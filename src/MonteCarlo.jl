module MonteCarlo

using Printf
using Logging
import Random
using Statistics
using DataFrames
import Dates
using DelimitedFiles

# Hyperparamters
const no_of_blocks = 2016                 # 2016 in protocol
const target_time   = 600                  # Expected seconds b/w blocks in protocol
const shares       = (0.10, 0.20, 0.33, 0.40)
const gammas       = (0.2, 0.5, 0.9)
const d_grid_size  = 1
const Δt           = 1                    # Seconds
const b            = 1                    # Change to 6.25
const β            = 1                    # 0.99999                        # in ]0, 1]
const max_fork     = 100

# Simulation size
const epochs       = 20      # Expected number of difficulty updates (epoch is 2016 settled block)
const N            = epochs * target_time * no_of_blocks          # Periods of Δt to run a sim
const S            = 20                   # Number of sims in Monte Carlo

include("Simulation.jl")
include("Policies.jl")
include("Types.jl")
include("Utils.jl")

struct Params
    share::Float64
    γ::Float64
    N::Int
end

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

            # honest = Array{Float64}(undef, S, n)
            # stales_honest = Array{Tuple{Int, Int}}(undef, S, n)
            # epochs_honest = Array{Int}(undef, S, n)
            # selfish = Array{Float64}(undef, S, n)
            # stales_selfish = Array{Tuple{Int, Int}}(undef, S, n)
            # epochs_selfish = Array{Int}(undef, S, n)
            random = Array{Float64}(undef, S, n)
            stales_random = Array{Tuple{Int, Int}}(undef, S, n)
            epochs_random = Array{Int}(undef, S, n)

            # inter = Array{Float64}(undef, S, n)
            # stales_inter = Array{Tuple{Int, Int}}(undef, S, n)
            # epochs_inter = Array{Int}(undef, S, n)
            
            for sim = 1:S
                randp = RandomP(0.003) # random policy parameter of when to override
                # ism = ISM(true) # start off by attacking

                sims = rand(N)   # Generate the same random number for every policy sim
                # honest[sim,:], stales_honest[sim,:], epochs_honest[sim,:] = simulation(honest_policy, init_state, sims, params)
                # selfish[sim,:], stales_selfish[sim,:], epochs_selfish[sim,:] = simulation(sm1, init_state, sims, params)
                random[sim,:], stales_random[sim,:], epochs_random[sim,:] = simulation(randp, init_state, sims, params)
                # inter[sim,:], stales_inter[sim,:], epochs_inter[sim,:] = simulation(ism, init_state, sims, params)
            end

            # honest_out  = sum(honest) / S, std(honest) /sqrt(S)
            # selfish_out  = sum(selfish) / S, std(selfish) /sqrt(S)
            # random_out  = sum(random) / S,  std(random) /sqrt(S)
            # @printf("Honest mining: %.2f, %.2f \n\n" , honest_out[1], honest[2])
            # @printf("Selfish mining: %.2f, %.2f \n\n" , selfish_out[1], selfish_out[2])
            # @printf("Opportunistic mining: %.2f, %.2f \n\n" , random_out[1], random_out[2])


            # pols = Dict([(:honest, (honest, stales_honest, epochs_honest)), 
            #              (:selfish, (selfish, stales_selfish, epochs_selfish)), 
            #              (:random, (random, stales_random, epochs_random))])
            pols = Dict([(:random, (random, stales_random, epochs_random))]) 
            # for (name, data) in pols
            #     # NOTE: How to you get the mean of the tuple when there are N obs for each sim?
            #     stale_means = map(i -> mean.(zip(data[2][:,i]...)), 1:N)
            #     push!(out, (name, share, N, γ, mean(data[1], dims=1), std(data[1], dims=1), 
            #                 first.(stale_means), last.(stale_means), mean(data[3], dims=1)))
            # end

            # open("sim-D$now.csv", "w") do io
            open("sim-results.txt", "a") do io
                # write(io, "Policy, share, N, gamma\n")
                # write(io, "Mean\nStd\nSh\nSa\nEpochs\n\n")  
                for (name, data) in pols
                    stale_means = map(i -> mean.(zip(data[2][:,i]...)), 1:n)
                    write(io, "$name, $share, $N, $γ\n")
                    writedlm(io, [mean(data[1], dims=1), std(data[1], dims=1), 
                                  first.(stale_means), last.(stale_means), mean(data[3], dims=1)])
                    write(io, "\n")
                end
            end

            # Just some feedback
            @info "Sim: $run / $total"
            run += 1

        end # loop over shares
    end # loop over gammas

    # Save the data
    # table = DataFrame(out)
    # rename!(table, [:policy, :share, :N, :gamma, :mean, :std, :Sh, :Sa, :epochs])


    # for row in eachrow(table)
    #     println(row)
    # end

end    # main

end # module

# if abspath(PROGRAM_FILE) == @__FILE__
#     main()
# end

