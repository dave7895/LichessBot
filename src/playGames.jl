function makeMove(id::String, move::Move)
    @debug("stringifying move $move")
    moveString = tostring(move)
    @debug(moveString)
    moveUrl = baseUrl * "/bot/game/$id/move/$moveString"
    @debug(moveUrl)
    @debug("starting post request to move api")
    HTTP.request("POST", moveUrl, defaultHeader)
    @debug("made move")
end

function makeMove!(id::String, b::Board; variant = "standard")
    move = chooseMove(b; variant = variant)
    @debug("chose move $move")
    makeMove(id, move)
    domove!(b, move)
    @debug("made! move")
    return tostring(move)
end

function streamGame(id::String)
    streamUrl = baseUrl * "/bot/game/stream/$id"
    variant = nothing
    myColor = nothing
    lastMove = nothing
    b = startboard()
    domove(b, "b2b3")
    @time JSON.parse("{}")
    @debug("streaming Game with id $id")
    r = HTTP.open("GET", streamUrl, defaultHeader) do http
        while !eof(http)
            s = String(readavailable(http))
            length(s) > 1 && @debug(length(s))
            if !isnothing(findfirst("{", s))
                @show b
                @debug("now parsing in streamGame")
                state = @time JSON.parse(s)
                if state["type"] == "gameFull"
                    @debug(s)
                    @debug("full game")
                    if state["white"]["id"] == myId
                        myColor = WHITE
                    elseif state["black"]["id"] == myId
                        myColor = BLACK
                    end
                    @show myColor
                    variant = state["variant"]["key"]
                    if state["initialFen"] != "startpos"
                        b = fromfen(state["initialFen"])
                        @debug("start is non default")
                    else
                        @debug("start is default")
                    end
                    if !isempty(state["state"]["moves"])
                        @debug("splitting and getting moves")
                        moves = string.(split(state["state"]["moves"]))
                        lastMove = moves[end]
                        @debug("applying moves to b")
                        @debug(b)
                        @debug(moves)
                        domoves!(b, moves...)
                        @debug("did all moves")
                    else
                        @debug("no moves to make")
                    end
                    if sidetomove(b) == myColor
                        @debug("starting to make move, still at streamGame")
                        lastMove = makeMove!(id, b, variant = variant)
                    end
                    @show b
                    @debug("reached end of gameFull evaluation")
                elseif state["type"] == "gameState"
                    @debug(s)
                    @debug("game status: $(state["status"])")
                    moves = string.(split(state["moves"]))
                    @debug("already $(length(moves)) moves done")
                    pos = findlast(x -> x == lastMove, moves)
                    @debug("checking if last move already done")
                    if moves[end] != lastMove
                        @debug("last move not yet done")
                        pos = isnothing(pos) ? 0 : pos
                        @show pos
                        @show lastMove
                        @debug(moves[max(pos, 1):end])
                        if pos + 1 == lastindex(moves)
                            domove!(b, moves[end])
                        elseif !isempty(moves)
                            @debug("moves not empty, applying...")
                            domoves!(b, moves[pos+1:end]...)
                        end
                        lastMove = moves[end]
                    end
                    if sidetomove(b) == myColor
                        @debug("starting to make move, still at streamGame")
                        lastMove = @time makeMove!(id, b, variant = variant)
                        @debug("to make move")
                    end
                    @show b
                    @debug("reached end of gameState evaluation")
                end
            end
        end

    end
    @debug("Game is over. exiting function streamGame of gameId $id")
end

function runBot()
    eventUrl = baseUrl * "/stream/event"
    challengeUrl = baseUrl * "/challenge"
    retVal = 0
    #trigger precompilation
    @time JSON.parse("{}")
    @debug("opening event stream")
    while true
        r = HTTP.open("GET", eventUrl, defaultHeader) do http
            while !eof(http)
                s = String(readavailable(http))
                length(s) == 1 && continue #print("\rbot still alive")
                if !isnothing(findfirst("{", s))
                    @debug("now parsing in runBot")
                    state = @time JSON.parse(s)
                    @debug(typeof(state))
                    @debug(state["type"])
                    if state["type"] == "challenge"
                        challenger = state["challenge"]["challenger"]["name"]
                        variant =
                            lowercase(state["challenge"]["variant"]["key"])
                        challengeId = state["challenge"]["id"]
                        @debug("""incoming $variant challenge
                                    from $challenger
                                    with id $challengeId""")
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
                            @debug("declaing challenge with variant $variant")
                            specificUrl =
                                challengeUrl * "/$challengeId/decline"
                            HTTP.request("POST", specificUrl, defaultHeader)
                        else
                            @debug("now accepting challenge")
                            specificUrl =
                                challengeUrl * "/$challengeId/accept"
                            HTTP.request("POST", specificUrl, defaultHeader)
                        end
                    elseif state["type"] == "gameStart"
                        @debug("now async starting stream")
                        @async streamGame(state["game"]["id"])
                    end
                    #write("state$(length(s)).bson", state)
                    #@debug("written to file")
                end
                #@debug(String(readavailable(http)))
            end
        end
    end
    return retVal
end
#=
r = HTTP.open("GET", "https://lichess.org/api/stream/event", ["Authorization"=>"Bearer $tok"]) do http
    while !eof(http)
        @debug(String(readavailable(http)))
    end
end
=#
