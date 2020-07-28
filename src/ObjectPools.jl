module ObjectPools

export allocate, release

const MAX_POOL_SIZE = 100

const pools = IdDict{Any, Any}()

function createpool(type::Type{T}) where T
    pool = Vector{T}()
    pools[T] = pool
    return pool
end

function getpool(type::Type{T}) where T
    if !haskey(pools, T)
        createpool(T)
    end
    return pools[T]::Vector{T}
end

@generated function getpool_static(type::Type{T}) where T
    if !haskey(pools, T)
        createpool(T)
    end
    return quote
        return $(getpool(T))
    end
end

function allocate(type::Type{T}, args...) where T
    pool = getpool_static(T)
    return allocate(pool, T, args...)
end

function allocate(pool, type::Type{T}, args...) where T
    if length(pool) > 0
        return pop!(pool)
    end
    return T(args...)
end

function release(obj::T) where T
    pool = getpool_static(T)
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
