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
folds = ['twitter', 'filcker', 'livejournal', 'trackers',
         'orkut']
for fold in folds:
    filePath = os.path.join(dataPath, fold)
    if os.path.isdir(filePath):
        script = path+'butterfly.bin '+filePath+'/ CPU 100 edge-centric '
        # print(script)
        for memorySize in np.logspace(25, 35, num=11, base=2):
            thisScript = script+str(int(memorySize))+" 112"
            # print(thisScript)
            f = os.popen(thisScript)
            res = f.readlines()
            print(res)

for fold in folds:
    filePath = os.path.join(dataPath, fold)
    if os.path.isdir(filePath):
        script = path+'butterfly.bin '+filePath+'/ GPU 100 edge-centric '
        # print(script)
        for memorySize in np.logspace(25, 35, num=11, base=2):
            thisScript = script+str(int(memorySize))+" 216"
            # print(thisScript)
            f = os.popen(thisScript)
            res = f.readlines()
            print(res)
