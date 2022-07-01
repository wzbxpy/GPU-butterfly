import sys
import os
import numpy as np
import time
from util import average_of_several_run

repeat = 5
if len(sys.argv) > 1:
    repeat = int(sys.argv[1])

dataPath = '/data/dataset/dataset/kron14-8'
folds = os.listdir(dataPath)
print(folds)

for fold in folds:
    filePath = os.path.join(dataPath, fold)
    if os.path.isdir(filePath):
        vertexfile = os.path.join(filePath, 'begin.bin')
        edgefile = os.path.join(filePath, 'adj.bin')
        size = os.path.getsize(vertexfile)+os.path.getsize(edgefile)
        print(fold, size)
        # run
        script1 = '/home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin ' + \
            filePath+'/ CPU 100 wedge-centric ' + str(int(size/2))+' 56'
        print(average_of_several_run(script1, 1))
        print(script1)
        script2 = '/home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin ' + \
            filePath+'/ CPU 100 edge-centric ' + str(int(size/2))+' 56'
        print(average_of_several_run(script2, 1))
        print(script2)
