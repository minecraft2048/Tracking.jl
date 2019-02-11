function veryearly(x::SVector{N,T}) where {N,T}
    x[(N - 1) >> 1 + 3]
end

function early(x::SVector{N,T}) where {N,T}
    x[(N - 1) >> 1 + 2]
end

function prompt(x::SVector{N,T}) where {N,T}
    x[(N - 1) >> 1 + 1]
end

function late(x::SVector{N,T}) where {N,T}
    x[(N - 1) >> 1]
end

function verylate(x::SVector{N,T}) where {N,T}
    x[(N - 1) >> 1 - 1]
end

"""
$(SIGNATURES)

Calculates the code offset in chips.
"""
function dll_disc(x, d = 1)
    E = abs(early(x))
    L = abs(late(x))
    (E - L) / (E + L) / 2 / (2 - d)
end


"""
$(SIGNATURES)

Calculates the phase error in radians.
"""
function pll_disc(x)
    p = prompt(x)
    atan(imag(p) / real(p))
end
