module ObjectPools

export allocate, release

const MAX_POOL_SIZE = 100

const pools = Dict{Type, Vector}()

function createpool(type::Type{T}) where T
    pool = Vector{type}()
    pools[T] = pool
    return pool
end

@generated function getpool(type::Type{T}) where T
    if !haskey(pools, T)
        createpool(T)
    end
    retval = pools[T]
    return :($retval)
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
