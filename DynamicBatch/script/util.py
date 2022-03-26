import sys
import os
import numpy as np


def average_of_several_run(script: str, repeat: int):
    np.set_printoptions(threshold=np.inf, linewidth=np.inf, suppress=False)
    average_res = []
    for re in range(repeat):
        f = os.popen(script)
        res = f.readlines()
        if len(res[-1]) < 3:
            print("err")
            return
        res1 = res[0].strip().split(" ")[-2:] + \
            res[-1].strip().split(" ")[-4:]
        average_res.append(res1)
    average_res = np.array(average_res).astype(float).mean(axis=0)
    print(average_res)


def clean_disk():
    script = "rm -rf /home/wzb/bc/dataset/*/partition*"
    f = os.popen(script)
    res = f.readlines()
