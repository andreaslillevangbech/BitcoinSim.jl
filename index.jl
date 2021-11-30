const base_sizes = [234,45,12,2]
const dim = length(base_sizes)

function state_to_index(state)
  index = 0 
  for i in reverse(1:dim)
    index += state[i]
    if i > 1
      index *= base_sizes[i-1]
    end
  end
  index + 1
end

s = [23,6,4,1]
state_size = prod(base_sizes)

for r in 0:s[4]
  for k in 0:s[3]
    for j in 0:s[2]
      for i in 0:s[1]
        println(state_to_index([i,j,k,r]))
      end
    end
  end
end

@info s
@info state_size
@info state_to_index(s)

function index_to_state(index)
  state = Vector{Int16}(undef, dim)
  index -= 1
  for i in 1:dim
    state[i] = index % base_sizes[i]
    index ÷= base_sizes[i]
  end
  state
end


index = state_to_index(s)
println(index)
state = index_to_state(index)
println(state)

