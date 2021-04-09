import os
import time
repeat=1
import sys
if len(sys.argv)>1:
    repeat=int(sys.argv[1])

path='/root/hypergraph/GPU-butterfly/preprocess/'
f=os.popen('g++ '+path+"TransformEdgelist2CSR.cpp -O3 -o "+path+'tra')
f.readlines()
dataPath='/root/hypergraph/dataset/bipartite/'
# print(os.listdir(dataPath))
filePath=os.path.join(dataPath,'test')
script='mkdir '+filePath+'/sorted/' #creat fold
f=os.popen(script)
f.readlines()
script=path+'tra '+filePath+'/'
print(script)
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