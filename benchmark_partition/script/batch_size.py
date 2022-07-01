import sys
import os
import numpy as np
import time
from util import average_of_several_run, clean_disk
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
# Paras = [('twitter', 35895640), ('MANN-a81', 44077616), ('filcker', 140721800), ('livejournal', 1882440376), ('delicious', 1905673736),
#          ('trackers', 2573195992), ('orkut', 5324712224), ('bi-twitter', 9960976800), ('bi-sk', 14979883352), ('bi-uk', 21864045888)]
# Paras = [('twitter', 35895640)]
Paras = [('twitter', 20770352), ('MANN-a81', 44077616), ('filcker', 72359344), ('livejournal', 983981296), ('delicious', 1091282080),
         ('trackers', 1448285896), ('orkut', 2708412328), ('bi-twitter', 5147097304), ('bi-sk', 7692486280), ('bi-uk', 11242987032)]

Paras = [('orkut', 2708412328)]
Paras = [('livejournal', 983981296), ('delicious', 1091282080),
         ('trackers', 1448285896), ('orkut', 2708412328)]
# Paras = [('orkut', 2708412328)]
# for i, (fold, memorySize) in enumerate(Paras):
#     Paras[i] = (fold, memorySize*0.1)
# Paras = [(1073741824, ['twitter'])]
# Paras = [(1073741824*4, ['bi-uk'])]
# Paras = [(1073741824, ['twitter'])]
# folds = ['livejournal']
# folds = ['twitter']
for fold, memorySize in Paras:
    print(fold)
    print()
    clean_disk()
    filePath = os.path.join(dataPath, fold)
    for i in [0.2, 0.5, 2, 40]:
        # for i in [40]:
        res = []
        thisMemorySize = memorySize*i
        if os.path.isdir(filePath):
            script = path+'butterfly.bin '+filePath + \
                '/ CPU 100 edge-centric '+str(int(thisMemorySize))+' 56 '
            # for batchSize in [1, 2, 4, 8, 16, 32, 56]:
            for batchSize in [-1]:
                thisScript = script+str(int(batchSize))
                print(thisScript)
                # res.append(average_of_several_run(thisScript, repeat))
        res = np.array(res)
        # print("final", res.transpose())
        # print(res[np.argmin(res[:, 1]), :])


# for fold, memorySize in Paras:
#     print(fold)
#     print()
#     clean_disk()
#     filePath = os.path.join(dataPath, fold)
#     for i in [0.1, 0.2, 0.5]:
#         res = []
#         thisMemorySize = memorySize*i
#         if os.path.isdir(filePath):
#             script = path+'butterfly.bin '+filePath + \
#                 '/ GPU 100 edge-centric '+str(int(thisMemorySize))+' 108 '
#             for batchSize in range(1, 31):
#                 thisScript = script+str(int(batchSize))
#                 res.append(average_of_several_run(thisScript, repeat))
#         res = np.array(res)
#         print("final", res.transpose())
#         print(res[np.argmin(res[:, 1]), :])
