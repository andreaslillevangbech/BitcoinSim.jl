Monte Carlo sim to test policy.

- Need to define policies
  - SM
  - Honest
  - Intermittent SM
- Transisiton without storing trans matrix
- Rewards
- 


Calculate size of state
h, a ∈ [0,max_fork]
s ∈ [0, 2015]
d ∈ [300 * hashrate/C, 2 * 600*hashrate/C] Maybe set max to 2 times max(expected)
w ∈ [0, dmax * 600 * no_of_blocks / 4]
d adjustment cannot be more than 4 of less than 1/4
Just set the hashrate very small, that downscales the problem
NOTE: potential bug in w
Dmax = 600*h/C
time = DmaxC/h
time = (600*h/C) * C / h = 600

NOTE: If there is an active fork and no one finds a block then the network is still forked. The action taken in the next period can be override if a>h (note a>=h since attacker matched). Adopt does not make sense and match cannot be performed again. If override then network is reset and and fork is irrelevant. If wait, then logic is like first match



Problems:

When there is an update, there might be new blocks added already and then the counter should not start at zero. This creates a bias in the update

When there is an update, the secret blocks remaining might not satisfy the difficulty requirement





Package structure:
add depends

