import os
import numpy as np
import time
repeat=1
import sys
if len(sys.argv)>1:
    repeat=int(sys.argv[1])

path='/root/GPU-butterfly/GPU-code/'
f=os.popen('sh '+path+'run.sh')
f.readlines()
dataPath='/root/dataset/bipartite/'
# print(os.listdir(dataPath))
folds=os.listdir(dataPath) 
for fold in folds:
    filePath=os.path.join(dataPath,fold)
    if os.path.isdir(filePath):
        script=path+'butterfly.bin '+filePath+'/ 0'
        # print(script)
        f=os.popen(script)
        print(f.readlines())
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