# This file is a part of FragmentedArrays.jl, licensed under the MIT License (MIT).


@inline @generated function _tuple_drop_last{N}(tuple::NTuple{N,Any})
    result_expr = Expr(:tuple)
    for i in 1:N-1
        push!(result_expr.args, :(tuple[$i]))
    end
    result_expr
end


@inline @generated function _extend_tuple{N,K}(tuple::NTuple{N,Any}, ::Type{Val{K}}, x)
    result_expr = Expr(:tuple)
    for i in 1:N
        push!(result_expr.args, :(tuple[$i]))
    end
    for i in 1:K-N
        push!(result_expr.args, :x)
    end
    result_expr
end


@inline @generated function _tuple_replace_at{N,K}(tuple::NTuple{N,Any}, ::Type{Val{K}}, x)
    result_expr = Expr(:tuple)
    for i in 1:K-1
        push!(result_expr.args, :(tuple[$i]))
    end
    push!(result_expr.args, :x)
    for i in K+1:N
        push!(result_expr.args, :(tuple[$i]))
    end
    result_expr
end


# @inline @generated function _create_tuple{N}(::Type{Val{N}}, x)
#     result_expr = Expr(:tuple)
#     for i in 1:N-1
#         push!(result_expr.args, :x)
#     end
#     result_expr
# end


# @inline function _throw_boundserror_lastdim{T,N}(A::AbstractArray{T,N}, i::Integer)
#     idxs = _tuple_replace_at(_create_tuple(Val{N}, :), Val{N}, i)
#     Base.throw_boundserror(A, idxs)
# end

# @inline function _checkbounds_lastdim{T,N}(A::AbstractArray{T,N}, i::Integer)
#     checkindex(Bool, indices(A, N), i) || _throw_boundserror_lastdim(A, i)
#     nothing
# end
