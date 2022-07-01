import sys
import os
import numpy as np
import time
from util import average_of_several_run, clean_disk, wedgeOredge
np.set_printoptions(threshold=np.inf, linewidth=np.inf, suppress=False)
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
memorySizes = 1073741824*3
folds = ['twitter', 'filcker', 'livejournal', 'trackers',
         'orkut', 'bi-twitter', 'bi-sk', 'bi-uk']
Paras = [('livejournal', 983981296), ('MANN-a81', 44077616),
         ('twitter', 20770352),  ('filcker', 72359344)]

Paras = [('MANN-a81', 44077616)]
Paras = [('twitter', 20770352), ('MANN-a81', 44077616), ('filcker', 72359344), ('livejournal', 983981296), ('delicious', 1091282080),
         ('trackers', 1448285896), ('orkut', 2708412328), ('bi-twitter', 5147097304), ('bi-sk', 7692486280), ('bi-uk', 11242987032)]
for i, (fold, memorySize) in enumerate(Paras):
    Paras[i] = (fold, memorySize*0.1)
# Paras = [(1073741824, ['twitter'])]
# Paras = [(1073741824*4, ['bi-uk'])]
# Paras = [(1073741824, ['twitter'])]
# folds = ['livejournal']
# folds = ['twitter']
# for fold, memorySize in Paras:
#     print(fold)
#     clean_disk()
#     filePath = os.path.join(dataPath, fold)
#     res = []
#     if os.path.isdir(filePath):
#         script = path+'butterfly.bin '+filePath + '/ CPU 100 '
#         for i in range(1, 6):
#             thisMemorySize = memorySize*i
#             variant = wedgeOredge(filePath+"/", thisMemorySize)
#             thisScript = script+variant+' '+str(int(thisMemorySize))+' 56 '
#             average_of_several_run(thisScript, repeat)

# for fold, memorySize in Paras:
#     print(fold)
#     clean_disk()
#     filePath = os.path.join(dataPath, fold)
#     res = []
#     if os.path.isdir(filePath):
#         script = path+'butterfly.bin '+filePath + '/ GPU 100 '
#         for i in range(1, 6):
#             thisMemorySize = memorySize*i
#             variant = wedgeOredge(filePath+"/", thisMemorySize)
#             thisScript = script+variant+' '+str(int(thisMemorySize))+' 108 '
#             average_of_several_run(thisScript, repeat)

for fold, memorySize in Paras:
    print(fold)
    # clean_disk()
    filePath = os.path.join(dataPath, fold)
    res = []
    if os.path.isdir(filePath):
        script = path+'butterfly.bin '+filePath + '/ IO 100 '
        for i in range(1, 6):
            thisMemorySize = memorySize*i
            variant = wedgeOredge(filePath+"/", thisMemorySize)
            variant = "wedge-centric"
            thisScript = script+variant+' '+str(int(thisMemorySize))+' 1 1'
            # print(thisScript)
            res.append(average_of_several_run(thisScript, repeat)[1])
        print("final", res)
