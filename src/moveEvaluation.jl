function chooseMove(b::Chess.Board; variant = "standard")
    println("choosing move", b)
    move = search_in_opening_books(b; variant=variant)
    if !isnothing(move)
        println("returning bookmove")
        return move
    end
    println("no move found in book")
    possible = moves(b)
    freeRealEstate = attacked_but_undefended(b, -sidetomove(b))
    println("freeRealEstate: ")
    pprint(b, highlight = freeRealEstate)
    takeable = attacked_with_pieces(b, -sidetomove(b))
    println("takeable squares/pieces")
    pprint(b, highlight = takeable)
    takingFree = Move[]
    takingAny = Move[]
    if !isempty(possible)
        if !isempty(freeRealEstate)
            println("$(length(possible)) moves to evaluate")
            mCounter = 0
            for m in possible
                if to(m) in freeRealEstate
                    println("found move that takes unprotected")
                    @show takingFree
                    println(typeof(m))
                    push!(takingFree, m)
                    println(takingFree)
                    #return m
                elseif to(m) in takeable
                    takingValue = value(pieceon(b, from(m)))
                    takenValue = value(pieceon(b, to(m)))
                    @show takingValue
                    @show takenValue
                    if takingValue <= takenValue
                        println(
                            "found move that takes higher valued but protected",
                        )
                        push!(takingAny, m)
                    end
                end
                if move_is_mate(b, m)
                    #println("found checkmate")
                    return m
                end
                mCounter += 1
                println("\r", mCounter, "/", length(possible), " evaluated")
            end
            @show takingAny
            @show takingFree
            if !isempty(takingFree)
                println("returning random take of unprotected")
                return rand(takingFree)
            end
            if !isempty(takingAny)
                println("returning random move that takes higher valued")
                return rand(takingAny)
            end
            println("returning completely random move")
            return rand(possible)
        else
            for m in possible
                if move_is_mate(b, m)
                    #println("found checkmate")
                    return m
                elseif to(m) in takeable
                    takingValue = value(pieceon(b, from(m)))
                    takenValue = value(pieceon(b, to(m)))
                    @show takingValue
                    @show takenValue
                    if takingValue <= takenValue
                        println(
                            "found move that takes higher valued but protected",
                        )
                        push!(takingAny, m)
                    end
                end
            end
            if !isempty(takingAny)
                println("returning random move that takes higher valued")
                return rand(takingAny)
            end
            println("returning completely random move, no mate no free")
            return rand(possible)
        end
    end
    move
end

function attacked_but_undefended(board, color)
    # copied from Chess.jl tutorial at https://romstad.github.io/Chess.jl/stable/manual/#Square-Sets-1

    attacker = -color  # The opposite color

    # Find all attacked squares
    attacked = SS_EMPTY  # The empty square set
    for s ∈ pieces(board, attacker)
        attacked = attacked ∪ attacksfrom(board, s)
    end

    # Find all defended squares
    defended = SS_EMPTY
    for s ∈ pieces(board, color)
        defended = defended ∪ attacksfrom(board, s)
    end

    # Return all attacked, but undefended squares containing pieces of
    # the desired color:
    attacked ∩ -defended ∩ pieces(board, color)
end

function attacked_with_pieces(board, color)
    attacker = -color
    attacked = SS_EMPTY
    for s ∈ pieces(board, attacker)
        attacked = attacked ∪ attacksfrom(board, s)
    end

    attacked ∩ pieces(board, color)
end


function move_is_mate(board, move)
    #from CHess.jl Tutorial
    # Do the move
    u = domove!(board, move)

    # Check if the resulting board is checkmate
    result = ischeckmate(board)

    # Undo the move
    undomove!(board, u)

    # Return result
    result
end

function value(p::Chess.Piece)
    p == PIECE_TYPE_NONE && return -1
    return ptype(p).val
end

function search_in_opening_books(b; variant="standard")
    if variant == "atomic"
        move = @time pickbookmove(
            b,
            bookfile = "/home/dave/LichessGames/atomicOpening.obk",
        )
    else
        move = pickbookmove(
            b,
            bookfile = "/home/dave/LichessGames/lichess_elite.obk",
        )
        if isnothing(move)
            println("no move found in elite db, looking in own games")
            move = pickbookmove(
                b,
                bookfile = "/home/dave/LichessGames/myGames.obk",
            )
        end
    end
    return move
end
