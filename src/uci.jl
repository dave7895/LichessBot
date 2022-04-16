uciisready() = println("readyok")

ucinewgame() = engineGame{SimpleGame}(SimpleGame())

function position!(eg::engineGame, commands)
    g = SimpleGame()
    if commands[1] == "fen"
        deleteat!(commands, 1)
        g = SimpleGame(commands[1])
    end
    deleteat!(commands, 1)
    #eg.g = g
    g
end

function moves!(eg::engineGame, commands)
    lastmove = Move(5)
    g = eg.g
    while !isempty(commands) && 'a' <= commands[1][1] <= 'h'
        lastmove = movefromstring(String(commands[1]))
        if isnothing(lastmove)
            break
        end
        domove!(g, lastmove)
        deleteat!(commands, 1)
    end
end

function go!(eg::engineGame, commands; stop = Ref(false))
    availableTime = Millisecond(0)
    depthSet = false
    @debug(commands)
    while !isempty(commands)
        if (commands[1] == "wtime")
            deleteat!(commands, 1)
            eg.wtime = Millisecond(parse(Int, commands[1]))
            deleteat!(commands, 1)
        elseif (commands[1] == "btime")
            deleteat!(commands, 1)
            eg.btime = Millisecond(parse(Int, commands[1]))
            deleteat!(commands, 1)
        elseif (commands[1] == "winc")
            deleteat!(commands, 1)
            eg.winc = Millisecond(parse(Int, commands[1]))
            deleteat!(commands, 1)
        elseif (commands[1] == "binc")
            deleteat!(commands, 1)
            eg.binc = Millisecond(parse(Int, commands[1]))
            deleteat!(commands, 1)
        elseif (commands[1] == "movestogo")
            deleteat!(commands, 1)
            #eg.movestogo = parse(Int, commands[1])
            deleteat!(commands, 1)
        elseif (commands[1] == "depth")
            deleteat!(commands, 1)
            eg.depth = parse(Int, commands[1])
            deleteat!(commands, 1)
            depthSet = true
        elseif (commands[1] == "movetime")
            deleteat!(commands, 1)
            availableTime = Millisecond(parse(Int, commands[1]))
            deleteat!(commands, 1)
        end
    end
    buffer = false
    if availableTime == Millisecond(0)
        buffer = true
        if sidetomove(board(eg.g)) == WHITE
            availableTime += min((eg.wtime * 7) ÷ 10, eg.winc + eg.wtime ÷ 60)
        else
            availableTime += min((eg.btime * 7) ÷ 10, eg.binc + eg.btime ÷ 60)
        end
        eg.depth = max(1, eg.depth - 1)
    end
    iDepth = Ref(eg.depth)
    if depthSet
        move = @async negamax(
            eg.g,
            eg.depth,
            true;
            stop = stop,
            uci = true,
            evalFunc = pstFull,
        )
    else
        move = @async iterativeDeepening(
            eg.g,
            availableTime,
            iDepth;
            buffer = buffer,
            stop = stop,
            uci = true,
            evalFunc = pstAndMate,
        )
    end
    return move
    println("bestmove $(tostring(move))")
end

function stop(eg, st = Channel{Bool}(5))
    #put!(st, true)
    st[] = true
    yield()
    #move = rand(moves(board(eg.g)))
end

function uci_listen(; id = true)
    if id
        println("id name $myId")
        println("id author David Weingut")
        println("uciok")
    end
    while true
        ln = readline()
        ln == "isready" && break
        ln == "quit" && return
    end
    @time iterativeDeepening(Game(), Millisecond(100), Ref(1); evalFunc=pstFull)
    eg = engineGame{SimpleGame}(SimpleGame())
    st = Ref{Bool}(false) #Channel{Bool}(5)
    position!(eg, ["startpos"])
    moves!(eg, ["a2a3"])
    uciisready()
    while true
        @debug(st[])#=isready(st)=#
        #uciisready()
        ln = readline()
        @debug("read line")
        commands = split(lowercase(ln))
        #println("info string $commands")
        startLength = length(commands) + 1
        while !isempty(commands) && length(commands) < startLength
            startLength = length(commands)
            com = Ref(commands, 1)
            if com[] == "quit"
                return
            end
            if com[] == "isready"
                uciisready()
                break
            end
            if com[] == "ucinewgame"
                eg = ucinewgame()
                uciisready()
                break
            end
            if com[] == "position"
                deleteat!(commands, 1)
                eg.g = position!(eg, commands)
                #println("position returned")
                if isempty(commands)
                    uciisready()
                    break
                end
            end
            if com[] == "moves"
                deleteat!(commands, 1)
                moves!(eg, commands)
                if isempty(commands)
                    uciisready()
                    break
                end
            end
            if com[] == "go"
                @debug("eg.depth = $(eg.depth)")
                deleteat!(commands, 1)
                go!(eg, commands; stop = st)
                @debug("go rturned")
                isempty(commands) && break
            end
            if com[] == "stop"
                stop(eg, st)
                @debug("returned from stop()")
            end
        end
    end
end
