module MonteCarlo

using Printf
using Logging
import Random
using Statistics
using DataFrames
import Dates
using DelimitedFiles

include("Simulation.jl")
include("Policies.jl")
include("Types.jl")
include("Utils.jl")

# Hyperparameters
const no_of_blocks = 2016                 # 2016 in protocol
const target_time   = 600                  # Expected seconds b/w blocks in protocol
const shares       = (0.10, 0.20, 0.3, 0.33, 0.35, 0.40)
const gammas       = (0.2, 0.5, 0.8, 0.9)
const d_grid_size  = 1
const Δt           = 1                    # Seconds
const b            = 1                    # Change to 6.25
const β            = 1                    # 0.99999                        # in ]0, 1]
const max_fork     = 100

# Constants
const hashrate = 100 * 10^7  #Ghashes per second - exogenous total hashrate of network
const C = 2^48 ÷ 0xffff # 2^256 / (0xffff * 2^208)
# const C      = 2^32 # approximation
const dmean = target_time * hashrate / C    # estimate of upper bound on d
const dmax = 2 * dmean
const dmin = dmax / 4  # estimate of lower bound on d

# Simulation size
const epochs       = 20      # Expected number of difficulty updates (epoch is 2016 settled block)
const N            = epochs * target_time * no_of_blocks          # Periods of Δt to run a sim
const S            = 10                   # Number of sims in Monte Carlo

struct Params
    share::Float64
    γ::Float64
    N::Int
end

# struct Result 
#     values::Array{Float64}(undef, S, n)
#     stales::
#     epochs::

# A state is a tuple of (honest, attack, settled, difficulty, time, fork)
Random.seed!(666)
const init_state = (0, 0, 0, dmean, 0, irrelevant)
const n = N ÷ target_time
const now = Dates.format(Dates.now(), "yyyy-mm-ddTHH:MM")

function main()
    # out = []
    run = 1
    total = length(gammas) * length(shares)
    for γ in gammas
        for share in shares

            params = Params(share, γ, N) # Define parameters for this simulation

            honest = Array{Float64}(undef, n, S)
            stales_honest = Array{Tuple{Int, Int}}(undef, n, S)
            epochs_honest = Array{Int}(undef, n, S)
            selfish = Array{Float64}(undef, n, S)
            stales_selfish = Array{Tuple{Int, Int}}(undef, n, S)
            epochs_selfish = Array{Int}(undef, n, S)
            # random = Array{Float64}(undef, S, n)
            # stales_random = Array{Tuple{Int, Int}}(undef, S, n)
            # epochs_random = Array{Int}(undef, S, n)

            # inter = Array{Float64}(undef, S, n)
            # stales_inter = Array{Tuple{Int, Int}}(undef, S, n)
            # epochs_inter = Array{Int}(undef, S, n)
            
            for sim = 1:S
                # randp = RandomP(0.003) # random policy parameter of when to override
                # ism = ISM(true) # start off by attacking

                sims = rand(N)   # Generate the same random number for every policy sim
                # NOTE: it might be better to insert as columns as julia is columns contigious 
                honest[:,sim], stales_honest[:,sim], epochs_honest[:,sim] = simulation(honest_policy, sims, params)
                selfish[:,sim], stales_selfish[:,sim], epochs_selfish[:,sim] = simulation(sm1, sims, params)
                # random[sim,:], stales_random[sim,:], epochs_random[sim,:] = simulation(randp, sims, params)
                # inter[sim,:], stales_inter[sim,:], epochs_inter[sim,:] = simulation(ism, init_state, sims, params)
            end

            # honest_out  = sum(honest) / S, std(honest) /sqrt(S)
            # selfish_out  = sum(selfish) / S, std(selfish) /sqrt(S)
            # random_out  = sum(random) / S,  std(random) /sqrt(S)
            # @printf("Honest mining: %.2f, %.2f \n\n" , honest_out[1], honest[2])
            # @printf("Selfish mining: %.2f, %.2f \n\n" , selfish_out[1], selfish_out[2])
            # @printf("Opportunistic mining: %.2f, %.2f \n\n" , random_out[1], random_out[2])


            pols = Dict([(:honest, (honest, stales_honest, epochs_honest)), 
                         (:selfish, (selfish, stales_selfish, epochs_selfish))])
            # pols = Dict([(:honest, (honest, stales_honest, epochs_honest)), 
            #              (:selfish, (selfish, stales_selfish, epochs_selfish)), 
            #              (:random, (random, stales_random, epochs_random))])
            # pols = Dict([(:random, (random, stales_random, epochs_random))]) 
            # for (name, data) in pols
            #     # NOTE: How to you get the mean of the tuple when there are N obs for each sim?
            #     stale_means = map(i -> mean.(zip(data[2][:,i]...)), 1:N)
            #     push!(out, (name, share, N, γ, mean(data[1], dims=1), std(data[1], dims=1), 
            #                 first.(stale_means), last.(stale_means), mean(data[3], dims=1)))
            # end

            # open("sim-D$now.csv", "w") do io
            # open("sim-results.txt", "a") do io
            #     # write(io, "Policy, share, N, gamma\n")
            #     # write(io, "Mean\nStd\nSh\nSa\nEpochs\n\n")  
            #     for (name, data) in pols
            #         stale_means = map(i -> mean.(zip(data[2][:,i]...)), 1:n)
            #         write(io, "$name, $share, $N, $γ\n")
            #         writedlm(io, [mean(data[1], dims=1), std(data[1], dims=1), 
            #                       first.(stale_means), last.(stale_means), mean(data[3], dims=1)])
            #         write(io, "\n")
            #     end
            # end
            for (name, data) in pols
                open("sim-results/$name-$share-$γ.out", "w") do io
                    stale_means = map(i -> mean.(zip(data[2][i,:]...)), 1:n)
                    write(io, "mean std Sh Sa epochs\n")
                    writedlm(io, hcat(mean(data[1], dims=2), std(data[1], dims=2), 
                        first.(stale_means), last.(stale_means), mean(data[3], dims=2)))
                end
            end

            # Just some feedback
            @info "Sim: $run / $total"
            run += 1

        end # loop over shares
    end # loop over gammas

end    # main

end # module
