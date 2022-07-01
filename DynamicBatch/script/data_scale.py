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


Paras = [('kron16-8', 4549520.00), ('kron16-64', 30597384.00), ('kron16-512', 221836928.00), ('kron16-4096', 1661255696.00), ('kron16-32768', 11387876216.00),
         ('kron16-8', 4549520.00), ('kron19-8', 37000472.00), ('kron22-8', 298740128.00), ('kron25-8', 2401501104.00), ('kron28-8', 19263646208.00), ]


Paras = [('kron23-8', 598661520), ('kron24-8', 1199175736), ('kron25-8',
                                                             2401501104), ('kron26-8', 4808050544), ('kron27-8', 9624489136), ]

# Paras = [
#     (962448913, ['kron27-8', 'kron26-8', 'kron25-8', 'kron24-8', 'kron23-8', 'kron22-8', 'kron21-8'])]
# Paras = [('kron16-32768', 11387876216.00)]
# Paras = [(1073741824, ['twitter'])]
# processorNums = [56]

# for i in [0.2, 0.5, 2, 40]:
# for i in [2]:
#     # clean_disk()
#     res = []
#     for fold, memorySize in Paras:
#         thisMemorySize = memorySize*i
#         filePath = os.path.join(dataPath, fold)
#         if os.path.isdir(filePath):
#             variant = wedgeOredge(filePath+"/", thisMemorySize)
#             if variant == "error":
#                 print("error")
#             else:
#                 script = path+'butterfly.bin '+filePath + \
#                     '/ CPU 100 '+variant+' '+str(int(thisMemorySize))+' 56'
#                 print(script)
#                 res.append(average_of_several_run(script, repeat)[1])

#                 # f = os.popen(script)
#                 # print(f.readlines())
#     print(res)
Paras = [('kron12-2048', 44189896), ('kron13-4096', 175184216),
         ('kron14-8192', 709371344), ('kron15-16384', 2811030848), ('kron16-32768', 11387876216), ]

# Paras = [('kron12-2048', 44189896), ('kron13-4096', 175184216),
#          ('kron14-8192', 709371344), ('kron15-16384', 2811030848), ]
# (2.1, "edge-centric"),
for i, variant in [(0.2, "wedge-centric"), (0.5, "wedge-centric"),  (40, "edge-centric")]:
    # for i in [2]:
    clean_disk()
    res = []
    for fold, memorySize in Paras:
        thisMemorySize = memorySize*i
        filePath = os.path.join(dataPath, fold)
        if os.path.isdir(filePath):
            script = path+'butterfly.bin '+filePath + \
                '/ CPU 100 '+variant+' '+str(int(thisMemorySize))+' 56'
            # print(script)
            res.append(average_of_several_run(script, repeat)[1])

            # f = os.popen(script)
            # print(f.readlines())
    print(res)


# Paras = [(1073741824, 'kron18-8192')]
# # # Paras = [(1073741824, 'kron16-8')]
# for variant in ['edge-centric', 'wedge-centric']:
#     res = []

#     for i in [4, 2, 1, 0.5, 0.25]:
#         # clean_disk()
#         for memorySize, fold in Paras:
#             thisMemorySize = memorySize*i
#             filePath = os.path.join(dataPath, fold)
#             if os.path.isdir(filePath):
#                 script = path+'butterfly.bin '+filePath + \
#                     '/ CPU 100 '+variant+' '+str(int(thisMemorySize))+' 56'
#                 print(script)
#                 # res.append(average_of_several_run(script, repeat)[1])
#     print(res)
# Paras = [(1138787621, ['kron16-8', 'kron16-32', 'kron16-128', 'kron16-512', 'kron16-2048', 'kron16-8192', 'kron16-32768']),
#          (962448913, ['kron27-8', 'kron26-8', 'kron25-8', 'kron24-8', 'kron23-8', 'kron22-8', 'kron21-8'])]
# # processorNums = [108]
# for memorySize, folds in Paras:
#     for fold in folds:
#         print(fold)
#         clean_disk()
#         filePath = os.path.join(dataPath, fold)
#         if os.path.isdir(filePath):
#             script = path+'butterfly.bin '+filePath + \
#                 '/ GPU 100 '+variant+' '+str(int(memorySize))+' 108'
#             average_of_several_run(script, repeat)
# Paras = ["kron16-32768", "kron17-16384",
#          "kron18-8192", "kron19-4096", "kron20-2048"]
# for variant in ['edge-centric', 'wedge-centric']:
#     res = []
#     for fold in Paras:
#         thisMemorySize = 1073741824
#         filePath = os.path.join(dataPath, fold)
#         if os.path.isdir(filePath):
#             script = path+'butterfly.bin '+filePath + \
#                 '/ IO 100 '+variant+' '+str(int(thisMemorySize))+' 56'
#             res.append(average_of_several_run(script, repeat)[1])
#     print(res)
