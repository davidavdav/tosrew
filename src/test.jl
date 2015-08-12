## lazy-load the data, after Base.pmap
function Base.pmap(f::Function, x::Data)
    np = nprocs() # determine the number of processes available 
    n = length(x)
    results = cell(n)
    i = 1
    # function to produce the next work item from the queue.
    # in this case it’s just an index.
    function nextitem() 
        idx = i
        i += 1 
        idx
    end
    @sync begin
        for p in workers()
            if p != myid() || np == 1
                @async begin 
                    while true
                        idx = nextitem() 
                        if idx > n
                            break 
                        end
                        next = x.list[idx]
                        results[idx] = remotecall_fetch(p, s->f(x.read(s)), next) 
                    end
                end 
            end
        end
    end
    results
end

function dmap(f::Function, x::Data, ma=length(x))
    if GMMs.kind(x) == :file
        nx = length(x)
        w = workers()
        nw = length(w)
        worker(i) = w[1 .+ (i % nw)]
        results = cell(ma)
        getnext(i) = x.list[i]
        read = x.read
        @sync begin
            for i = 1:ma
                @async begin
                    next = getnext(i)
                    results[i] = remotecall_fetch(worker(i), s->f(read(s)), next)
                end
            end
        end
        results
    else
        pmap(f, x)
    end
end
