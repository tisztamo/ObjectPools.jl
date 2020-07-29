module ObjectPools
using Base.Threads

export allocate, release

const MAX_POOL_SIZE = 100

const pools = IdDict{Any, Any}()
const poolslock = SpinLock()

function _createpool_unsafe(type::Type{T}) where T
    pool = Vector{T}()
    pools[T] = pool
    return pool
end

function _createpool(type)
    lock(poolslock)
    try
        return _createpool_unsafe(type)
    finally
        unlock(poolslock)
    end
end

function _trycreatepool(type)
    if trylock(poolslock)
        try
            return _createpool_unsafe(type)
        finally
            unlock(poolslock)
        end
    else
        return nothing
    end
end

function getpool(type::T) where T
    if !haskey(pools, type)
        _createpool(type)
    end
    return pools[type]::Vector{type}
end

@generated function getpool_static(type::Type{T}) where T
    if !haskey(pools, T)
        pool = _trycreatepool(T)
        if isnothing(pool) # Wasn't able to create the pool because pools is locked
            return quote getpool($T) end # Falling back to dynamic
        end
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
