import sys
import os
import numpy as np
import time
from util import average_of_several_run, clean_disk


repeat = 5
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
folds = ['twitter', 'filcker', 'livejournal', 'delicious', 'trackers',
         'orkut', 'bi-twitter', 'bi-sk', 'bi-uk']
folds = ['bi-uk']
for fold in folds:
    print(fold)
    clean_disk()
    filePath = os.path.join(dataPath, fold)
    if os.path.isdir(filePath):
        script = path+'butterfly.bin '+filePath+'/ CPU 100 edge-centric '
        # print(script)
        for memorySize in np.logspace(28, 38, num=11, base=2):
            thisScript = script+str(int(memorySize))+" 56"
            average_of_several_run(thisScript, repeat)


for fold in folds:
    print(fold)
    clean_disk()
    filePath = os.path.join(dataPath, fold)
    if os.path.isdir(filePath):
        script = path+'butterfly.bin '+filePath+'/ GPU 100 edge-centric '
        # print(script)
        for memorySize in np.logspace(28, 38, num=11, base=2):
            thisScript = script+str(int(memorySize))+" 108"
            average_of_several_run(thisScript, repeat)
