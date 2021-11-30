using Printf
import Random

# Hyperparamters
const no_of_blocks       = 2016                 # 2016 in protocol
const interblock         = 600                  # Expected seconds b/w blocks in protocol
const share              = 0.40                 # Share of hashrate for the attacker
const γ                  = 0.10                 # Gamma is the network connectivity
const d_grid_size        = 1
const Δt                 = 1                    # Seconds
const b                  = 1                    # Change to 6.25
const β                  = 1                    # 0.99999                        # in ]0, 1]
const max_fork           = 100

include("simulation.jl")
include("policies.jl")
include("utils.jl")

const N                  = 10*600*2016          # Periods of Δt to run a sim
const S                  = 10                   # Number of sims in Monte Carlo
const init_state         = (0, 0, 0, dmax/2, 0)

# Main part
Random.seed!(666)


honest = Array{Float64}(undef, S)
selfish = Array{Float64}(undef, S)
intermittent = Array{Float64}(undef, S)

println("Fair share of blocks in expectation: ")
@show 10*2016*share
println()

for sim in 1:S
  sims = rand(N)
  honest[sim] = simulation(init_state, honest_policy, sims)
  selfish[sim] = simulation(init_state, sm1, sims)
  intermittent[sim] = simulation(init_state, ism, sims)
end

println("Honest mining: ")
@show sum(honest) / S
println()

println("Selfish mining: ")
@show sum(selfish) / S
println()

println("Intermittent selfish mining: ")
@show sum(intermittent) / S
println()

