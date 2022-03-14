import numpy as np

base_sizes = [3,4,5]
state_space_dim = len(base_sizes)

def state_to_index(state):
   index = 0
   for i in reversed(range(state_space_dim)):
       index += state[i]

       if i > 0:
           index *= base_sizes[i - 1]

   return index + 1

def index_to_state(index):
    index = index - 1
    state = []
    for i in range(state_space_dim):
        state.append(int(index % base_sizes[i]))
        index /= base_sizes[i]

    return state

state = [i-1 for i in base_sizes]
print("size is ", np.prod(base_sizes))
print(state_to_index(state))
print(index_to_state(60))
