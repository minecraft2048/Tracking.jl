"""
$(SIGNATURES)

Generic correlator holding a user defined number of correlation values.
"""
struct GenericCorrelator{T, M} <: AbstractCorrelator{T}
    taps::Vector{T}
    num_taps::NumTaps{M}
    early_index::Int64
    prompt_index::Int64
    late_index::Int64
end

"""
$(SIGNATURES)

GenericCorrelator constructor without parameters assumes a single antenna
and tree correlator elements.
"""
function GenericCorrelator()
    GenericCorrelator(NumAnts(1))
end

"""
$(SIGNATURES)

GenericCorrelator constructor that allows for the configuration of the
number of antenna elements using `num_ants::NumAnts{N}` The number of
correlator taps is fixed to three.
"""
function GenericCorrelator(num_ants::NumAnts{N}) where N
    GenericCorrelator(
        num_ants,
        NumTaps(3),
        2
    )
end

"""
$(SIGNATURES)

GenericCorrelator constructor that allows for the configuration of the
number of correlator taps using `num_taps::NumTaps{N}` The number of
antenne elements is fixed to one.
"""
function GenericCorrelator(num_taps::NumTaps{M}) where M
    GenericCorrelator(
        NumAnts(1),
        num_taps,
        2
    )
end

"""
$(SIGNATURES)

GenericCorrelator constructor that allows for the configuration of the
number of antenna elements using `num_ants::NumAnts{N}`, the number of
correlator taps using `num_taps::NumTaps{M}`. The early-late spacing
is fixed to 2.
"""
function GenericCorrelator(num_ants::NumAnts{N}, num_taps::NumTaps{M}) where {M, N}
    prompt_idx = ceil(M/2)
    GenericCorrelator(
        num_ants,
        num_taps,
        2
    )
end

"""
$(SIGNATURES)

GenericCorrelator constructor for single antenna correlation, that
allows for the configuration of the number of correlator taps using
`num_taps::NumTaps{M}` and the spacing of the early and late correlator
using `el_spacing`.
"""
function GenericCorrelator(num_ants::NumAnts{1}, num_taps::NumTaps{M}, el_spacing) where M
    prompt_index = ceil(Int64, M/2)
    early_index  = prompt_index + ceil(Int64, el_spacing/2)
    late_index   = prompt_index - ceil(Int64, el_spacing/2)
    @assert late_index <= M
    GenericCorrelator(
        [zero(ComplexF64) for i = 1:M],
        num_taps,
        early_index,
        prompt_index,
        late_index
    )
end

"""
$(SIGNATURES)

GenericCorrelator constructor that allows for the configuration of the
number of antenna elements using `num_ants::NumAnts{N}`, the number of
correlator taps using `num_taps::NumTaps{M}` and the spacing of the
early and late correlator using `el_spacing`.
"""
function GenericCorrelator(num_ants::NumAnts{N}, num_taps::NumTaps{M}, el_spacing) where {M, N}
    prompt_index = ceil(Int64, M/2)
    early_index  = prompt_index + ceil(Int64, el_spacing/2)
    late_index   = prompt_index - ceil(Int64, el_spacing/2)
    @assert late_index <= M
    GenericCorrelator(
        [zero(SVector{N, ComplexF64}) for i = 1:M],
        num_taps,
        early_index,
        prompt_index,
        late_index
    )
end


"""
$(SIGNATURES)

Get number of antennas from correlator
"""
get_num_ants(correlator::GenericCorrelator{Complex{T},M}) where {T,M} = 1
get_num_ants(correlator::GenericCorrelator{SVector{N,T},M}) where {T,M,N} = N

"""
$(SIGNATURES)

Get number of correlator taps
"""
get_num_taps(correlator::GenericCorrelator{T,M}) where {T,M} = M

"""
$(SIGNATURES)

Get early correlator index
"""
get_early_index(correlator::GenericCorrelator) = correlator.early_index

"""
$(SIGNATURES)

Get prompt correlator index
"""
get_prompt_index(correlator::GenericCorrelator) = correlator.prompt_index

"""
$(SIGNATURES)

Get late correlator index
"""
get_late_index(correlator::GenericCorrelator) = correlator.late_index

"""
$(SIGNATURES)

Get all correlator taps
"""
get_taps(correlator::GenericCorrelator) = correlator.taps

"""
$(SIGNATURES)

Get a specific correlator tap with `index` counted negative for late and
positive for early correlators.
"""
function get_tap(correlator::GenericCorrelator, index::Integer)
    correlator.taps[index+get_prompt_index(correlator)]
end

"""
$(SIGNATURES)

Get the early correlator
"""
function get_early(correlator::GenericCorrelator)
    correlator.taps[get_early_index(correlator)]
