function makeMove(id::String, move::Move)
    println("stringifying move $move")
    moveString = tostring(move)
    println(moveString)
    moveUrl = baseUrl * "/bot/game/$id/move/$moveString"
    println(moveUrl)
    println("starting post request to move api")
    HTTP.request("POST", moveUrl, defaultHeader)
    println("made move")
end

function makeMove!(id::String, b::Board; variant = "standard")
    move = chooseMove(b; variant = variant)
    println("chose move $move")
    makeMove(id, move)
    domove!(b, move)
    println("made! move")
    return tostring(move)
end

function streamGame(id::String)
    streamUrl = baseUrl * "/bot/game/stream/$id"
    variant = nothing
    myColor = nothing
    lastMove = nothing
    b = startboard()
    domove(b, "b2b3")
    println("streaming Game with id $id")
    r = HTTP.open("GET", streamUrl, defaultHeader) do http
        while !eof(http)
            s = String(readavailable(http))
            length(s) > 1 && println(length(s))
            if !isnothing(findfirst("{", s))
                println("now parsing in streamGame")
                state = @time JSON.parse(s)
                if state["type"] == "gameFull"
                    println(s)
                    println("full game")
                    if state["white"]["id"] == myId
                        myColor = WHITE
                    elseif state["black"]["id"] == myId
                        myColor = BLACK
                    end
                    @show myColor
                    variant = state["variant"]["key"]
                    if state["initialFen"] != "startpos"
                        b = fromfen(state["initialFen"])
                        println("start is non default")
                    else
                        println("start is default")
                    end
                    if !isempty(state["state"]["moves"])
                        println("splitting and getting moves")
                        moves = string.(split(state["state"]["moves"]))
                        lastMove = moves[end]
                        println("applying moves to b")
                        println(b)
                        println(moves)
                        domoves!(b, moves...)
                        println("did all moves")
                    else
                        println("no moves to make")
                    end
                    if sidetomove(b) == myColor
                        println("starting to make move, still at streamGame")
                        lastMove = makeMove!(id, b, variant = variant)
                    end
                    @show b
                    println("reached end of gameFull evaluation")
                elseif state["type"] == "gameState"
                    println(s)
                    println("game status: $(state["status"])")
                    moves = string.(split(state["moves"]))
                    println("already $(length(moves)) moves done")
                    pos = findlast(x -> x == lastMove, moves)
                    println("checking if last move already done")
                    if moves[end] != lastMove
                        println("last move not yet done")
                        pos = isnothing(pos) ? 0 : pos
                        @show pos
                        @show lastMove
                        println(moves[max(pos, 1):end])
                        if !isempty(moves)
                            println("moves not empty, applying...")
                            domoves!(b, moves[pos+1:end]...)
                        end
                        lastMove = moves[end]
                    end
                    if sidetomove(b) == myColor
                        println("starting to make move, still at streamGame")
                        lastMove = @time makeMove!(id, b, variant = variant)
                        println("to make move")
                    end
                    println("reached end of gameState evaluation")
                end
            end
        end

    end
    println("Game is over. exiting function streamGame of gameId $id")
end

function runBot()
    eventUrl = baseUrl * "/stream/event"
    challengeUrl = baseUrl * "/challenge"
    retVal = 0
    println("opening event stream")
    r = HTTP.open("GET", eventUrl, defaultHeader) do http
        while !eof(http)
            s = String(readavailable(http))
            length(s) == 1 && print("\rbot still alive")
            if !isnothing(findfirst("{", s))
                println("now parsing in runBot")
                state = @time JSON.parse(s)
                println(typeof(state))
                println(state["type"])
                if state["type"] == "challenge"
                    challenger = state["challenge"]["challenger"]["name"]
                    variant = lowercase(state["challenge"]["variant"]["key"])
                    challengeId = state["challenge"]["id"]
                    println(
                        """incoming $variant challenge
                            from $challenger
                            with id $challengeId""",
                    )
                    if lowercase(challenger) == lowercase(myId)
                        continue
                    end
                    if variant in [
                        "racingkings",
                        "horde",
                        "kingofthehill",
                        "antichess",
                        "crazyhouse",
                    ]
                        println("declaing challenge with variant $variant")
                        specificUrl = challengeUrl * "/$challengeId/decline"
                        HTTP.request("POST", specificUrl, defaultHeader)
                    else
                        println("now accepting challenge")
                        specificUrl = challengeUrl * "/$challengeId/accept"
                        HTTP.request("POST", specificUrl, defaultHeader)
                    end
                elseif state["type"] == "gameStart"
                    println("now async starting stream")
                    @async streamGame(state["game"]["id"])
                end
                #write("state$(length(s)).bson", state)
                #println("written to file")
            end
            #println(String(readavailable(http)))
        end
    end
    return retVal
end
#=
r = HTTP.open("GET", "https://lichess.org/api/stream/event", ["Authorization"=>"Bearer $tok"]) do http
    while !eof(http)
        println(String(readavailable(http)))
    end
end
=#
