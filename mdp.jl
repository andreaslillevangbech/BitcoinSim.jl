using LinearAlgebra

# Hyperparamters
const hashrate = 100 * 10^7  #Ghashes per second - exogenous total hashrate of network
const no_of_blocks = 10   # 2016 in protocol
const interblock = 600  #seconds
const share = 0.30  # Share of hashrate for attacker
const d_grid_size = 1
const Δt = 10  # seconds
const b = 6.25
const β = 0.99999  # in ]0, 1]
const max_fork = 50

# Constants
const offset = 0xffff * 2^208
# const C = (2^256-1)/offset
const C = 2^32

# Calculate size of state
# h, a ∈ [0,max_fork]
# s ∈ [0, 2015]
# d ∈ [300 * hashrate/C, 2 * 600*hashrate/C] Maybe set max to 2 times max(expected)
# w ∈ [0, dmax * 600 * no_of_blocks / 4]
# d adjustment cannot be more than 4 of less than 1/4
# Just set the hashrate very small, that downscales the problem
# NOTE: potential bug in w
# Dmax = 600*h/C
# time = DmaxC/h
# time = (600*h/C) * C / h = 600

const dmax = 2 * interblock * hashrate / C
const dmin = dmax / 4
const base_sizes = (
  max_fork,  # h
  max_fork,  # a
  no_of_blocks,  # s
  Int((dmax - dmin) ÷ d_grid_size),  # d in grid
  Int(floor(2 * interblock * no_of_blocks / Δt))  # w  times 2 is about 99% quantile
)

const state_space_dim = length(base_sizes)
const num_of_states = prod(base_sizes)

# Maybe state should just be a vector
mutable struct State
  h::Int16  # Length of honest branch
  a::Int16  # Length of attackers branch
  s::Int16  # Settled blocks since fork
  d::Int16  # Current difficulty (discretized)
  w::Int16  # Time steps since adjustment
  State() = new(0,0,0,dmax,0)  # Init
end

@enum Action begin
  adopt = 1
  override = 2
  wait = 3
end



function set_transition(index, P::Matrix{Float64}[])

  h,a,s,d,w = index_to_state(index)

  @assert h>=0
  @assert a>=0
  @assert no_of_blocks > s >= 0
  @assert dmax >= d >= dmin

  # probas
  λ = get_lambda(d) 
  p_a = Δt*share*λ
  p_h = Δt*(1-share)*λ

  # adopt
  if h>0
    if s + h < no_of_blocks
      # honest
      P[Int(adopt)][index,
      state_to_index([1,0,s+h,d,w+1])] = p_h
      # attack
      P[Int(adopt)][index,
      state_to_index([0,1,s+h,d,w+1])] = p_a
      # No block
      P[Int(adopt)][index,
      state_to_index([0,0,s+h,d,w+1])] = 1 - p_h - p_a
    else
      s_new = s + h % no_of_blocks
      # honest
      P[Int(adopt)][index,
      state_to_index([1,0,s_new,d_adjust(d,w),0])] = p_h
      # attack
      P[Int(adopt)][index,
      state_to_index([0,1,s_new,d_adjust(d,w),0])] = p_a
      # No block
      P[Int(adopt)][index,
      state_to_index([0,0,s_new,d_adjust(d,w),0])] = 1 - p_h - p_a
    end
  end

  # override
  if a > h
    if s + h + 1 < no_of_blocks
      # honest
      P[Int(override)][index,
      state_to_index([1,a-h-1,s+h+1,d,w+1])] = p_h
      # attack
      P[Int(override)][index,
      state_to_index([0,a-h,s+h+1,d,w+1])] = p_a
      # No block
      P[Int(override)][index,
      state_to_index([0,a-h-1,s+h+1,d,w+1])] = 1 - p_h - p_a

    # difficulty adjustment  
    else
      s_new = s + h + 1 % no_of_blocks
      # honest
      P[Int(override)][index,
      state_to_index([1,a-h-1,s_new,d_adjust(d,w),0])] = p_h
      # attack
      P[Int(override)][index,
      state_to_index([0,a-h,s_new,d_adjust(d,w),0])] = p_a
      # No block
      P[Int(override)][index,
      state_to_index([0,a-h-1,s_new,d_adjust(d,w),0])] = 1 - p_h - p_a
    end
  end

  # wait
  P[Int(wait)][index,
  state_to_index([h+1,a,s,d,w+1])] = p_h
  P[Int(wait)][index,
  state_to_index([h,a+1,s,d,w+1])] = p_a
  P[Int(wait)][index,
  state_to_index([h,a,s,d,w+1])] = 1 - p_h - p_a

end   set_transition



