import sys
import os
import numpy as np
import time
repeat = 1
if len(sys.argv) > 1:
    repeat = int(sys.argv[1])

unifiedMemory = True
path = '/home/wzb/bc/GPU-butterfly/DynamicBatch/'
f = os.popen(f'cd {path} \\ make')
f.readlines()
# f = os.popen('make')
# f.readlines()
dataPath = '/home/wzb/bc/dataset/'
# print(os.listdir(dataPath))
folds = os.listdir(dataPath)
print(folds)
memorySize = 1073741824*2
# folds = ['twitter', 'filcker', 'livejournal', 'trackers',
#          'orkut', 'bi-twitter', 'bi-sk', 'bi-uk']
# folds = ['livejournal']
folds = ['orkut']
for fold in folds:
    filePath = os.path.join(dataPath, fold)
    if os.path.isdir(filePath):
        script = path+'butterfly.bin '+filePath + \
            '/ CPU 100 edge-centric '+str(int(memorySize))+' 112 '
        for batchSize in range(1, 10):
            thisScript = script+str(int(batchSize))
            # print(thisScript)
            f = os.popen(thisScript)
            res = f.readlines()
            print(res)

for fold in folds:
    filePath = os.path.join(dataPath, fold)
    if os.path.isdir(filePath):
        script = path+'butterfly.bin '+filePath + \
            '/ GPU 100 edge-centric '+str(int(memorySize))+' 216 '
        for batchSize in range(1, 10):
            thisScript = script+str(int(batchSize))
            # print(thisScript)
            f = os.popen(thisScript)
            res = f.readlines()
            print(res)
