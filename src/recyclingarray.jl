# This file is a part of FragmentedArrays.jl, licensed under the MIT License (MIT).

export RecyclingArray

type RecyclingArray{ArrayT<:DenseArray,T,N} <: DenseArray{T,N}
    data::ArrayT
    first_dims_n::Int
    n_free_front::Int
    n_free_back::Int
    extendable::Bool
end


function (::Type{RecyclingArray{ArrayT,T,N}}){ArrayT<:DenseArray,T,N}(
    dims::Integer...;
    reserve_front::Int = 0, reserve_back::Int = 0, extendable::Bool = (ndims(ArrayT) == 1)
)
    T != eltype(ArrayT) && throw(ArgumentError("type $T doesn't match element type of $ArrayT"))
    N != ndims(ArrayT) && throw(ArgumentError("number of dimensions $N doesn't match dimensionality of $ArrayT"))
    N_dims = length(dims)
    N_dims != 0 && N_dims != N && throw(ArgumentError("number or size arguments and array dimensionality don't match"))
    extendable && N != 1 && throw(ArgumentError("multi-dimensional RecyclingArray cannot be extendable"))
    reserve_front < 0 && throw(ArgumentError("reserve_front must be ≥ 0"))
    reserve_back < 0 && throw(ArgumentError("reserve_back must be ≥ 0"))
    initial_size = _extend_tuple(dims, Val{N}, 0)
    data_size = _tuple_replace_at(initial_size, Val{N}, initial_size[N] + reserve_front + reserve_back)
    first_dims_n = prod(_tuple_replace_at(initial_size, Val{N}, 1))
    RecyclingArray{ArrayT,T,N}(ArrayT(data_size...), first_dims_n, reserve_front, reserve_back, extendable)
end


function RecyclingArray{T,N}(data::AbstractArray{T, N}; extendable::Bool = (N == 1))
    A = RecyclingArray{typeof(data),T,N}(size(data)..., extendable = extendable)
    @assert size(A.data) == size(data)
    copy!(A.data, data)
    A
end


@inline size_lastdim{T,N}(A::AbstractArray{T,N}) = size(A, N)

@inline function size_lastdim{ArrayT,T,N}(A::RecyclingArray{ArrayT,T,N})
    s = size(A.data, N)
    s - typeof(s)(A.n_free_front + A.n_free_back)
end


@inline freesize_lastdim{ArrayT,T,N}(A::RecyclingArray{ArrayT,T,N}; in_front::Bool = false) =
    in_front ? A.n_free_front : A.n_free_back

@inline extendable_lastdim{ArrayT,T,N}(A::RecyclingArray{ArrayT,T,N}) = A.extendable


@inline Base.size{ArrayT,T,N}(A::RecyclingArray{ArrayT,T,N}, i::Integer) =
    i == N ? size_lastdim(A) : size(A.data, i)

@inline Base.size{ArrayT,T,N}(A::RecyclingArray{ArrayT,T,N}) =
    _tuple_replace_at(size(A.data), Val{N}, size_lastdim(A))



@inline _recycling_array_idx{T,N}(data::DenseArray{T,N}, first_dims_n::Int, n_free_front::Int, i::Real) =
    Base.to_index(first_dims_n * n_free_front + i)

Base.linearindexing(A::RecyclingArray) = Base.LinearFast()

@inline Base.@propagate_inbounds function Base.getindex{ArrayT,T,N}(A::RecyclingArray{ArrayT,T,N}, i::Real)
    data = A.data
    data[_recycling_array_idx(data, A.first_dims_n, A.n_free_front, i)]
end

@inline Base.@propagate_inbounds function Base.setindex!{ArrayT,T,N}(A::RecyclingArray{ArrayT,T,N}, x, i::Real)
    data = A.data
    data[_recycling_array_idx(data, A.first_dims_n, A.n_free_front, i)] = x
    A
end


@inline Base.@propagate_inbounds function Base.pointer{ArrayT,T,N}(A::RecyclingArray{ArrayT,T,N}, index::Integer = 1)
    data = A.data
    pointer(data, _recycling_array_idx(data, A.first_dims_n, A.n_free_front, index))
end

@inline Base.@propagate_inbounds function Base.Ref{ArrayT,T,N}(A::RecyclingArray{ArrayT,T,N}, index::Integer = 1)
    data = A.data
    Ref(data, _recycling_array_idx(data, A.first_dims_n, A.n_free_front, index))
end


