## try to read _any_ soundfile using sox (or something else)

function readsamples(file; sr::Int=8000, chan::Symbol=:a)
    ch = [:a => 1, :b => 2][chan]
    nch = int(readall(`soxi -c $file`))
    if nch > 1
        sox = `sox $file -t raw -e signed -r $sr -b 16 -c 1 - mixer -$ch`
    else
        if ch>1
            warn("Channel not in input")
        end
        sox = `sox $file -t raw -e signed -r $sr -b 16 -`
    end
    fd, proc = readsfrom(sox)
    x = Int16[]
    while !eof(fd)
        push!(x, read(fd, Int16))
    end
    x / (1<<15)
end


