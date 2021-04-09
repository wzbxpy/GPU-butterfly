import os
import sys
import string
import struct
import numpy as np
from matplotlib import pyplot as plt 
import matplotlib
from matplotlib import rcParams

def loadMyData(path):
    print(path)
    labels=[]
    k=0
    a=np.zeros((7,3))
    file=open(path)
    for line in file.readlines():
        line = line.strip()
        s=line.split(' ')
        labels.append(s[0])
        for i in range(7):
            a[i][k]=s[i+1]
            a[i][k]=format(a[i][k],'.4f')
        k=k+1
    return a,labels

rcParams['font.family'] = 'serif'
rcParams['font.serif'] = ['Times New Roman'] + rcParams['font.serif']
rcParams['font.size'] = 13.5
path='/home/ubuntu/hypergraph/GPU-butterfly/result.txt'

a,labels=loadMyData(path)

def autolabel(rects,ax):
    """Attach a text label above each bar in *rects*, displaying its height."""
    for rect in rects:
        height = rect.get_height()
        ax.annotate('{}'.format(height),
                    xy=(rect.get_x() + rect.get_width() / 2, height),
                    xytext=(0, 3),  # 3 points vertical offset
                    textcoords="offset points",
                    ha='center', va='bottom')

def Hash_vs_Heap():
    x = np.arange(len(labels))  # the label locations
    width = 0.35  # the width of the bars
    fig, ax = plt.subplots()
    rects1 = ax.bar(x - width/2, a[1], width, label='Hash')
    rects2 = ax.bar(x + width/2, a[2], width, label='Heap')
    plt.yscale('log')
    # plt.xscale('log')
    ax.set_ylabel('times(s)')
    ax.set_title('Hash vs Heap (degree<=10)')
    ax.set_xticks(x)
    ax.set_xticklabels(labels)
    ax.legend()
    autolabel(rects1,ax)
    autolabel(rects2,ax)
    fig.tight_layout()
    plt.savefig('/home/ubuntu/hypergraph/GPU-butterfly/Hash_vs_Heap.pdf')


def Hash_vs_Sort():
    x = np.arange(len(labels))  # the label locations
    width = 0.35  # the width of the bars
    fig, ax = plt.subplots()
    rects1 = ax.bar(x - width/2, a[4], width, label='Hash')
    rects2 = ax.bar(x + width/2, a[5], width, label='Sort')
    plt.yscale('log')
    # plt.xscale('log')
    ax.set_ylabel('times(s)')
    ax.set_title('Hash vs Sort (degree<=32)')
    ax.set_xticks(x)
    ax.set_xticklabels(labels)
    ax.legend()
    autolabel(rects1,ax)
    autolabel(rects2,ax)
    fig.tight_layout()
    plt.savefig('/home/ubuntu/hypergraph/GPU-butterfly/Hash_vs_Sort.pdf')

def Hash_stack():
    x = np.arange(len(labels))  # the label locations
    width = 0.35  # the width of the bars
    fig, ax = plt.subplots()
    b=np.zeros((4,3))
    for i in range(3):
        b[0][i]=a[3][i]/(a[3][i]+a[6][i]+a[1][i])
        b[1][i]=a[6][i]/(a[3][i]+a[6][i]+a[1][i])
        b[2][i]=(a[3][i]+a[6][i])/(a[3][i]+a[6][i]+a[1][i])
        b[3][i]=a[1][i]/(a[3][i]+a[6][i]+a[1][i])
    print(b[0],b[1])
    rects1 = ax.bar(labels, b[0], width, label='Hash(degree>32)')
    rects2 = ax.bar(labels, b[1], width, bottom=b[0], label='Hash(32>=degree>10)')
    rects2 = ax.bar(labels, b[3], width, bottom=b[2], label='Hash(degree<=10)')
    # rects3 = ax.bar(x + width/2, b[2], width, label='Hash(degree>10)')
    # rects4 = ax.bar(x + width/2, b[3], width, bottom=b[2],label='Heap(degree<10)')
    # plt.yscale('log')
    # plt.xscale('log')
    ax.set_ylabel('percentage')
    ax.set_title('Hash_stack')
    ax.set_xticks(x)
    ax.set_xticklabels(labels)
    ax.legend()
    # fig.tight_layout()
    plt.savefig('/home/ubuntu/hypergraph/GPU-butterfly/Hash_stack.pdf')

# Hash_vs_Heap()
# Hash_vs_Sort()
Hash_stack()