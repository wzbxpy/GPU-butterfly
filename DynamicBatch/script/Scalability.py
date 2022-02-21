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
         'orkut', 'bi-twitter', 'bi-sk', 'bi-uk']
# folds = ['livejournal']
# processorNums = [1, 2, 4, 8, 16, 32, 56, 112]
processorNums = [56, 112]

for fold in folds:
    filePath = os.path.join(dataPath, fold)
    if os.path.isdir(filePath):
        script = path+'butterfly.bin '+filePath + \
            '/ CPU 100 edge-centric 507374182400 '
        print(fold)
        for processorNum in processorNums:
            thisScript = script+str(int(processorNum))
            thisScript = thisScript
            # print(thisScript)

            f = os.popen(thisScript)
            res = f.readlines()
            print(res)

# processorNums = [1, 2, 4, 8, 16, 32, 64, 108, 216]
# for fold in folds:
#     filePath = os.path.join(dataPath, fold)
#     if os.path.isdir(filePath):
#         script = path+'butterfly.bin '+filePath + \
#             '/ GPU 100 edge-centric 40737418240 '
#         for processorNum in processorNums:
#             thisScript = script+str(int(processorNum))
#             thisScript = thisScript
#             # print(thisScript)

#             f = os.popen(thisScript)
#             res = f.readlines()
#             print(res)
