import sys
import os
import numpy as np
import time
from util import average_of_several_run, clean_disk
np.set_printoptions(threshold=np.inf, linewidth=np.inf, suppress=False)
repeat = 5
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
memorySizes = 1073741824*3
folds = ['twitter', 'filcker', 'livejournal', 'trackers',
         'orkut', 'bi-twitter', 'bi-sk', 'bi-uk']
Paras = [(1073741824, ['twitter', 'filcker', 'livejournal', 'orkut']),
         (1073741824*4, ['delicious', 'trackers', 'bi-twitter', 'bi-sk', 'bi-uk'])]
# Paras = [(1073741824, ['twitter'])]
# Paras = [(1073741824*4, ['bi-uk'])]
# Paras = [(1073741824, ['twitter'])]
# folds = ['livejournal']
# folds = ['twitter']
for memorySize, folds in Paras:
    for fold in folds:
        print(fold)
        print()
        clean_disk()
        filePath = os.path.join(dataPath, fold)
        if os.path.isdir(filePath):
            script = path+'butterfly.bin '+filePath + \
                '/ CPU 100 edge-centric '+str(int(memorySize))+' 56 '
            average_of_several_run(script, repeat)
            thisScript = script+str(1)
            average_of_several_run(thisScript, repeat)


for memorySize, folds in Paras:
    for fold in folds:
        print(fold)
        print()
        clean_disk()
        filePath = os.path.join(dataPath, fold)
        if os.path.isdir(filePath):
            script = path+'butterfly.bin '+filePath + \
                '/ GPU 100 edge-centric '+str(int(memorySize))+' 108 '
            average_of_several_run(script, repeat)
            thisScript = script+str(1)
            average_of_several_run(thisScript, repeat)
