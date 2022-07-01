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
Paras = [('twitter', 20770352), ('MANN-a81', 44077616), ('filcker', 72359344), ('livejournal', 983981296), ('delicious', 1091282080),
         ('trackers', 1448285896), ('orkut', 2708412328), ('bi-twitter', 5147097304), ('bi-sk', 7692486280), ('bi-uk', 11242987032)]

Paras = [('delicious', 1091282080*0.5)]
# Paras = [('twitter', 20770352*0.2)]
for thread in [4, 56]:
    # navie
    for fold, memorySize in Paras:
        clean_disk()
        filePath = os.path.join(dataPath, fold)
        res = []
        if os.path.isdir(filePath):
            script = path+'butterfly.bin '+filePath + '/ IO 100 '
            variant = wedgeOredge(filePath+"/", memorySize)
            thisScript = script+variant+' ' + \
                str(int(memorySize/thread))+' '+'1'+' '
            f = os.popen(thisScript)
            print(f.readlines())

    # shared noting
    for fold, memorySize in Paras:
        clean_disk()
        filePath = os.path.join(dataPath, fold)
        res = []
        if os.path.isdir(filePath):
            script = path+'butterfly.bin '+filePath + '/ IO 100 '
            variant = wedgeOredge(filePath+"/", memorySize)
            thisScript = script+variant+' ' + \
                str(int(memorySize))+' '+str(thread)+' 1000'
            f = os.popen(thisScript)
            print(f.readlines())
    # shared
    for fold, memorySize in Paras:
        clean_disk()
        filePath = os.path.join(dataPath, fold)
        res = []
        if os.path.isdir(filePath):
            script = path+'butterfly.bin '+filePath + '/ IO 100 '
            variant = wedgeOredge(filePath+"/", memorySize)
            thisScript = script+variant+' ' + \
                str(int(memorySize))+' '+str(thread)+' 1'
            f = os.popen(thisScript)
            print(f.readlines())
    # fine-grand
    for fold, memorySize in Paras:
        clean_disk()
        filePath = os.path.join(dataPath, fold)
        res = []
        if os.path.isdir(filePath):
            script = path+'butterfly.bin '+filePath + '/ IO 100 '
            variant = wedgeOredge(filePath+"/", memorySize)
            thisScript = script+variant+' ' + \
                str(int(memorySize))+' '+str(thread)+' '
            f = os.popen(thisScript)
            print(f.readlines())


# for thread in [4, 56]:
#     # navie
#     for fold, memorySize in Paras:

#         clean_disk()
#         filePath = os.path.join(dataPath, fold)
#         res = []
#         if os.path.isdir(filePath):
#             script = path+'butterfly.bin '+filePath + '/ CPU 100 '
#             variant = wedgeOredge(filePath+"/", memorySize)
#             thisScript = script+variant+' ' + \
#                 str(int(memorySize/thread))+' '+'1'+' '
#             f = os.popen(thisScript)
#             print(f.readlines())

#     # shared noting
#     for fold, memorySize in Paras:

#         clean_disk()
#         filePath = os.path.join(dataPath, fold)
#         res = []
#         if os.path.isdir(filePath):
#             script = path+'butterfly.bin '+filePath + '/ sharedHashtable 100 '
#             variant = wedgeOredge(filePath+"/", memorySize)
#             thisScript = script+variant+' ' + \
#                 str(int(memorySize))+' '+str(thread)+' 1000'
#             f = os.popen(thisScript)
#             print(f.readlines())
#     # shared
#     for fold, memorySize in Paras:

#         clean_disk()
#         filePath = os.path.join(dataPath, fold)
#         res = []
#         if os.path.isdir(filePath):
#             script = path+'butterfly.bin '+filePath + '/ CPU 100 '
#             variant = wedgeOredge(filePath+"/", memorySize)
#             thisScript = script+variant+' ' + \
#                 str(int(memorySize))+' '+str(thread)+' 1'
#             f = os.popen(thisScript)
#             print(f.readlines())
#     # fine-grand
#     for fold, memorySize in Paras:

#         clean_disk()
#         filePath = os.path.join(dataPath, fold)
#         res = []
#         if os.path.isdir(filePath):
#             script = path+'butterfly.bin '+filePath + '/ CPU 100 '
#             variant = wedgeOredge(filePath+"/", memorySize)
#             thisScript = script+variant+' ' + \
#                 str(int(memorySize))+' '+str(thread)+' '
#             f = os.popen(thisScript)
#             print(f.readlines())
