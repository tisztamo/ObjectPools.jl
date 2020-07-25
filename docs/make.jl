using Documenter, ObjectPools

makedocs(
    modules = [ObjectPools],
    format = Documenter.HTML(; prettyurls = get(ENV, "CI", nothing) == "true"),
    authors = "Schaffer Krisztian",
    sitename = "ObjectPools.jl",
    pages = Any["index.md"]
    # strict = true,
    # clean = true,
    # checkdocs = :exports,
)

deploydocs(
    repo = "github.com/tisztamo/ObjectPools.jl.git",
    push_preview = true
)
