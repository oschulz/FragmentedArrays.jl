# This file is a part of FragmentedArrays.jl, licensed under the MIT License (MIT).

__precompile__(true)

module FragmentedArrays

include.([
    "funcdecls.jl",
    "util.jl",
    "recyclingarray.jl",
    "fragmentedarray.jl",
])

end # module
