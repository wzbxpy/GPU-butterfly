import sys
import os
import numpy as np


def average_of_several_run(script: str, repeat: int):
    np.set_printoptions(threshold=np.inf, linewidth=np.inf, suppress=False)
    average_res = []
    for re in range(repeat):
        f = os.popen(script)
        # print(script)
        res = f.readlines()
        # print(res)
        if len(res[-1]) < 3:
            print("err")
            return [-1, 99999]
        res1 = res[0].strip().split(" ")[-2:] + \
            res[-1].strip().split(" ")[-4:]
        average_res.append(res1)

    average_res = np.array(average_res).astype(float).mean(axis=0)
    # print(average_res)

    return [average_res[1], np.sum(average_res[3:6])]


def clean_disk():
    script = "rm -rf /home/wzb/bc/dataset/*/partition*"
    f = os.popen(script)
    res = f.readlines()


def wedgeOredge(path: str, memory: int) -> str:
    path = path+"properties.txt"
    with open(path, 'r') as f:
        f = f.readlines()
        f = np.array(f[0].strip().split(" ")).astype(float)
        vertices = f[0]+f[1]
        edges = f[2]
        memory = np.sqrt(memory/4)
        if memory > 2*edges/vertices:
            return 'edge-centric'
        else:
            return "wedge-centric"
    return 'error'


if __name__ == "__main__":
    print(wedgeOredge("/home/wzb/bc/dataset/kron16-32768/", 1138787621))
