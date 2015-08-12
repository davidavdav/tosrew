## code that does main() type of work

using SGEArrays
using MFCC
using GZip

## this assumes 10ms frames and crazy HTK 100ns units
function readbutsad(file::String)
    sad = Uint32[]
    if endswith(file, ".gz")
        fh = GZip.open(file)
    else
        fh = open(file)
    end
    for line in readlines(fh)
        start, stop, lab = split(line)
        if lab == "sp"
            for j in div(int(start), 100_000)+1 : div(int(stop), 100_000)
                push!(sad, j)
            end
        end
    end
    sad
end

function main_feacalc(procfealist::String)
    list = readdlm(procfealist, String)
    llist = size(list, 1)
    ch = Dict(["a", "b", "x"], [:a, :b, :mono])
    for i in SGEArray(1:llist)
        key = list[i,15]
	infile = joinpath("raw", "$key.raw")
        outfile = joinpath("data", "fea", "$key.mfcc")
        sadfile = joinpath("sad", "$key.lab.gz")
	dir = dirname(outfile)
	isdir(dir) || mkdir(dir)
        if !isfile(outfile)
            try
                ## read raw data
	        x = open(infile, "r") do fd
	    	    read(fd, Uint16, div(filesize(infile),2))
	        end
                ## we use BUT sad, so we need to be careful with normalization
                sad = readbutsad(sadfile)
                fea, meta, params = feacalc(float(vec(x)), sadtype=:none, normtype=:none, 
                                            defaults=:nbspeaker; dither=true)
                meta["sadtype"] = :but
                meta["speech"] = sad
                meta["nframes"] = length(sad)
                meta["normtype"] = :warp
                nwarp = 399
                meta["nwarp"] = nwarp
                feasave(outfile, warp(fea[sad,:], nwarp), meta=meta, params=params)
                println(outfile)
            catch err
                println("Error: ", err, "in trying to produce ", outfile)
            end
        else
            println("Skipping existing $outfile")
        end
    end
end
