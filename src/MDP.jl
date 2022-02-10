using LinearAlgebra
using SparseArrays

include("Utils.jl")
include("Types.jl")

# Hyperparamters
const hashrate     = 100 * 10^7  #Ghashes per second - exogenous total hashrate of network
const no_of_blocks = 10   # 2016 in protocol
const interblock   = 60  #seconds
const share        = 0.30  # Share of hashrate for attacker
const γ            = 0.40
const d_grid_size  = 1
const Δt           = 1  # seconds
const b            = 6.25
const β            = 0.99999  # in ]0, 1]
const max_fork     = 5

# Constants
const offset       = 0xffff * 2^208
# const C          = (2^256-1)/offset
const C            = 2^32

const dmax         = Int(floor(2 * interblock * hashrate / C))
const dmin         = dmax ÷ 4
const wmax         = 2 * interblock * no_of_blocks 
const base_sizes = (
    max_fork + 1,  # h
    max_fork + 1,  # a
    no_of_blocks,  # s
    (dmax - dmin) ÷ d_grid_size,  # d in grid
    wmax ÷ Δt,  # w  times 2 is about 99% quantile
    3,         # Number of fork states
)

const state_space_dim = length(base_sizes)
const num_of_states   = prod(base_sizes)
const num_of_actions  = 4


# NOTE:
# Build a sparse matrix of SxS for each action in A.
# Build a function that only return the available actions ???

function build_mdp()

    COO = Vector{Union{Vector{Int},Vector{Float64}}}[]
    for act in 1:num_of_actions
        push!(COO, [[num_of_states], [num_of_states], [0.0]])
    end

    for index in 1:num_of_states
        set_transition!(COO, index)
    end

    # for act in 1:num_of_actions
    #     COO = zip(P[act]...) .|> collect
    #     println(typeof(COO))
    # end
    # P = sparse(COO...)
    
    P = Vector{SparseMatrixCSC{Float64, Int64}}(undef, num_of_actions)
    for act in 1:num_of_actions
        P[act] = sparse(COO[act]...)
    end

    return P
end

function add_to_coo!(coo, tup)
    for i in 1:3
        push!(coo[i], tup[i])
    end
end


