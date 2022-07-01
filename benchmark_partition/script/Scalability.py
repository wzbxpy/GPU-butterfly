import sys
import os
import numpy as np
import time
from util import average_of_several_run

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
folds = ['twitter', 'MANN-a81', 'filcker', 'livejournal', 'delicious', 'trackers',
         'orkut', 'bi-twitter', 'bi-sk', 'bi-uk']
# folds = ['filcker']
# processorNums = [1, 2, 4, 8, 16, 32, 56, 112]
processorNums = [56]

for fold in folds:
    filePath = os.path.join(dataPath, fold)
    if os.path.isdir(filePath):
        script = path+'butterfly.bin '+filePath + \
            '/ CPU 100 edge-centric 507374182400 '
        print(fold)
        for processorNum in processorNums:
            thisScript = script+str(int(processorNum))
            average_of_several_run(thisScript, repeat)
            f = os.popen(f'mv {filePath}/partition1src0/* {filePath}/')
            f.readlines()


# processorNums = [1, 2, 4, 8, 16, 32, 64, 108, 216]
# # processorNums = [108, 216]

# for fold in folds:
#     filePath = os.path.join(dataPath, fold)
#     if os.path.isdir(filePath):
#         print(fold)
#         script = path+'butterfly.bin '+filePath + \
#             '/ GPU 100 edge-centric 40737418240 '
#         for processorNum in processorNums:
#             thisScript = script+str(int(processorNum))
#             average_of_several_run(thisScript, repeat)
