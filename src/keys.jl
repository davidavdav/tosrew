using DataFrames, NamedArrays

function readprismkey(f::String)
    fields = [:id, :db, :pin, :base, :chan, :sid, :sex, :birthyear, :recyear, :age, :speechtype, :chantype, :nomdur, :lang, :l1, :vocaleffort]
    readtable(f, separator=' ', header=false, names=fields)
end

function readsphkey(f::String)
    d = readdlm(f, String)
    paths = NamedArray(d[:,2], Vector[d[:,1]], ["key"])
    paths
end

toprism = ["sre04" => "MIX04", "sre05" => "MIX05", "sre06" => "MIX06",
           "sre08" => "MIX08", "sre10" => "MIX10", 
           "fisher" => "FISHE1", 
           "swbcellp1" => "SWCELLP1", "swbcellp2" => "SWCELLP2",
           "swb2p1" => "SWPH1", "swb2p3" => "SWPH3"]
           
function readboth(db::String)
    pdb = 0
    try
        pdb = toprism[db]
    catch
        error(string("Unsupported db: ", db))
    end
    path = readsphkey(string("lists/sph/", db, "-sph.key"))
    df = readprismkey(string("lists/prism-set/KEYS/", pdb, ".key"))
    base = convert(Array,df[:base])
    keys = names(path)[1]
    found = findin(base, keys)
    if length(found) < length(base)
        warn(string(length(base) - length(found), " sph files are missing"))
    end
    df = df[found,:]
    df[:path] = path[base[found]].array
    df
end

function makelist(outfile="lists/process-sph.list")
    x = Array[]
    for db in keys(toprism)
        df = readboth(db)
        push!(x, hcat(df[:id], df[:chan], df[:path]))
    end
    writedlm(outfile, vcat(x...))
end

function makeubmlist(g::String, outputfile="lists/ubmtrain-$g.list")
    @assert g in ["m", "f"]
    exists = Set(readdlm("lists/mix04-mfcc.list", String))
    noreps = Set(readdlm("lists/prism-set/LISTS/sessions_from_heldout_speakers_no_rep"))
    ok = intersect(exists, noreps)
    x = DataArray[]
    for db in keys(toprism)
        df = readboth(db)
        sel = bitpack([k in ok for k in df[:id]] & array(df[:sex] .== g))
        push!(x, df[sel,:id])
    end
    writedlm(outputfile, array(vcat(x...)))
end
