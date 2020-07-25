module ObjectPools

export allocate, release

const MAX_POOL_SIZE = 100

const pools = Dict{Symbol, Vector}()

function createpool(type::Type{T}) where T
    pool = Vector{type}()
    pools[Symbol(string(T))] = pool
    return pool
end

@generated function getpool(type::Type{T}) where T
    s = Symbol(string(T))
    if !haskey(pools, s)
        createpool(T)
    end
    return quote
        return pools[$(Base.Meta.quot(s))]
    end
end

function allocate(type::Type{T}, args...)::T where T
    pool = getpool(type)
    return allocate(pool, T, args...)
end

function allocate(pool, type::Type{T}, args...)::T where T
    if length(pool) > 0
        return pop!(pool)
    end
    return T(args...)
end

function release(obj::T) where T
    pool = getpool(T)
    return release(pool, obj)
end

function release(pool, obj)
    if length(pool) < MAX_POOL_SIZE
        push!(pool, obj)
        return true 
    end
    return false
end

end # module
