import sys
import os
import numpy as np
import time
repeat = 1
if len(sys.argv) > 1:
    repeat = int(sys.argv[1])


script = '/home/wzb/bc/GPU-butterfly/GPU-code/butterfly.bin /home/lyx/datasets/bipartite/orkut/sorted/ 1'
# print(script)
for i in range(1, 11):
    f = os.popen(f'{script} {i}')
    res = f.readlines()
    print(i, res[-2].strip())
