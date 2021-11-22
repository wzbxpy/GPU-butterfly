# -*- coding: utf-8 -*-

import os
import numpy as np


def file_name(file_dir):
    lst = []
    for root, dirs, files in os.walk(file_dir):
        if ("sorted" in root):
            lst.append(root)
    return lst


os.system("make")
pathList = file_name("/home/shbing/dataUse/datasets/bipartite/")
pathList = ['/home/shbing/dataUse/datasets/bipartite/orkut/sorted']
print(pathList)
for path in pathList:
    for i in np.logspace(1, 10, 10, base=2):
        oriPath = path
        newPath = path.replace("dataUse", "datasetsNew")
        #print(oriPath, newPath)
        name = newPath.split("/")[-2]
        print(name, path)
        num = int(i)
        out = os.system(
            f"/home/wzb/bc/GPU-butterfly/cpu-code/butterfly.bin {newPath} run -1 {name} {num}")
# for path in pathList:
#     oriPath = path
#     newPath = path.replace("dataUse", "datasetsNew")
#     #print(oriPath, newPath)
#     print(newPath)
#     #a = os.system(f"./try {newPath}")
#     #print(a)
