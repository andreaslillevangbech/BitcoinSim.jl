# Constants
const hashrate = 100 * 10^7  #Ghashes per second - exogenous total hashrate of network
const C = 2^48 ÷ 0xffff # 2^256 / (0xffff * 2^208)
# const C = 2^32 # approximation

const dmax = 2 * interblock * hashrate / C    # estimate of upper bound on d
const dmin = dmax / 4  # estimate of lower bound on d

function simulation(init_state, policy, sims, verbose=false)

  value = 0
  discount = 1
  state = init_state
  attack = true  # For intermittent SM

  # main loop for one simulation
  for i = 1:N
    action = policy(state, attack)
    new_states, reward, update = transition(state, action)
    if update 
      attack = !attack
    end
    # sim = rand()
    sim = sims[i]
    proba = 0
    for new_state in new_states
      proba += last(new_state)
      if sim < proba
        state = first(new_state)
        break
      end
    end

    discount *= β
    value += reward * discount

    if verbose
      d = state[4]
      if i % (2016*600) == 0
        println("d = ", d)
      end
    end

  end

  return value
end  # function



function transition(state, action)

  h,a,s,d,w = state
  reward = 0
  update = false

  λ = get_lambda(d) 
  q = Δt*share*λ
  p = Δt*(1-share)*λ

  # List of (state, proba)
  new_states = Array{Tuple{
                     Tuple{Int, Int, Int, Float64, Int}, 
                     Float64
                    }}(undef, 3)


  if action == adopt
    @assert h > 0
    if s + h < no_of_blocks
      new_states[1] = 
            ((1,0,s+h,d,w+1), p)
      new_states[2] = 
            ((0,1,s+h,d,w+1), q)
      new_states[3] = 
            ((0,0,s+h,d,w+1), 1-p-q) # Note this is ruling out finding two blocks
    else
      update = true
      s_new = (s + h) % no_of_blocks
      # honest
      new_states[1] = 
            ((1,0,s_new,d_adjust(d,w),0), p)
      # attack
      new_states[2] = 
            ((0,1,s_new,d_adjust(d,w),0), q)
      # No block
      new_states[3] = 
            ((0,0,s_new,d_adjust(d,w),0), 1 - p - q)
    end

  elseif action == override
    @assert a > h
    reward = b * (h + 1)
    if s + h + 1 < no_of_blocks
      # honest
      new_states[1] = 
            ((1,a-h-1,s+h+1,d,w+1), p)
      # attack
      new_states[2] = 
            ((0,a-h,s+h+1,d,w+1), q)
      # No block
      new_states[3] = 
            ((0,a-h-1,s+h+1,d,w+1), 1 - p - q)

    # difficulty adjustment  
    else
      update = true
      s_new = (s + h + 1) % no_of_blocks
      # honest
      new_states[1] = 
            ((1,a-h-1,s_new,d_adjust(d,w),0), p)
      # attack
      new_states[2] = 
            ((0,a-h,s_new,d_adjust(d,w),0), q)
      # No block
      new_states[3] = 
            ((0,a-h-1,s_new,d_adjust(d,w),0), 1 - p - q)
    end

  elseif action == wait
    new_states[1] = 
          ((h+1,a,s,d,w+1), p)
    new_states[2] = 
          ((h,a+1,s,d,w+1), q)
    new_states[3] = 
          ((h,a,s,d,w+1), 1 - p - q)

  else
    ArgumentError("Not an action")
  end

  return new_states, reward, update
end # function


#function trans(action, state)
# 
#   λ = get_lambda(state.d) 
#   q = Δt*share*λ
#   p = Δt*(1-share)*λ
# 
#   sim = rand()
# 
#   if action == adopt
#     if state.s + state.h < no_of_blocks
#       if sim <
# 
