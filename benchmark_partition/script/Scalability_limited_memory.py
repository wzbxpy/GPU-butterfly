import sys
import os
import numpy as np
import time
from util import average_of_several_run, clean_disk, wedgeOredge

repeat = 1
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
Paras = [('twitter', 20770352), ('MANN-a81', 44077616), ('filcker', 72359344), ('livejournal', 983981296), ('delicious', 1091282080),
         ('trackers', 1448285896), ('orkut', 2708412328), ('bi-twitter', 5147097304), ('bi-sk', 7692486280), ('bi-uk', 11242987032)]

Paras = [('twitter', 20770352), ('MANN-a81', 44077616), ('filcker', 72359344), ('livejournal', 983981296), ('delicious', 1091282080),
         ('trackers', 1448285896)]
Paras = [('twitter', 20770352)]
Paras = [('bi-twitter', 5147097304),
         ('bi-sk', 7692486280), ('bi-uk', 11242987032)]
processorNums = [1, 2, 4, 8, 16, 32, 56]
# processorNums = [56]


for fold, memorySize in Paras:
    print(fold)
    print()
    clean_disk()
    filePath = os.path.join(dataPath, fold)
    for i in [0.2, 0.5, 2, 50]:
        thisMemorySize = memorySize*i
        if os.path.isdir(filePath):
            variant = wedgeOredge(filePath+"/", thisMemorySize)
            # print(variant)
            script = path+'butterfly.bin '+filePath + \
                '/ CPU 100 '+variant+' '+str(int(thisMemorySize))+' '
            res = []
            for processorNum in processorNums:
                thisScript = script+str(int(processorNum))
                res.append(average_of_several_run(thisScript, repeat)[1])
            print('final', res)


# processorNums = [1, 2, 4, 8, 16, 32, 64, 108, 216]
# # processorNums = [108]
# for memorySize, folds in Paras:
#     for fold in folds:
#         print(fold)
#         print()
#         clean_disk()
#         filePath = os.path.join(dataPath, fold)
#         if os.path.isdir(filePath):
#             script = path+'butterfly.bin '+filePath + \
#                 '/ GPU 100 edge-centric '+str(int(memorySize))+' '
#             for processorNum in processorNums:
#                 thisScript = script+str(int(processorNum))
#                 average_of_several_run(thisScript, repeat)
