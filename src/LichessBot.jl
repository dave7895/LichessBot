module LichessBot

using Chess
using Chess.Book
using HTTP
using JSON
using Random
using Dates
using DelimitedFiles
import Base.isready, Base.isempty
@debug "LichessBot: import finished"
baseUrl = "https://lichess.org/api"
token = get(ENV, "LICHESS_TOKEN", "")
defaultHeader = Dict("Authorization" => "Bearer $token")
myId =
    isempty(token) ? "" :
    try
        JSON.parse(String(HTTP.get(baseUrl * "/account", defaultHeader).body))["id"]
    catch c
        ""
    end
mutable struct engineGame{G<:Union{Game,SimpleGame}}
    g::G
    wtime::Millisecond
    btime::Millisecond
    winc::Millisecond
    binc::Millisecond
    #movestogo::Integer
    depth::Integer
    engineGame{G}(g::G) where {G<:Union{Game,SimpleGame}} =
        new(g, Minute(1), Minute(1), Millisecond(0), Millisecond(0), 1) #=0,=#
end # mutable struct
include("moveEvaluation.jl")
include("moveSelection.jl")
include("playGames.jl")
include("pst.jl")
include("utils.jl")
include("uci.jl")
export runBot, setDefaultToken!, upgradeToBot, negamax

end
