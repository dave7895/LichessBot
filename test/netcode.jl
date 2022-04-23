using HTTP, JSON

@testset "Netcode tests" begin
    begin
        d = Dict((("type", "gameStart"),))
        s = JSON.json(d)
        io = IOBuffer(s)
        @test LichessBot.eventsCallback(io) == 1
    end # begin
    begin
        io = IOBuffer("{\"type\":\"gameState\", \"moves\":\"a2a3\", \"btime\":5000, \"binc\":1000}")
        @test isnothing(gameCallback(io))
    end
end
