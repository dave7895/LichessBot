function negamax(
    g::Union{Game,SimpleGame},
    depth,
    alpha::Integer = -typemax(Int32),
    beta::Integer = typemax(Int32);
    evalFunc = simpleEval,
    stop = Ref(false),
    AB::Bool = true,
)::Int
    #println("not TL negamax $stop, d=$depth")
    #println(evalFunc)
    if depth == 0 || isterminal(g)
        return evalFunc(g, depth)
    end
    b = board(g)
    if ischeck(b)
        depth += 1
    end
    legalMoves = moves(b, MoveList(movecount(b)))
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
                -beta,
                -alpha;
                evalFunc = evalFunc,
                stop = stop,
                AB = AB,
            ),
        )
        back!(g)
        alpha = max(alpha, bestEval)
        AB && alpha >= beta && break
    end
    return bestEval
end

function negamax(b::Board, args...; kwargs...)
    g = Game(b)
    negamax(g, args...; kwargs...)
end

function matDiff(m::Move, b::Board)
    target = pieceon(b, to(m))
    isempty(target) ? -1000 :
    pieceValue(target) - pieceValue(pieceon(b, from(m)))
end

function negamax(
    g::Union{Game,SimpleGame},
    depth,
    toplevel::Bool,
    alpha::Integer = -typemax(Int32),
    beta::Integer = typemax(Int32);
    evalFunc = simpleEval,
    info = false,
    returnScore::Union{Nothing,Ref} = nothing,
    stop = Ref(false),
    uci = false,
    AB::Bool = true,
)::Move
    uci && println("info string TL negamax ", stop)
    if depth == 0 || isterminal(g)
        return moves(board(g))[1]
    end
    b = board(g)
    legalMoves = moves(b, MoveList(movecount(b)))
    #legalMoves = ml.moves #shuffle(moves(b))
    topMove = legalMoves[1]
    @info topMove
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
                -beta,
                -alpha;
                evalFunc = evalFunc,
                stop = stop,
                AB = AB,
            )
        back!(g)
        info && @info s, m
        if s > bestEval
            bestEval = s
            topMove = m
        end
        alpha = max(alpha, bestEval)
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
    referenceTime = Millisecond(time)
    if buffer
        #println("using buffer")
        referenceTime ÷= (movecount(board(g)))
    else
        referenceTime ÷= 5
    end
    println(referenceTime)
    if uci && isnothing(returnScore)
        returnScore = Ref(0)
    end
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
            true;
            evalFunc = evalFunc,
            info = false,
            returnScore = returnScore,
            stop = stop,
            AB = AB,
        )
        if uci
            println("info depth $(initialDepth[]) score cp $(returnScore[])")
        end
    end
    if uci
        println("bestmove $(tostring(topMove))")
    end
    return topMove
end
