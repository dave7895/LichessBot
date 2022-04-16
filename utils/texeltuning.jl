using Zygote
using LichessBot
using LichessBot.Chess
using DelimitedFiles
using StatsBase
tab = copy(LichessBot.psttable)
filename = "newspeed.fen"
games = @time readdlm(filename, ',')
boards = @time fromfen.(String.(games[:, 1]))
scores = games[:, 2]
data = @time collect(zip(boards, scores))
K = 100

sigmoid(s, K = K) = 1 / (1 + 10^(-K * s / 400))

function err(tup::Tuple, table = tab, K = K)
    tup[2] - sigmoid(LichessBot.pstFull(tup[1], 1, table), K)
end

function err(t::Real, table = tab, K=K)
    -sigmoid(t, K)
end
#=function error(v, table=tab, K=K)
    length(v) <= 2 && return error(tuple(v..., table, K))
    mean([error(t, table, K)^2 for t in v])
end=#

#error(K::Real) = error((startboard(), 0.5), tab, K)


#d = 10
#lastErr = error(K)
atexit(()->println(round.(Int, tab)))
atexit(()->writedlm("src/pstNeu.txt", round.(Int, tab)))
accu = ones(size(tab))
evals = @time [LichessBot.reallySimpleEval(b, 2) for b in boards]
println("length of date: $(length(data))")
for e in length(evals):1
    if abs(evals[e]) >= 10000
        deleteat!(data, e)
    end
end
println("length of data after: $(length(data))")
mut = ReentrantLock()
@time gradient(err, data[1], tab)[2]
while sum(abs.(accu)) > 0.001
    global accu, tab
    global accu = zeros(size(tab))
    @time#= Threads.@threads=# for #=(i, =#t in #=enumerate(=#rand(data, 100000)
        #print("\r$i")
        #print("\r$(err(t, tab))")
        locAcc = gradient(err, t, tab)[2]
        replace!(x->isnan(x) ? zero(x) : x, locAcc)
        lock(mut)
        accu += locAcc
        unlock(mut)
        #println(maximum(accu))
        #sleep(0.1)
        #isnan(accu) && break
    end
    println("\n Summe der Werte: $(sum(accu)), Summe der Beträge: $(sum(abs.(accu)))")
    nancount = count(isnan, accu)
    zerocount = count(x->!iszero(x), accu)
    #@time replace!(accu, NaN=>0)
    @time replace!(x->isnan(x) ? zero(x) : x, accu)
    println("$nancount NaNs replaced, $zerocount neither zero nor NaN\n")
    if !any(isnan, accu)
        tab += accu
    else
        accu = ones(size(tab))
    end
    accu = 0
    #println(K)
end
#println(tab)
