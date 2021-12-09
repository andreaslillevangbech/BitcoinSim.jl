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
const shares       = (0.10, 0.50)
const gammas       = (0.20, 0.8)
const d_grid_size  = 1
const Δt           = 1                    # Seconds
const b            = 1                    # Change to 6.25
const β            = 1                    # 0.99999                        # in ]0, 1]
const max_fork     = 100

# Simulation size
const epochs       = 2      # Expected number of difficulty updates (epoch is 2016 settled block)
const N            = epochs * target_time * no_of_blocks          # Periods of Δt to run a sim
const S            = 2                   # Number of sims in Monte Carlo

include("simulation.jl")
include("policies.jl")
include("utils.jl")

struct Params
    share::Float64
    γ::Float64
    N::Int
end

# A state is a tuple of (honest, attack, settled, difficulty, time, fork)
Random.seed!(666)
const init_state = (0, 0, 0, dmean, 0, irrelevant)
const now = Dates.format(Dates.now(), "yyyy-mm-ddTHH:MM")

function main()
    # out = []
    run = 1
    total = length(gammas) * length(shares)
    for γ in gammas
        for share in shares

            params = Params(share, γ, N) # Define parameters for this simulation

            honest = Array{Float64}(undef, S, N)
            stales_honest = Array{Tuple{Int, Int}}(undef, S, N)
            epochs_honest = Array{Int}(undef, S, N)
            selfish = Array{Float64}(undef, S, N)
            stales_selfish = Array{Tuple{Int, Int}}(undef, S, N)
            epochs_selfish = Array{Int}(undef, S, N)
            opportunistic = Array{Float64}(undef, S, N)
            stales_oppor = Array{Tuple{Int, Int}}(undef, S, N)
            epochs_oppor = Array{Int}(undef, S, N)

            for sim = 1:S
                osm = OSM() # Start of by attacking

                sims = rand(N)   # Generate the same random number for every policy sim
                honest[sim,:], stales_honest[sim,:], epochs_honest[sim,:] = simulation(honest_policy, init_state, sims, params)
                selfish[sim,:], stales_selfish[sim,:], epochs_selfish[sim,:] = simulation(sm1, init_state, sims, params)
                opportunistic[sim,:], stales_oppor[sim,:], epochs_oppor[sim,:] = simulation(osm, init_state, sims, params)
            end

            # honest_out  = sum(honest) / S, std(honest) /sqrt(S)
            # selfish_out  = sum(selfish) / S, std(selfish) /sqrt(S)
            # oppor_out  = sum(opportunistic) / S,  std(opportunistic) /sqrt(S)
            # @printf("Honest mining: %.2f, %.2f \n\n" , honest_out[1], honest[2])
            # @printf("Selfish mining: %.2f, %.2f \n\n" , selfish_out[1], selfish_out[2])
            # @printf("Opportunistic mining: %.2f, %.2f \n\n" , oppor_out[1], oppor_out[2])


            pols = Dict([(:honest, (honest, stales_honest, epochs_honest)), 
                         (:selfish, (selfish, stales_selfish, epochs_selfish)), 
                         (:oppor, (opportunistic, stales_oppor, epochs_oppor))])
            # for (name, data) in pols
            #     # NOTE: How to you get the mean of the tuple when there are N obs for each sim?
            #     stale_means = map(i -> mean.(zip(data[2][:,i]...)), 1:N)
            #     push!(out, (name, share, N, γ, mean(data[1], dims=1), std(data[1], dims=1), 
            #                 first.(stale_means), last.(stale_means), mean(data[3], dims=1)))
            # end

            # open("sim-D$now.csv", "w") do io
            open("sim-dlm.csv", "w") do io
                write(io, "Policy, share, N, gamma\n")
                write(io, "Mean\nStd\nSh\nSa\nEpochs\n\n")  
                for (name, data) in pols
                    stale_means = map(i -> mean.(zip(data[2][:,i]...)), 1:N)
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


if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
