function set_transition(index, IJV)

  # IJV is a list of tuples for each action
  # a tuple is a transition for a given action
  # call IJV |> zip |> collect to get the I, J, V
  # vectors for COO sparse matrix format

  h,a,s,d,w = index_to_state(index)
  @assert h>=0
  @assert a>=0
  @assert no_of_blocks > s >= 0
  @assert dmax >= d >= dmin

  # probas
  λ = get_lambda(d) 
  q = Δt*share*λ   # Attacker proba
  p = Δt*(1-share)*λ

  # Need, for each action, I, J, V
  # I assume you you append to vectors I, J, V for each action

  # adopt
  if h>0
    if s + h < no_of_blocks
      # honest
      push!(IJV[Int(adopt)],(index,
                    state_to_index([1,0,s+h,d,w+1]), p))
      # attack
      push!(IJV[Int(adopt)],(index,
                    state_to_index([0,1,s+h,d,w+1]), q))
      # No block
      push!(IJV[Int(adopt)],(index,
                    state_to_index([0,0,s+h,d,w+1]), 1 - p - q))
    else
      s_new = s + h % no_of_blocks
      # honest
      push!(IJV[Int(adopt)],(index,
                    state_to_index([1,0,s_new,d_adjust(d,w),0]), p))
      # attack
      push!(IJV[Int(adopt)],(index,
                    state_to_index([0,1,s_new,d_adjust(d,w),0]), q))
      # No block
      push!(IJV[Int(adopt)],(index,
                    state_to_index([0,0,s_new,d_adjust(d,w),0]), 1 - p - q))
    end
  end

  # override
  if a > h
    if s + h + 1 < no_of_blocks
      # honest
      push!(IJV[Int(override)],(index,
                       state_to_index([1,a-h-1,s+h+1,d,w+1]), p))
      # attack
      push!(IJV[Int(override)],(index,
                       state_to_index([0,a-h,s+h+1,d,w+1]), q))
      # No block
      push!(IJV[Int(override)],(index,
                       state_to_index([0,a-h-1,s+h+1,d,w+1]), 1 - p - q))

    # difficulty adjustment  
    else
      s_new = s + h + 1 % no_of_blocks
      # honest
      push!(IJV[Int(override)],(index,
                       state_to_index([1,a-h-1,s_new,d_adjust(d,w),0]), p))
      # attack
      push!(IJV[Int(override)],(index,
                       state_to_index([0,a-h,s_new,d_adjust(d,w),0]), q))
      # No block
      push!(IJV[Int(override)],(index,
                       state_to_index([0,a-h-1,s_new,d_adjust(d,w),0]), 1 - p - q))
    end
  end

  # wait
  push!(IJV[Int(wait)],(index,
               state_to_index([h+1,a,s,d,w+1]), p))
  push!(IJV[Int(wait)],(index,
               state_to_index([h,a+1,s,d,w+1]), q))
  push!(IJV[Int(wait)],(index,
               state_to_index([h,a,s,d,w+1]), 1 - p - q))

end  # set_transition
