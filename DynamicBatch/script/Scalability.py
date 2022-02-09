import sys
import os
import numpy as np
import time
repeat = 1
if len(sys.argv) > 1:
    repeat = int(sys.argv[1])

path = '/home/wzb/bc/GPU-butterfly/DynamicBatch/'
f = os.popen(f'cd {path} \\ make')
f.readlines()
# f = os.popen('make')
# f.readlines()
dataPath = '/home/wzb/bc/dataset/'
# print(os.listdir(dataPath))
folds = os.listdir(dataPath)
print(folds)
folds = ['trackers']
processorNums = [1, 2, 4, 8, 16, 32, 56, 112]
for fold in folds:
    filePath = os.path.join(dataPath, fold)
    if os.path.isdir(filePath):
        script = path+'butterfly.bin '+filePath + \
            '/ Partition 100 edge-centric 1073741824 112 '
        for batchSize in range(1, 10):
            thisScript = script+str(int(batchSize))
            # print(thisScript)
            f = os.popen(thisScript)
            res = f.readlines()
            print(res)
