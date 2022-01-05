import sys
import os
import numpy as np
import time
repeat = 1
if len(sys.argv) > 1:
    repeat = int(sys.argv[1])

path = '/home/wzb/bc/GPU-butterfly/FinalVersion/'
f = os.popen(f'cd {path} \\ make')
f.readlines()
# f = os.popen('make')
# f.readlines()
dataPath = '/home/wzb/bc/dataset/'
# print(os.listdir(dataPath))
folds = os.listdir(dataPath)
print(folds)
for fold in folds:
    filePath = os.path.join(dataPath, fold)
    if os.path.isdir(filePath):
        script = path+'butterfly.bin '+filePath+'/ Partition 100 edge-centric '
        # print(script)
        for memorySize in np.logspace(25, 35, num=11, base=2):
            thisScript = script+str(int(memorySize))+" 1"
            # print(thisScript)
            f = os.popen(thisScript)
            res = f.readlines()
            print(res)
            # if int(res[1].split(' ')[1]) > 0:
            #     verterNum = int(res[1].split(' ')[1])+int(res[1].split(' ')[2])
            #     edgeNum = int(res[1].split(' ')[3])
            #     # print(res)
            #     print(fold, verterNum, edgeNum, res[2].split(
            #         " ")[-1].strip(), res[3].split(" ")[-1].strip())
            # time.sleep(10)
            # print(s)
            #             # print(script[i])
            #         time=np.zeros(len(script))
            #         res=""
            #         for j in range(3):
            #             f=os.popen(script[j])
            #             s=f.readlines()
            #             res=res+' '+s[0].strip('\n')
            #         print(data,res)
