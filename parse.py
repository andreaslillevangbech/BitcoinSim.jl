#!/usr/bin/env python3

# A parser for the sim results
import numpy as np
import re

file = open(0)
data_line = False
table = []
for line in file:
    if line == "\n" and data_line:
        data_line = False
        np.savetxt(pol+"-"+share+"-"+gamma+".out", np.array(table))
        table.clear()
    
    if data_line:
        table.append([float(i) for i in line.strip().split()])
    
    meta = re.match(r'(.*), (.*), ([0-9]*), (.*)$', line)
    if meta:
        pol, share, secs, gamma = meta.groups()
        # share, secs, gamma = float(share), int(secs), float(gamma)
        data_line = True
        
