A Bitcoin simulator for mining attacks. Inspired by the paper "Majority is not Enough: Bitcoin Mining is Vulnerable" (Eyal and Sirer 2013). You can devise you own policy in Policies.jl. Then add the policy to the loop in MonteCarlo.jl. Currently implemented policies are Selfish mining, Intermittent Selfish mining, Opportunistic selfish mining and Honest mining.

Easiest way to run is through the Julia REPL
```
pkg> activate .
julia> using BitcoinSim
julia> BitcoinSim.MonteCarlo.main()
```