end

"""
$(SIGNATURES)

Get the prompt correlator
"""
function get_prompt(correlator::GenericCorrelator)
    correlator.taps[get_prompt_index(correlator)]
end

"""
$(SIGNATURES)

Get the late correlator
"""
function get_late(correlator::GenericCorrelator)
    correlator.taps[get_late_index(correlator)]
end

"""
$(SIGNATURES)

Reset the Correlator
"""
function zero(correlator::GenericCorrelator)
    GenericCorrelator(
        zero(correlator.taps),
        NumTaps(get_num_taps(correlator)),
        get_early_index(correlator),
        get_prompt_index(correlator),
        get_late_index(correlator)
    )
end

"""
$(SIGNATURES)

Filter the correlator by the function `post_corr_filter`
"""
function filter(post_corr_filter, correlator::GenericCorrelator)
    GenericCorrelator(
        map(x->post_corr_filter(x), get_taps(correlator)),
        NumTaps(get_num_taps(correlator)),
        get_early_index(correlator),
        get_prompt_index(correlator),
        get_late_index(correlator)
    )
end

"""
$(SIGNATURES)

Calculate the replica phase offset required for the correlator taps with
respect to the prompt correlator, expressed in samples. The shifts are
ordered from latest to earliest replica.
"""
function get_correlator_sample_shifts(
    system::AbstractGNSS,
    correlator::GenericCorrelator{T,M},
    sampling_frequency,
    preferred_code_shift
) where {T,M}
    numEl = floor(Int, M/2)
    SVector{M}(-numEl:numEl) .* round(Int, preferred_code_shift * sampling_frequency / get_code_frequency(system))
end

"""
$(SIGNATURES)

Calculate the total spacing between early and late correlator in samples.
"""
function get_early_late_sample_spacing(
    correlator::GenericCorrelator{T,M},
    correlator_sample_shifts::SVector{M}
) where {T,M}
    correlator_sample_shifts[get_early_index(correlator)] -
    correlator_sample_shifts[get_late_index(correlator)]
end

"""
$(SIGNATURES)

Normalize the correlator
"""
function normalize(correlator::GenericCorrelator, integrated_samples)
    GenericCorrelator(
        map(x->x/integrated_samples, get_taps(correlator)),
        NumTaps(get_num_taps(correlator)),
        get_early_index(correlator),
        get_prompt_index(correlator),
        get_late_index(correlator)
    )
end
"""
$(SIGNATURES)

Perform a correlation for multi antenna systems
"""
function correlate(
    correlator::GenericCorrelator,
    downconverted_signal::AbstractVector,
    code,
    correlator_sample_shifts,
    start_sample,
    num_samples
)
    taps = map(Vector(correlator_sample_shifts)) do correlator_sample_shift
        correlate_single_tap(
            correlator_sample_shift - correlator_sample_shifts[1],
            start_sample,
            num_samples,
            downconverted_signal,
            code
        )
    end

    return GenericCorrelator(
        map(+, get_taps(correlator), taps),
        NumTaps(get_num_taps(correlator)),
        get_early_index(correlator),
        get_prompt_index(correlator),
        get_late_index(correlator)
    )
end

function correlate_single_tap(
    offset,
    start_sample,
    num_samples,
    downconverted_signal,
    code
)
    tap = zero(eltype(downconverted_signal))
    @inbounds for i = start_sample:num_samples + start_sample - 1
        tap += downconverted_signal[i] * code[i + offset]
    end
    tap
end

"""
$(SIGNATURES)

Perform a correlation for multi antenna systems
"""
function correlate(
    correlator::GenericCorrelator{<: SVector{N}},
    downconverted_signal::AbstractMatrix,
    code,
    correlator_sample_shifts,
    start_sample,
    num_samples,
) where N
    taps = map(Vector(correlator_sample_shifts)) do correlator_sample_shift
        correlate_single_tap(
            NumAnts(N),
            correlator_sample_shift - correlator_sample_shifts[1],
            start_sample,
            num_samples,
            downconverted_signal,
            code
        )
    end
    GenericCorrelator(
        map(+, get_taps(correlator), taps),
        NumTaps(get_num_taps(correlator)),
        get_early_index(correlator),
        get_prompt_index(correlator),
        get_late_index(correlator)
    )
end

function correlate_single_tap(
    ::NumAnts{N},
    offset,
    start_sample,
    num_samples,
    downconverted_signal,
    code
) where N
    tap = zero(MVector{N, eltype(downconverted_signal)})
    @inbounds for j = 1:length(tap), i = start_sample:num_samples + start_sample - 1
        tap[j] += downconverted_signal[i,j] * code[i + offset]
    end
    SVector(tap)
end