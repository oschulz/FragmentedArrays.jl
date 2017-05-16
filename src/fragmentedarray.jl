# This file is a part of FragmentedArrays.jl, licensed under the MIT License (MIT).

using Base.Threads


type FragmentedArray{ArrayT<:DenseArray,T,N} <: AbstractArray{T,N}
    fragments = Array{ArrayFragment{ArrayT,T,N}}
    fragmentsize::NTuple{N,Int}
    fragment_lookup_valid::Bool
    fragment_lookup_table::Array{Int}
    fragment_lookup_lock::TatasLock
end


function _update_fragment_lookup(A::FragmentedArray)
    lock(A.fragment_lookup_lock) do
        fragments = A.fragments
        cum_fragment_len = A.cum_fragment_len
        resize!(cum_fragment_len, length(fragments))
        last_cum_len = zero(Int)
        @simd @inbounds for i in eachindex(cum_fragment_len, fragments)
            last_cum_len = cum_fragment_len[i] = Int(last + length(linearindices(fragments[i])))
        end
        A.fragment_lookup_valid = true
    end
end


function ensure_fragment_lookup(A::FragmentedArray)  
    if !A.fragment_lookup_valid
        _update_fragment_lookup(A)
    end
    nothing
end


function find_fragment(A::FragmentedArray, i::Integer)
    ensure_fragment_lookup(A)
    searchsortedfirst(A.fragment_lookup_table, i)
end
