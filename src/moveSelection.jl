function negamax(
    g::Union{Game,SimpleGame},
    depth,
    ply,
    alpha::Integer = -typemax(Int32),
    beta::Integer = typemax(Int32);
    evalFunc = simpleEval,
    stop = Ref(false),
    AB::Bool = true,
    pvt = nothing,
)::Int
    #println("not TL negamax $stop, d=$depth")
    #println(evalFunc)
    if depth == 0 || isterminal(g)
        #depth <= 0 && !ischeck(board(g)) && return quiesce(g, alpha, beta)
        return evalFunc(g, depth)
    end
    b = board(g)
    if ischeck(b)
        depth += 1
    end
    legalMoves = moves(b, MoveList(movecount(b)))
    ordermoves!(legalMoves, b, ply, pvt)
    bestEval = -typemax(Int)
    for m in legalMoves
        #=if isready(stop)
            take!(stop)
            println("stopped in not TL negamax at d=$depth")
            break
        end=#
        stop[] && !(stop[] = false) && break
        u = domove!(g, m)
        bestEval = max(
            bestEval,
            -negamax(
                g,
                depth - 1,
                ply + 1,
                -beta,
                -alpha;
                evalFunc = evalFunc,
                stop = stop,
                AB = AB,
                pvt = pvt,
            ),
        )
        back!(g)
        if bestEval > alpha
            alpha = bestEval
            if !isnothing(pvt)
                pvt[ply] = m
                #fillMoveList!(pvt, m, ply)
            end
        end
        AB && alpha >= beta && break
    end
    return bestEval
end

function negamax(b::Board, args...; kwargs...)
    g = Game(b)
    negamax(g, args...; kwargs...)
end

function matDiff(m::Move, b::Board, pvMove = nothing)
    #m == pvMove && return 10000
    target = pieceon(b, to(m))
    isempty(target) ? -1000 :
    pieceValue(target) - pieceValue(pieceon(b, from(m)))
end

function negamax(
    g::Union{Game,SimpleGame},
    depth,
    ply,
    toplevel::Bool,
    alpha::Integer = -typemax(Int32),
    beta::Integer = typemax(Int32);
    evalFunc = simpleEval,
    info = false,
    returnScore::Union{Nothing,Ref} = nothing,
    stop = Ref(false),
    uci = false,
    AB::Bool = true,
    pvt = nothing,
)::Move
    uci && println("info string TL negamax ", stop)
    if depth == 0 || isterminal(g)
        return moves(board(g))[1]
    end
    b = board(g)
    legalMoves = moves(b, MoveList(movecount(b)))
    ordermoves!(legalMoves, b, ply, pvt)
    #legalMoves = ml.moves #shuffle(moves(b))
    topMove = legalMoves[1]
    #@info topMove
    bestEval = -typemax(Int)
    for m in legalMoves
        #=if isready(stop)
            take!(stop)
            println("stopped in TL negamax")
            break
        end=#
        stop[] && !(stop[] = false) && break
        domove!(g, m)
        s =
            -negamax(
                g,
                depth - 1,
                ply + 1,
                -beta,
                -alpha;
                evalFunc = evalFunc,
                stop = stop,
                AB = AB,
                pvt = pvt,
            )
        back!(g)
        info && @info s, m
        if s > bestEval
            bestEval = s
            topMove = m
            alpha = max(alpha, bestEval)
            if !isnothing(pvt)
                #fillMoveList!(pvt, topMove, ply)
                pvt[ply] = topMove
            end
        end
        AB && alpha >= beta && break
    end
    if !isnothing(returnScore)
        returnScore[] = bestEval
    end
    if uci
        println("bestmove $(tostring(topMove))")
    end
    return topMove
end

function ordermoves!(ms::MoveList, b::Board, ply::Int = 0, pvt = nothing)
    values = [100*see(b, m) for m in ms]#[matDiff(m, b) for m in ms]
    if !isnothing(pvt)
        idx = findfirst(x -> x == pvt[ply], ms)
        if !isnothing(idx)
            values[idx] = 10000
        end
    end
    ms.moves = ms.moves[sortperm(values; rev = true)]
end # function

function fillMoveList!(ms::MoveList, m::Move, ply::Integer)
    anyPush = false
    while length(ms) < ply
        anyPush = true
        push!(ms, m)
    end
    if !anyPush
        ms.moves[ply] = m
    end
    ms
end

function iterativeDeepening(
    g::Union{Game,SimpleGame},
    time,
    initialDepth::Ref = Ref(1);
    buffer = true,
    returnScore = nothing,
    stop = Ref(false),
    uci = false,
    evalFunc = simpleEval,
    AB::Bool = true,
)
    #println(stop)
    starttime = now()
    initialDepth[] -= 1
    topMove = moves(board(g))[1]
    println(board(g))
    referenceTime = Millisecond(time)
    if buffer
        #println("using buffer")
        referenceTime ÷= max(10, movecount(board(g)))
    else
        referenceTime ÷= 5
    end
    println(referenceTime)
    if uci && isnothing(returnScore)
        returnScore = Ref(0)
    end
    pvt = fill(Move(0), 32)
    savedPvt = copy(pvt)
    initialDepth[] = 1
    stoptime = now() + (referenceTime * 12 ÷ 10)
    while (now() - starttime) < referenceTime #&& !isready(stop)
        @debug ("some time left, d=$(initialDepth[])")
        #=if isready(stop)
            take!(stop)
            println("info string stopped in iterativeDeepening()")
            break
        end=#
        stop[] && !(stop[] = false) && break
        initialDepth[] += 1
        topMove = negamax(
            g,
            initialDepth[],
            1,
            true;
            evalFunc = evalFunc,
            info = false,
            returnScore = returnScore,
            stop = stop,
            AB = AB,
            pvt = pvt,
        )
        if !stop[]
            savedPvt = pvt
            pvt = fill(Move(0), 32)
        end
        if uci
            println(
                "info depth $(initialDepth[]) score cp $(returnScore[]) pv $(tostring(savedPvt[1])))",
            )
        end
    end
    if uci
        println("bestmove $(tostring(topMove))")
    end
    return topMove
end