function set_transition!(P, index)

    h, a, s, d, w, fork = index_to_state(index)

    if (w + Δt >= wmax) w -= Δt end

    fork = Fork(fork)
    # NOTE : Actions are adopt, override, match, wait
  
    @assert h >= 0
    @assert a >= 0
    @assert no_of_blocks > s >= 0
    @assert dmax >= d >= dmin
  
    # probas
    λ = get_lambda(d)
    q = Δt * share * λ
    p = Δt * (1 - share) * λ
  
    # match
    if (a >= h) && (fork == relevant) && (a < max_fork)
        add_to_coo!(
            P[Int(match)],
            (
                index,  # honest miner on honest chain
                state_to_index((h + 1, a, s, d, w + Δt, Int(relevant))),
                p * (1 - γ),
            )
        )
        add_to_coo!(
            P[Int(match)], 
            (
                index,  # attacker get one and keeps secret
                state_to_index((h, a + 1, s, d, w + Δt, Int(irrelevant))),
                q,
            )
        )
        add_to_coo!(
            P[Int(match)],
            (
                index, # no block and fork stays active
                state_to_index((h, a, s, d, w + Δt, Int(active))),
                1 - q - p * γ - p * (1 - γ),
            )
        )
  
        # Honest miner on attacker chain and h blocks are then settled
        if s + h < no_of_blocks
            add_to_coo!(
                P[Int(match)],
                (index, state_to_index((1, a - h, s + h, d, w + Δt, Int(irrelevant))), p * γ),
            )
  
        else
            s_new = (s + h) % no_of_blocks
            add_to_coo!(
                P[Int(match)],
                (
                    index,
                    state_to_index((1, a - h, s_new, d_adjust(d, w), 0, Int(irrelevant))),
                    p * γ,
                ),
            )
        end
    end
  
  
    # adopt
    if h > 0
        if s + h < no_of_blocks
            # honest
            add_to_coo!(P[Int(adopt)], (index, state_to_index((1, 0, s + h, d, w + Δt, Int(relevant))), p))
            # attack
            add_to_coo!(
                P[Int(adopt)],
                (index, state_to_index((0, 1, s + h, d, w + Δt, Int(irrelevant))), q),
            )
            # No block
            add_to_coo!(
                P[Int(adopt)],
                (index, state_to_index((0, 0, s + h, d, w + Δt, Int(fork))), 1 - p - q),
            )
        else
            s_new = (s + h) % no_of_blocks
            # honest
            add_to_coo!(
                P[Int(adopt)],
                (index, state_to_index((1, 0, s_new, d_adjust(d, w), 0, Int(relevant))), p),
            )
            # attack
            add_to_coo!(
                P[Int(adopt)],
                (index, state_to_index((0, 1, s_new, d_adjust(d, w), 0, Int(irrelevant))), q),
            )
            # No block
            add_to_coo!(
                P[Int(adopt)],
                (index, state_to_index((0, 0, s_new, d_adjust(d, w), 0, Int(fork))), 1 - p - q),
            )
        end
    end
  
    # override
    if a > h
        if s + h + 1 < no_of_blocks
            # honest
            add_to_coo!(
                P[Int(override)],
                (index, state_to_index((1, a - h - 1, s + h + 1, d, w + Δt, Int(relevant))), p),
            )
            # attack
            add_to_coo!(
                P[Int(override)],
                (index, state_to_index((0, a - h, s + h + 1, d, w + Δt, Int(irrelevant))), q),
            )
            # No block
            add_to_coo!(
                P[Int(override)],
                (index, state_to_index((0, a - h - 1, s + h + 1, d, w + Δt, Int(fork))), 1 - p - q),
            )
  
            # difficulty adjustment
        else
            s_new = (s + h + 1) % no_of_blocks
            # honest
            add_to_coo!(
                P[Int(override)],
                (index, state_to_index((1, a - h - 1, s_new, d_adjust(d, w), 0, Int(relevant))), p),
            )
            # attack
            add_to_coo!(
                P[Int(override)],
                (index, state_to_index((0, a - h, s_new, d_adjust(d, w), 0, Int(irrelevant))), q),
            )
            # No block
            add_to_coo!(
                P[Int(override)],
                (
                    index,
                    state_to_index((0, a - h - 1, s_new, d_adjust(d, w), 0, Int(fork))),
                    1 - p - q,
                ),
            )
        end
    end
  
    # wait
    if (a < max_fork) && (h < max_fork)
        if (fork == active) && (a >= h)
            add_to_coo!(
                P[Int(wait)],
                (
                    index,  # honest miner on honest chain
                    state_to_index((h + 1, a, s, d, w + Δt, Int(relevant))),
                    p * (1 - γ),
                ),
            )
            add_to_coo!(P[Int(wait)], (
                index,  # attacker get one and keeps secret
                state_to_index((h, a + 1, s, d, w + Δt, Int(irrelevant))),
                q,
            ))
            add_to_coo!(
                P[Int(wait)],
                (
                    index, # no block and fork stays active
                    state_to_index((h, a, s, d, w + Δt, Int(active))),
                    1 - q - p * γ - p * (1 - γ),
                ),
            )
      
            # Honest miner on attacker chain and h blocks are then settled
            if s + h < no_of_blocks
                add_to_coo!(
                    P[Int(wait)],
                    (index, state_to_index((1, a - h, s + h, d, w + Δt, Int(irrelevant))), p * γ),
                )
      
            else
                s_new = (s + h) % no_of_blocks
                add_to_coo!(
                    P[Int(wait)],
                    (
                        index,
                        state_to_index((1, a - h, s_new, d_adjust(d, w), 0, Int(irrelevant))),
                        p * γ,
                    ),
                )
            end
      
        else
            add_to_coo!(P[Int(wait)], (index, state_to_index((h + 1, a, s, d, w + Δt, Int(relevant))), p))
            add_to_coo!(P[Int(wait)], (index, state_to_index((h, a + 1, s, d, w + Δt, Int(irrelevant))), q))
            add_to_coo!(P[Int(wait)], (index, state_to_index((h, a, s, d, w + Δt, Int(irrelevant))), 1 - p - q))
        end
    end

end  #  set_transition



