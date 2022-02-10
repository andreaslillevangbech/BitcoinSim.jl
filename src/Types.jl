@enum Action begin
    adopt = 1
    override = 2
    match = 3
    wait = 4
end

# Start it at 0 as all other state vars start at 0
@enum Fork begin
    irrelevant = 0
    relevant = 1
    active = 2
end

# Maybe state should just be a tuple
mutable struct State
    h::Int16  # Length of honest branch
    a::Int16  # Length of attackers branch
    s::Int16  # Settled blocks since fork
    d::Int16  # Current difficulty (discretized)
    w::Int16  # Time steps since adjustment
    fork::Fork # Forked state of network
    State() = new(0, 0, 0, dmax, 0)  # Init
end

# Get admissible action in a state
function actions(state)::Action end
