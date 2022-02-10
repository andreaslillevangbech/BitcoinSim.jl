function d_adjust(d, w)
    dnew = Int(floor(d * max(min((no_of_blocks * target_time) / w, 4), 1 / 4)))
    if (dnew < dmin) return dmin end
    if (dnew > dmax) return dmax end
    return dnew
    # return fd - fd % d_grid_size
end

function get_lambda(d)
    # expected_time = E[#hashes]/hashrate] = 1/λ
    return hashrate / (d * C)
end

function state_to_index(state) :: Int
    index = 0 
    for i in reverse(1:state_space_dim)
        index += state[i]
        if i == 4   # d does not start at 0
            index -= dmin
        end
        if i > 1
            index *= base_sizes[i - 1]
        end
    end
    if index > num_of_states
        println("Too BIG", state)
    elseif index < 0
        println("This state $state gives NEG index $index")
    end
    index + 1
end

function index_to_state(index)
    state = Vector{Int}(undef, state_space_dim)
    index -= 1
    for i = 1:state_space_dim
        state[i] = index % base_sizes[i]
        index ÷= base_sizes[i]
    end
    state[4] += dmin
    Tuple(state)
end

