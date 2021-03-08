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

print(matplotlib.get_cachedir())
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
hist,bin=np.histogram(b,bins=h)
print(h)
plt.plot(hist)
# plt.title('hist')
plt.yscale('log')
plt.xscale('log')

plt.ylabel('number of vertex')
plt.xlabel('degree')
# plt.tick_params(labelsize=40)
# labels = plt.get_xticklabels() + plt.get_yticklabels()
# [label.set_fontname('Times New Roman') for label in labels]

plt.savefig('/root/hypergraph/figure/1-hop-degree.pdf')