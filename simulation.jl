# Constants
const hashrate = 100 * 10^7  #Ghashes per second - exogenous total hashrate of network
const C = 2^48 ÷ 0xffff # 2^256 / (0xffff * 2^208)
# const C      = 2^32 # approximation
const dmean = target_time * hashrate / C    # estimate of upper bound on d
const dmax = 2 * dmean
const dmin = dmax / 4  # estimate of lower bound on d

function simulation(policy, init_state, sims, params; verbose = false)

    value = 0
    discount = 1
    stale_h = 0
    stale_a = 0
    epochs = 0
    state = init_state

    # main loop for one simulation
    for i = 1:(params.N)
        action = policy(state)
        new_states = transition(state, action, params)
        discount *= β

        sim = sims[i]
        proba = 0
        for new_state in new_states
            proba += new_state[2]
            if sim < proba
                state = first(new_state)
                reward = new_state[3]
                value += reward * discount
                stale_h += new_state[4][1]
                stale_a += new_state[4][2]
                epochs += new_state[5]
                break
            end
        end

        if verbose
            d = state[4]
            if i % (2016 * 600) == 0
                println("d = ", d)
            end
        end
    end

    return value, (stale_h, stale_a), epochs
end  # function


function transition(state, action, params)

    h, a, s, d, w, fork = state
    epoch = false
    reward = 0

    λ = get_lambda(d)
    q = Δt * params.share * λ
    p = Δt * (1 - params.share) * λ

    # List of (state, proba, reward, stales, epoch)
    new_states = Array{Tuple{Tuple{Int,Int,Int,Float64,Int,Fork},Float64,Float64,Tuple{Int,Int},Bool}}(undef, 4)

    # NOTE: Need to rewrite logic such that when s+(a|h) > 2016 then difficuly increases...

    # If you match then it puts the network into a forked state
    if action == match || (fork == active && action == wait)
        stales = (0, 0)
        @assert a >= h
        @assert fork in (relevant, active)
        new_states[1] =       # honest miner on honest chain
            ((h + 1, a, s, d, w + 1, relevant), p * (1 - params.γ), reward, stales, epoch)
        new_states[2] =       # attacker get one and keeps secret
            ((h, a + 1, s, d, w + 1, irrelevant), q, reward, stales, epoch)
        new_states[3] =       # no block and fork stays active
            ((h, a, s, d, w + 1, active), 1 - q - p * params.γ - p * (1 - params.γ), reward, stales, epoch)

        # Honest miner on attacker chain and h blocks are then settled
        # NOTE: Rewrite reward into transition!!!
        reward = b * h
        stales = (h, 0)

        if s + h < no_of_blocks
            new_states[4] = ((1, a - h, s + h, d, w + 1, irrelevant), p * params.γ, reward, stales, epoch)
        else
            epoch = true
            s_new = (s + h) % no_of_blocks
            new_states[4] = ((1, a - h, s_new, d_adjust(d, w), 0, irrelevant), p * params.γ, reward, stales, epoch)
        end

        # Else if fork is not active fork becomes irrelevant
        fork = irrelevant

    elseif action == adopt
        stales = (0, a)
        @assert h > 0
        if s + h < no_of_blocks
            new_states[1] = ((1, 0, s + h, d, w + 1, relevant), p, reward, stales, epoch)
            new_states[2] = ((0, 1, s + h, d, w + 1, irrelevant), q, reward, stales, epoch)
            new_states[3] = ((0, 0, s + h, d, w + 1, fork), 1 - p - q, reward, stales, epoch) # Note this is ruling out finding two blocks

        # difficulty adjustment
        else
            epoch = true
            s_new = (s + h) % no_of_blocks
            # honest
            new_states[1] = ((1, 0, s_new, d_adjust(d, w), 0, relevant), p, reward, stales, epoch)
            # attack
            new_states[2] = ((0, 1, s_new, d_adjust(d, w), 0, irrelevant), q, reward, stales, epoch)
            # No block
            new_states[3] = ((0, 0, s_new, d_adjust(d, w), 0, fork), 1 - p - q, reward, stales, epoch)
        end


    elseif action == override
        stales = (h, 0)
        @assert a > h
        reward = b * (h + 1)
        if s + h + 1 < no_of_blocks
            # honest
            new_states[1] = ((1, a - h - 1, s + h + 1, d, w + 1, relevant), p, reward, stales, epoch)
            # attack
            new_states[2] = ((0, a - h, s + h + 1, d, w + 1, irrelevant), q, reward, stales, epoch)
            # No block
            new_states[3] = ((0, a - h - 1, s + h + 1, d, w + 1, fork), 1 - p - q, reward, stales, epoch)

            # difficulty adjustment
        else
            epoch = true
            s_new = (s + h + 1) % no_of_blocks
            # honest
            new_states[1] = ((1, a - h - 1, s_new, d_adjust(d, w), 0, relevant), p, reward, stales, epoch)
            # attack
            new_states[2] = ((0, a - h, s_new, d_adjust(d, w), 0, irrelevant), q, reward, stales, epoch)
            # No block
            new_states[3] = ((0, a - h - 1, s_new, d_adjust(d, w), 0, fork), 1 - p - q, reward, stales, epoch)
        end

    elseif action == wait
        stales = (0,0)
        new_states[1] = ((h + 1, a, s, d, w + 1, relevant), p, reward, stales, epoch)
        new_states[2] = ((h, a + 1, s, d, w + 1, irrelevant), q, reward, stales, epoch)
        new_states[3] = ((h, a, s, d, w + 1, fork), 1 - p - q, reward, stales, epoch)

    else
        ArgumentError("Not an action")
    end

    return new_states
end # function


