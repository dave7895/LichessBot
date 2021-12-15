module LichessBot

using Chess
using Chess.Book
using HTTP
using JSON
baseUrl = "https://lichess.org/api"
token = get(ENV, "LICHESS_TOKEN", "")
defaultHeader = Dict("Authorization" => "Bearer $token")
myId =
    isempty(token) ? "" :
    JSON.parse(String(HTTP.get(baseUrl * "/account", defaultHeader).body))["id"]
include("moveEvaluation.jl")
include("playGames.jl")
include("utils.jl")
export runBot, setDefaultToken!, upgradeToBot

end
