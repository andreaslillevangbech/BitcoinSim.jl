# Due to fork length, when a or h become equal
# to fork length the action has to be adopt or override
# In case override is feasible, obviously this is chosen

# State is (h,a,s,d,w, fork)
# w = 0 means there was an update

function honest_policy(state)::Action
    h, a, _, _, _, _ = state
    if h > a
        return adopt
    elseif a > h
        return override
    end
    return wait
end

# Selfish mining
function sm1(state)::Action
    h, a, _, _, _, fork = state
    if h > a
        return adopt
    elseif a == h == 1 && fork == relevant
        return match
    elseif h == a - 1 && a > 1
        return override
    end
    return wait
end

# Intermittent Selfish mining
mutable struct ISM
    attack::Bool
end
function (p::ISM)(state)::Action
    if state[5] == 0  # If there was an update
        p.attack = !p.attack
    end
    if p.attack
        return sm1(state)
    else
        return honest_policy(state)
    end
end

# Opportunistic selfish mining
# If difficulty is below a certain threshold
struct OSM end
function (p::OSM)(state)::Action
    h, a, s, d, w, fork = state
    if d < dmean * (3 / 4)
        return honest_policy(state)
    else
        return sm1(state)
    end
end

function policy_is_honest() end
