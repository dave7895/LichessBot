using Chess
function testMove(b::Board, m::Move)
        negamax(b, 3, true; evalFunc = LichessBot.reallySimpleEval) == m
end
function testMove(fen::AbstractString, m::Move)
        testMove(fromfen(fen), m)
end
function testMove(b, m::AbstractString)
        testMove(b, movefromstring(m))
end
boards = [
("5k2/pR4R1/3p3p/6p1/4N3/8/PPr2PPP/7K b - - 2 26", "c2c1"),
("rnbk4/pppp2b1/4pr2/P4p1Q/1q3P2/2N5/3R2P1/2B1KB1R b - - 2 28", "b4c3"),
("rnbk1b1Q/pppp4/4pr2/P4p2/5P2/2q5/3R2P1/2B1KB1R w - - 2 30", "c1b2"),
("rnb1kbr1/pppp1ppp/4p3/8/1qP4Q/1P6/P2PNPPP/RNB1KB1R w KQq - 3 8", "h4h7"),
("1r1kr3/1pp4p/7b/p2b1pp1/3B1PP1/PPnP2Q1/R2N1K1P/5BNR b - - 7 26", "c3d1")
]
@testset "Evaluation" begin
        for (bs, ms) in boards
                b = fromfen(bs)
                @test LichessBot.negamax(b, 3, true) == movefromstring(ms)
        end
        #=begin
                local b = startboard()
                @test !isnothing(LichessBot.oldChooseMove(b))
        end
        begin
                local b = fromfen(
                        "5k2/pR4R1/3p3p/6p1/4N3/8/PPr2PPP/7K b - - 2 26",
                )
                @test LichessBot.negamax(b, 3, true) == Move(SQ_C2, SQ_C1)
        end
        begin
                local b = fromfen(
                        "rnbk4/pppp2b1/4pr2/P4p1Q/1q3P2/2N5/3R2P1/2B1KB1R b - - 2 28",
                )
                @test negamax(b, 3, true) == Move(SQ_B4, SQ_C3)
        end
        begin
                local b = fromfen(
                        "rnbk1b1Q/pppp4/4pr2/P4p2/5P2/2q5/3R2P1/2B1KB1R w - - 2 30",
                )
                @test negamax(
                        b,
                        3,
                        true;
                        evalFunc = LichessBot.reallySimpleEval,
                ) == movefromstring("c1b2")
        end
        begin
                local b = fromfen(
                        "rnb1kbr1/pppp1ppp/4p3/8/1qP4Q/1P6/P2PNPPP/RNB1KB1R w KQq - 3 8",
                )
                @test negamax(
                        b,
                        3,
                        true;
                        evalFunc = LichessBot.reallySimpleEval,
                ) == movefromstring("h4h7")
        end
        begin
                local b = fromfen("1r1kr3/1pp4p/7b/p2b1pp1/3B1PP1/PPnP2Q1/R2N1K1P/5BNR b - - 7 26")
                @test negamax(
                b, 1, true
                ) == movefromstring("c3d1")
        end=#
        for (bs, ms) in boards
                b = fromfen(bs)
                @test negamax(b, 3, true) == negamax(b, 3, true; AB=false)
                @test negamax(b, 3) == negamax(b, 3; AB=false)
        end
end
