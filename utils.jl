@enum Action begin
  adopt = 1
  override = 2
  match = 3
  wait = 4
end

@enum Fork begin
  irrelevant = 1
  relevant = 2
  active = 3
end

function d_adjust(d,w)
  return d * max(min((no_of_blocks * interblock) / w, 4), 1/4) 
  # return fd - fd % d_grid_size
end

function get_lambda(d)
  # expected_time = E[#hashes]/hashrate] = 1/λ
  return hashrate / (d*C)
end

function state_to_index(state)
  state[4] -= dmin
  index = 0 
  for i in reverse(1:state_space_dim)
    index += state[i]
    if i > 1
      index *= base_sizes[i-1]
    end
  end
  index + 1
end

function index_to_state(index)
  state = Vector{Int16}(undef, state_space_dim)
  index -= 1
  for i in 1:state_space_dim
    state[i] = index % base_sizes[i]
    index ÷= base_sizes[i]
  end
  state[4] += dmin
  state
end

