using HTTP, JSON

@testset "Netcode tests" begin
    begin
        d = Dict((("type", "gameStart"),))
        s = JSON.json(d)
        io = IOBuffer(s)
        @test LichessBot.eventsCallback(io) == 1
    end # begin
end
