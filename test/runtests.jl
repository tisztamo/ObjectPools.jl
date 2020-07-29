using ObjectPools
using Test, BenchmarkTools

@testset "Creating objects through the allocate" begin
    @test allocate(Int, 4) === 4
    @test allocate(Dict) isa Dict
    @test allocate(Dict{Int, Int}, [1 => 2])[1] === 2
end

@testset "Reusing objects" begin
    d1 = allocate(Dict{Int, Int})
    release(d1)

    d2 = allocate(Dict{Int, Int})
    @test d2 === d1

    d3 = allocate(Dict{Int, Int})
    @test d3 !== d1
end

function fill_pool(type, args...)
    ds = [allocate(type, args...) for i = 1:ObjectPools.MAX_POOL_SIZE]
    @test map(release, ds) == [true for i = 1:ObjectPools.MAX_POOL_SIZE]
end

@testset "Reusing multiple objects of multiple types" begin
    fill_pool(Dict{String, Any})
    fill_pool(UInt, 1)
    fill_pool(Float16, 1.0)
    fill_pool(Float16, 1.0)
end

@testset "Filling up the pool" begin
    type = Dict{UInt, Int}
    extra_obj = allocate(type)
    ds = [allocate(type) for i = 1:ObjectPools.MAX_POOL_SIZE]
    @test map(release, ds) == [true for i = 1:ObjectPools.MAX_POOL_SIZE]
    @test release(extra_obj) == false
end

@testset "Benchmarks" begin
    @info "Running benchmarks:"
    @info "Dict constructor: Dict{Int, Int}()"
    @btime Dict{Int, Int}()

    @info "Creating new objects when the pool is empty: allocate(Dict{Int, Int})"
    @test (@btime allocate(Dict{Int, Int})) isa Dict{Int, Int}

    @info "Acquire-Release: begin a=allocate(Dict{Int, Int}); release(a) end"
    @btime begin a=allocate(Dict{Int, Int}); release(a) end

    @info "Acquire-Release from locally cached pool: begin pool=ObjectPools.getpool(Dict{Int, Int}); a=allocate(pool, Dict{Int, Int}); release(pool, a) end"
    @btime begin pool=ObjectPools.getpool(Dict{Int, Int}); a=allocate(pool, Dict{Int, Int}); release(pool, a) end

    pool = ObjectPools.getpool(Dict{Int, Int})
    @info "Acquire-Release from a constant pool: begin a=allocate(pool, Dict{Int, Int}); release(pool, a) end"
    @btime begin a=allocate($pool, Dict{Int, Int}); release($pool, a) end
end
