psttable = readdlm(pkgdir(@__MODULE__)*"/src/pst.txt", Int)

function pst(p::Piece, sq::Square, table=psttable)::Real
    sqval = (pcolor(p) == WHITE ? sq.val : ((sq.val - 1) ⊻ 7) + 1)::Int
    table[ptype(p).val, sqval]
end

pstEval(g::Union{Game,SimpleGame}, d = 1, table=psttable, c::PieceColor=WHITE)::Real =
    isdraw(g) ? 0 : pstEval(board(g), d, table, c)

function pstEval(b::Board, d::Integer = 1, table=psttable, c::PieceColor=WHITE)
    score = 0
    ps = Piece.((1:6) .+ (8*(c==BLACK)))
    for p = ps
        for s = pieces(b, p)
            score += pst(p, s, table)
        end
    end
    score
end

function pstFull(b::Board, d::Integer=1, table=psttable)
    pstEval(b, d, table, sidetomove(b)) - pstEval(b, d, table, -sidetomove(b))
end

function pstFull(g::Union{Game,SimpleGame}, d::Integer=1, table=psttable)
    c = sidetomove(board(g))
    pstEval(g, d, table, c) - pstEval(g, d, table, -c)
end

function pstAndMate(g, d::Integer=1, table=psttable; matescore=10000)
    b = typeof(g) == Board ? g : board(g)
    if ischeckmate(b)
        return -max(d, 1) * matescore
    end
    if isdraw(g) #|| isrepetitiondraw(g) # too slow
        return 0
    end
    any(m->LichessBot.move_is_mate(b,m), moves(b)) && return max(d, 1) * matescore
    return pstFull(g, d, table)
end
