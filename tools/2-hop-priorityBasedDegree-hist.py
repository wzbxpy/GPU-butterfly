import os
import sys
import string
import struct
import numpy as np
from matplotlib import pyplot as plt 
import matplotlib
from matplotlib import rcParams
rcParams['font.family'] = 'serif'
rcParams['font.serif'] = ['Times New Roman'] + rcParams['font.serif']
rcParams['font.size'] = 13.5

path='/root/hypergraph/dataset/twitter'
if (len(sys.argv)>1):
    path=str(sys.argv[1])
print(path)
file=open(path+'/properties.txt','r')
s=file.read()
print(s)
s=s.strip('\n')
s=s.split(' ')
print(s)
uCount=int(s[0])
vCount=int(s[1])
edgeCount=int(s[2])
print(uCount,vCount,edgeCount)
file.close()
file=open(path+'/begin.bin','rb')
a=file.read((uCount+vCount+1)*8)
cou=uCount+vCount+1
a=struct.unpack('{}q'.format(cou),a)
b=np.zeros(cou-1)
for i in range(uCount+vCount):
    b[i]=a[i+1]-a[i]

h=int(max(b))

file=open(path+'/adj.bin','rb')
c=file.read((edgeCount)*8)
c=struct.unpack('{}i'.format(edgeCount*2),c)
d=np.zeros(cou-1)
for i in range(uCount+vCount):
    for j in range(a[i],a[i+1]):
        if b[c[j]]<b[i]:
            d[i]=d[i]+b[c[j]]


h=int(max(d))
hist,bin=np.histogram(d,bins=h)
print(h)
plt.plot(hist)
plt.yscale('log')
plt.xscale('log')
plt.ylabel('number of vertex')
plt.xlabel('number of wedges satisfied priority')
plt.savefig('/root/hypergraph/figure/2-hop-priorityBasedDegree.pdf')