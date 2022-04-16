using Chess, Chess.PGN

filename = "newspeed.pgn"
infile = open(filename)
@time gs = gamesfromstream(infile)
outf = open("newspeed.fen", "w")
for g in gs
        s = headervalue(g, "Result")
        r = 0
        try
                r = parse(Int, s[1])
        catch e
                println(position(infile))
        end
        if Bool(r) && s[2] == '/'
                r = 0.5
        end
        for b in boards(g)
                println(outf, fen(b), ',', r)
        end
end

close(infile)
close(outf)