_array_grow_front(A::Array, n) = ccall(:jl_array_grow_beg, Void, (Any, UInt), A, n)


Base.@propagate_inbounds Base.resize!{ArrayT,T}(A::RecyclingArray{ArrayT,T,1}, n::Integer) =
    resize_lastdim!(A, n)

Base.@propagate_inbounds function resize_lastdim!{ArrayT,T,N}(A::RecyclingArray{ArrayT,T,N}, n::Integer; in_front::Bool = false)
    n < 0 && throw(ArgumentError("new length must be ≥ 0"))
    data = A.data
    l = size_lastdim(A)
    reserve = in_front ? A.n_free_front : A.n_free_back
    delta_n = n - l
    if delta_n <= reserve
        new_reserve = reserve - delta_n
        @assert new_reserve >= 0        
        if in_front
            A.n_free_front = new_reserve
        else
            A.n_free_back = new_reserve
        end
        @assert A.n_free_front + A.n_free_back <= size(data, N)
    else
        A.extendable || throw(ArgumentError("array is not extendable"))
        @assert N == 1
        n_extend = delta_n - reserve
        if in_front
            _array_grow_front(data, n_extend)
            A.n_free_front = 0
        else
            resize!(data, n_extend + size(data, N))
            A.n_free_back = 0
        end
    end
    A
end


Base.sizehint!{ArrayT,T}(A::RecyclingArray{ArrayT,T,1}, n::Integer) =
    sizehint_lastdim(A, n)

function sizehint_lastdim!{ArrayT,T,N}(A::RecyclingArray{ArrayT,T,N}, n::Integer)
    s = size_lastdim(A)
    if n > s
        resize_lastdim!(A, n)
        resize_lastdim!(A, s)
    end
end


function Base.push!{ArrayT,T}(A::RecyclingArray{ArrayT,T,1}, x)
    x_T = convert(T, x)
    resize_lastdim!(A, size_lastdim(A) + 1, in_front = false)
    @inbounds A[last(linearindices(A))] = x_T
    return A
end

function Base.pop!{ArrayT,T}(A::RecyclingArray{ArrayT,T,1})
    s = size_lastdim(A)
    isempty(A) && throw(ArgumentError("array must not be empty"))
    x = @inbounds A[last(linearindices(A))]
    resize_lastdim!(A, size_lastdim(A) - 1, in_front = false)
    x
end

function Base.unshift!{ArrayT,T}(A::RecyclingArray{ArrayT,T,1}, x)
    x_T = convert(T, x)
    resize_lastdim!(A, size_lastdim(A) + 1, in_front = true)
    @inbounds A[first(linearindices(A))] = x_T
    return A
end

function Base.shift!{ArrayT,T}(A::RecyclingArray{ArrayT,T,1})
    s = size_lastdim(A)
    isempty(A) && throw(ArgumentError("array must not be empty"))
    x = @inbounds A[first(linearindices(A))]
    resize_lastdim!(A, size_lastdim(A) - 1, in_front = true)
    x
end


function _append_lastdim_impl!{ArrayT,T,N,M}(A::RecyclingArray{ArrayT,T,N}, B::AbstractArray{T,M}; in_front::Bool = false)
    (M > N) && throw(DimensionMismatch("dimensionality of B is higher than dimensionality of A"))
    size_B = size(B)
    ext_size_B = _extend_tuple(size_B, Val{N}, one(eltype(size_B)))
    if (_tuple_drop_last(size(A)) != _tuple_drop_last(ext_size_B))
        throw(DimensionMismatch("array sizes do not match in all dimensions except last"))
    end
    dest_offs = in_front ? 1 : length(A) + 1
    data = A.data
    data_dest_offs = _recycling_array_idx(data, A.first_dims_n, A.n_free_front, dest_offs)
    sz_l_A_1 = size_lastdim(A) + 1
    resize_lastdim!(A, size_lastdim(A) + ext_size_B[N], in_front = in_front)
    copy!(data, data_dest_offs, B, 1, length(B))
    A
end

Base.append!{ArrayT,T}(A::RecyclingArray{ArrayT,T,1}, B::AbstractVector) =
    _append_lastdim_impl!(A, B, in_front = false)

append_lastdim!(A::RecyclingArray, B::AbstractArray) =
    _append_lastdim_impl!(A, B, in_front = false)

prepend_lastdim!(A::RecyclingArray, B::AbstractArray) =
    _append_lastdim_impl!(A, B, in_front = true)
