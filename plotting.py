import matplotlib.pyplot as plt
import numpy as np

# Some examples of how to plot the simulation results

# Composite plot
combs = ["0.4-0.5", "0.1-0.8", "0.3-0.8", "0.33-0.5", "0.35-0.9", "0.1-0.9"]
fig, axs = plt.subplots(3,2, figsize=(14, 17))
for i, (c, ax) in enumerate(zip(combs, axs.flat)):
    self = np.loadtxt("sim-results/selfish-{}.out".format(c))
    hon = np.loadtxt("sim-results/honest-{}.out".format(c))
    share, gamma = c.split("-")
    expected = np.cumsum(np.full(4*blocks, float(share) ))
    time = 4*blocks
    x = np.arange(time)
    y = self[0][:time] - expected
    z = hon[0][:time] - expected
    ax.plot(x, y, linewidth=2.0, label="selfish")
    ax.plot(x, z, linewidth=2.0, label="honest")
    ax.set(xlabel='T', ylabel='Revenue (block reward=1)')
    ax.set_title(f"$\\alpha={share}$, $\\gamma={gamma}$")
    ax.legend()
plt.show()
fig.savefig("plots/selfish", dpi=400)


# Each data point here is 10 minutes apart
# Four blocks is about 8 weeks
self = np.loadtxt("sim-results/selfish-0.1-0.8.out")
hon = np.loadtxt("sim-results/honest-0.1-0.8.out")
expected = np.cumsum(np.full(4*blocks, 0.1))
x = np.arange(4*blocks)
y = self[0][:4*blocks] - expected
z = hon[0][:4*blocks] - expected

fig, ax = plt.subplots()
ax.plot(x, y, linewidth=2.0, label="selfish")
ax.plot(x, z, linewidth=2.0, label="honest")
plt.title("Difference from expected revenue. share=0.1, gamma=0.8")
plt.xlabel('T')
plt.ylabel('Revenue (block reward=1)')
plt.legend()
plt.show()
fig.savefig('plots/self0108.png')

# Each data point here is 10 minutes apart
# Four blocks is about 8 weeks
time = 10*blocks
inter = np.loadtxt("sim-results/inter-0.33-0.5.out")
hon = np.loadtxt("sim-results/honest-0.33-0.5.out")
expected = np.cumsum(np.full(time, 0.33))
x = np.arange(time)
y = inter[0][:time] - expected
z = hon[0][:time] - expected

# fig, ax = plt.subplots()
plt.plot(x, y, linewidth=2.0, label="intermittent")
plt.plot(x, z, linewidth=2.0, label="honest")
plt.title("Difference from expected revenue. share=0.33, gamma=0.5")
plt.xlabel('T')
plt.ylabel('Revenue (block reward=1)')
plt.legend()
plt.show()
fig.savefig('plots/self03305.png')


combs = ["inter-0.1-0.9", "inter-0.33-0.5", "random-0.4-0.9", "random-0.4-0.5"]
time = 20*blocks
fig, axs = plt.subplots(2,2, figsize=(14, 8))
for i, (c, ax) in enumerate(zip(combs, axs.flat)):
    pol, share, gamma = c.split("-")
    wat = np.loadtxt(f"sim-results/{pol}-{share}-{gamma}.out")
    hon = np.loadtxt(f"sim-results/honest-{share}-{gamma}.out")
    expected = np.cumsum(np.full(time, float(share) ))
    x = np.arange(time)
    y = wat[0][:time] - expected
    z = hon[0][:time] - expected
    if i < 2:
        ax.plot(x, y, linewidth=2.0, label="intermittent")
    else:
        ax.plot(x, y, linewidth=2.0, label="randomP")
    ax.plot(x, z, linewidth=2.0, label="honest")
    ax.set(xlabel='T', ylabel='Revenue (block reward=1)')
    ax.set_title(f"$\\alpha={share}$, $\\gamma={gamma}$")
    ax.legend()
plt.show()
fig.savefig("alt.png", dpi=400)
