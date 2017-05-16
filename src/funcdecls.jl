# This file is a part of FragmentedArrays.jl, licensed under the MIT License (MIT).

"
    size_lastdim(A::AbstractArray)
"
function size_lastdim end
export size_lastdim

"
    freesize_lastdim(A::AbstractArray; in_front::Bool = false)
"
function freesize_lastdim end
export freesize_lastdim

"
    extendable_lastdim(A::AbstractArray)
"
function extendable_lastdim end
export extendable_lastdim

"
    resize_lastdim!(A::AbstractArray, n::Integer; in_front::Bool = false)
"
function resize_lastdim! end
export resize_lastdim!

"
    sizehint_lastdim!(A::AbstractArray, n::Integer)
"
function sizehint_lastdim! end
export sizehint_lastdim!

"
    append_lastdim!(A::AbstractArray, B::AbstractArray) -> A
"
function append_lastdim! end
export append_lastdim!

"
    prepend_lastdim!(A::AbstractArray, B::AbstractArray) -> A
"
function prepend_lastdim! end
export prepend_lastdim!
