import sys
import os
import numpy as np
import time
from util import average_of_several_run, clean_disk

repeat = 5
if len(sys.argv) > 1:
    repeat = int(sys.argv[1])

path = '/home/wzb/bc/GPU-butterfly/DynamicBatch/'
f = os.popen(path+"run.sh")
print(f.readlines())
# f = os.popen('make')
# f.readlines()
dataPath = '/home/wzb/bc/dataset/'
# print(os.listdir(dataPath))
folds = os.listdir(dataPath)
print(folds)
folds = ['twitter', 'filcker', 'livejournal', 'delicious', 'trackers',
         'orkut', 'bi-twitter', 'bi-sk', 'bi-uk']
# folds = ['trackers']
Paras = [(1073741824, ['twitter', 'filcker', 'livejournal', 'orkut']),
         (1073741824*4, ['delicious', 'trackers', 'bi-twitter', 'bi-sk', 'bi-uk'])]

# Paras = [(1073741824, ['twitter'])]
processorNums = [1, 2, 4, 8, 16, 32, 56, 112]
# processorNums = [56]


for memorySize, folds in Paras:
    for fold in folds:
        print(fold)
        print()
        clean_disk()
        filePath = os.path.join(dataPath, fold)
        if os.path.isdir(filePath):
            script = path+'butterfly.bin '+filePath + \
                '/ CPU 100 edge-centric '+str(int(memorySize))+' '
            for processorNum in processorNums:
                thisScript = script+str(int(processorNum))
                average_of_several_run(thisScript, repeat)


processorNums = [1, 2, 4, 8, 16, 32, 64, 108, 216]
# processorNums = [108]
for memorySize, folds in Paras:
    for fold in folds:
        print(fold)
        print()
        clean_disk()
        filePath = os.path.join(dataPath, fold)
        if os.path.isdir(filePath):
            script = path+'butterfly.bin '+filePath + \
                '/ GPU 100 edge-centric '+str(int(memorySize))+' '
            for processorNum in processorNums:
                thisScript = script+str(int(processorNum))
                average_of_several_run(thisScript, repeat)
