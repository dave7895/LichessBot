#!/home/dave/.local/bin/julia --startup-file=no
readline()
println("id name davidsguterbot")
println("id author David Weingut")
println("uciok")
using Pkg
Pkg.activate(".")
using LichessBot
LichessBot.uci_listen(;id=false)
