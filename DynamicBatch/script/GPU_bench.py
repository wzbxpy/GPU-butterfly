import sys
import os
import numpy as np
import time
import pandas as pd
from tkinter import font
from matplotlib.axes import Axes
from matplotlib.transforms import Bbox
from matplotlib import markers, pyplot as plt, scale
import matplotlib
from matplotlib import rcParams
from matplotlib.backends.backend_pdf import PdfPages
import math

np.set_printoptions(threshold=np.inf, linewidth=np.inf, suppress=False)

rcParams["text.usetex"] = True
rcParams["font.family"] = "serif"

rcParams["font.serif"] = ["Times New Roman"] + rcParams["font.serif"]
rcParams["font.size"] = 17
rcParams["font.weight"] = "light"
# rcParams["figure.autolayout"] = True

labels = [1, 2, 3]
patterns = ["", "//", "\\", "--", "xx", "oo", "*", ".", "///"]
matplotlib.rc("hatch", linewidth=0)
styles = ["d-", "s-", "^-", "o-", "^-", "+-", "s-", ".-"]
markers = ["d", "s", "^", "o"]


def average_of_several_run_GPU(script: str, repeat: int):
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
        res1 = res[0].strip().split(" ")[-2:] + res[-1].strip().split(" ")[-5:]
        average_res.append(res1)

    average_res = np.array(average_res).astype(float).mean(axis=0)
    # print(average_res)

    return average_res


def export_legend(legend, filename="legend.pdf", expand=[-5, -5, 5, 5]):
    fig = legend.figure
    fig.canvas.draw()
    bbox = legend.get_window_extent()
    bbox = bbox.from_extents(*(bbox.extents + np.array(expand)))
    bbox = bbox.transformed(fig.dpi_scale_trans.inverted())
    fig.savefig(filename, bbox_inches=bbox)


repeat = 1
if len(sys.argv) > 1:
    repeat = int(sys.argv[1])

path = "/home/wzb/bc/GPU-butterfly/DynamicBatch/"
# f = os.popen('make')
# f.readlines()
dataPath = "/data/dataset/dataset"
# print(os.listdir(dataPath))
folds = os.listdir(dataPath)
print(folds)
# folds = ["twitter", "MANN-a81", "filcker", "livejournal", "delicious", "trackers", "orkut", "bi-twitter", "bi-sk", "bi-uk"]
Paras_all = [
    ("twitter", 20770352),
    ("MANN-a81", 44077616),
    ("filcker", 72359344),
    ("livejournal", 983981296),
    ("delicious", 1091282080),
    ("trackers", 1448285896),
    ("orkut", 2708412328),
    ("bi-twitter", 5147097304),
    ("bi-sk", 7692486280),
    ("bi-uk", 11242987032),
]
Paras_selected = [("livejournal", 983981296), ("delicious", 1091282080), ("trackers", 1448285896), ("orkut", 2708412328)]
filenames_sharedMemory = ["butterfly_shared0", "butterfly_shared1", "butterfly_shared2", "butterfly_shared4", "butterfly_shared8"]
# filenames_hashRecy = ["butterfly_adaptive", "butterfly_scanwedge", "butterfly_scantable"]


def reset_yaxis(df: pd.DataFrame):
    bottom, top = np.nanmin(df.to_numpy()), np.nanmax(df.to_numpy())
    print(bottom, top)
    bottom = np.float_power(10, math.floor(np.log10(bottom)))
    top = np.float_power(10, math.ceil(np.log10(top)))
    plt.ylim(bottom, top)
    plt.yticks(np.logspace(int(np.log10(bottom)), int(np.log10(top)), int(1 + np.log10(top) - np.log10(bottom))))


def plot_subwarp(csv_file: str):
    rcParams["font.size"] = 17
    rcParams["figure.figsize"] = (4, 3)
    df = pd.read_csv(csv_file + ".csv", index_col=0)
    df = df.transpose()
    print(df)
    ax = df.plot()
    name = [r"$M=10\%|E|$", r"$M=25\%|E|$", r"$M=|E|$", r"$M=\infty$"]
    plt.legend(name, loc="upper center", bbox_to_anchor=(0.5, 2), ncol=4, fontsize="small")
    leg = ax.get_legend()

    export_legend(leg, filename=path + "result/subwarp_legend.pdf")
    plt.legend().remove()
    plt.yscale("log")
    ax.set_xticks(range(len(df)))
    ax.set_xticklabels(df.index)
    reset_yaxis(df)
    plt.ylabel("Time (s)")
    plt.xlabel("Size of subwarp")
    plt.savefig(csv_file + ".pdf", bbox_inches="tight")


def plot_sharedMemory(csv_file: str):
    rcParams["font.size"] = 17
    rcParams["figure.figsize"] = (4, 3)
    df = pd.read_csv(csv_file + ".csv", index_col=0)
    df = df.transpose()
    df.index = ["0 MB", "4 MB", "8 MB", "16 MB", "32 MB"]
    df = df.iloc[0] / df
    print(df)
    ax = df.plot()
    name = [r"$M=10\%|E|$", r"$M=25\%|E|$", r"$M=|E|$", r"$M=\infty$"]
    plt.legend(name, loc="upper center", bbox_to_anchor=(0.5, 2), ncol=4, fontsize="small")
    leg = ax.get_legend()

    export_legend(leg, filename=path + "result/shared_legend.pdf")
    plt.legend().remove()
    # plt.yscale("log")
    ax.set_xticks(range(len(df)))
    ax.set_xticklabels(df.index)
    ax.set_ylim(0.9, 1.3)
    plt.ylabel("Speedup")
    plt.xlabel("Shared memory size")
    # reset_yaxis(df)
    plt.savefig(csv_file + ".pdf", bbox_inches="tight")


def plot_block_vs_warp(csv_file: str):
    rcParams["font.size"] = 17
    rcParams["figure.figsize"] = (8, 3)
    df = pd.read_csv(csv_file + ".csv", index_col=0)
    # df.columns = df.iloc[0]
    # df = df[1:]
    ax = df.plot(kind="bar")
    plt.legend(loc="upper center", ncol=4, fontsize="small")
    leg = ax.get_legend()

    # export_legend(leg, filename=path + "result/block_vs_warp_legend.pdf")
    # plt.legend().remove()
    plt.yscale("log")
    xticks = ["{:>4}-{:>4}".format(i * 32 + 1, (i + 1) * 32) for i in range(32)] + ["1025-  $\infty$"]
    print(xticks)
    # plt.xticks(np.arange(33), [i.replace(" ", r"\ ") for i in xticks])
    ax.set_xticklabels([i.replace(" ", r"\ ") for i in xticks])
    ax.tick_params(axis="x", labelsize=13)
    ax.set_ylabel("Time (s)")
    ax.set_xlabel("Degree range of processed vertex")
    # for tick in ax.get_xticklabels():
    #     tick.set_verticalalignment("center")
    # reset_yaxis(df)
    plt.savefig(csv_file + ".pdf", bbox_inches="tight")


def plot_block_vs_warp_overall_performance(csv_file: str):
    rcParams["font.size"] = 17
    rcParams["figure.figsize"] = (4, 3)
    df_overall = pd.DataFrame(columns=["block only", "hybrid", "aggressive warp"])
    for i in [0.2, 0.5, 2, 50]:
        df = pd.read_csv(csv_file + str(i) + ".csv", index_col=0)
        result = [0, 0, 0]
        warp = True
        for index, row in df.iterrows():
            if row["warp"] > row["block"]:
                warp = False
            result[0] = result[0] + row["block"]  # type: ignore
            if warp:
                result[1] = result[1] + row["warp"]  # type: ignore
            else:
                result[1] = result[1] + row["block"]  # type: ignore
            # result[1] += min(row["block"], row["warp"])  # type: ignore
            result[2] = result[2] + row["warp"]  # type: ignore
            if row.name == 32:  # type: ignore
                result[2] = result[2] + row["block"]  # type: ignore
        df_overall.loc[len(df_overall)] = result

    print(df_overall)
    ax = df_overall.plot(kind="bar")
    plt.legend(loc="upper center", ncol=4, fontsize="small")
    name = [r"$10\%|E|$", r"$25\%|E|$", r"$|E|$", r"$\infty$"]
    ax.set_xticklabels(name)
    plt.xticks(rotation=0, fontsize=14)

    plt.legend(loc="upper center", bbox_to_anchor=(0.5, 2), ncol=4, fontsize="small")
    leg = ax.get_legend()
    export_legend(leg, filename=path + "result/block_vs_warp_legend.pdf")
    plt.legend().remove()
    plt.yscale("log")
    ax.set_ylabel("Time (s)")
    ax.set_xlabel("Memory size")
    # reset_yaxis(df)
    plt.savefig(csv_file + ".pdf", bbox_inches="tight")


def vary_execution_file(Paras, filenames):
    for fold, memorySize in Paras:
        df = pd.DataFrame(columns=filenames)
        for i in [0.2, 0.5, 2, 50]:
            thisMemorySize = memorySize * i
            filePath = os.path.join(dataPath, fold)
            if os.path.isdir(filePath):
                data = []
                for filename in filenames:
                    script = path + filename + ".bin " + filePath + "/ GPU 100 edge-centric " + str(int(thisMemorySize)) + " 108"
                    print(script)
                    data.append(average_of_several_run_GPU(script, repeat)[3])
                print(data)
                df.loc[len(df)] = data  # type: ignore
        df.to_csv(path + "result/shared" + fold + ".csv")


def vary_subwarp_size(Paras):
    options = [1, 2, 4, 8, 16, 32]
    for fold, memorySize in Paras:
        # df = pd.DataFrame(columns=["memorySize"] + [r"$M=10\%|E|$", r"$M=25\%|E|$", r"$M=|E|$", r"$M=\infty$"])
        df = pd.DataFrame(columns=[1, 2, 4, 8, 16, 32])
        for i in [0.2, 0.5, 2, 50]:
            thisMemorySize = memorySize * i
            filePath = os.path.join(dataPath, fold)
            if os.path.isdir(filePath):
                data = []
                for option in options:
                    script = path + "butterfly.bin " + filePath + "/ GPU 100 edge-centric " + str(int(thisMemorySize)) + " 108 -1 adaptiveRecy " + str(option)
                    data.append(average_of_several_run_GPU(script, repeat)[3])
            df.loc[len(df)] = data  # type: ignore
        df.to_csv(path + "result/" + "subwarp" + fold + ".csv")


def vary_hashtable_recy(Paras):
    options = ["adaptiveRecy", "scanHashtableRecy", "scanWedgeRecy"]
    df = pd.DataFrame(columns=["Dataset"] + options)
    for fold, memorySize in Paras:
        filePath = os.path.join(dataPath, fold)
        if os.path.isdir(filePath):
            data = [fold]
            for option in options:
                script = path + "butterfly.bin " + filePath + "/ GPU 100 edge-centric 507374182400 108 -1 " + option + " 16"
                data.append(average_of_several_run_GPU(script, repeat)[3])
            print(data)
            df.loc[len(df)] = data  # type: ignore
    return df


def block_vs_warp(Paras):
    def average_of_several_run_for_block_vs_warp(script: str, repeat: int):
        np.set_printoptions(threshold=np.inf, linewidth=np.inf, suppress=False)
        average_res = []
        for re in range(repeat):
            f = os.popen(script)
            # print(script)
            res = f.readlines()
            df = pd.DataFrame([i.strip().split() for i in res[2:]])
            average_res.append(df.to_numpy())

        average_res = np.array(average_res).astype(float).mean(axis=0)
        # # print(average_res)
        return pd.DataFrame(average_res)

    for fold, memorySize in Paras:
        # df = pd.DataFrame(columns=["memorySize"] + [r"$M=10\%|E|$", r"$M=25\%|E|$", r"$M=|E|$", r"$M=\infty$"])
        df = pd.DataFrame(
            columns=["partition num", "batch num", "find break vertex cost", "block cost", "small workload block cost", "small workload warp cost", "io cost"]
        )
        for i in [0.2, 0.5, 2, 50]:
            thisMemorySize = memorySize * i
            filePath = os.path.join(dataPath, fold)
            if os.path.isdir(filePath):
                data = []
                script = (
                    path + "butterfly.bin " + filePath + "/ GPU 100 edge-centric " + str(int(thisMemorySize)) + " 108 -1 adaptiveRecy 16 blockForSmallWorkload"
                )
                # res=average_of_several_run_GPU(script, repeat)
                data = average_of_several_run_for_block_vs_warp(script, repeat)
                data.columns = ["block", "warp"]
                print(data)
                data.to_csv(path + "result/" + "blockVSwarp" + fold + str(i) + ".csv")
        #     df.loc[len(df)] = data  # type: ignore
        # df.to_csv(path + "result/" + "blockVSwarp" + fold + ".csv")


# vary_subwarp_size(Paras_selected)
# # df.to_csv(path + "result/" + "subwarp.csv")
# for fold, _ in Paras_selected:
#     plot_subwarp(path + "result/" + "subwarp" + fold)
# vary_execution_file(Paras_selected, filenames_sharedMemory)
# for fold, _ in Paras_selected:
#     plot_sharedMemory(path + "result/" + "shared" + fold)
# block_vs_warp(Paras_selected)

# for fold, _ in Paras_selected:
#     for i in [0.2, 0.5, 2, 50]:
#         plot_block_vs_warp(path + "result/" + "blockVSwarp" + fold + str(i))


for fold, _ in Paras_selected:
    plot_block_vs_warp_overall_performance(path + "result/" + "blockVSwarp" + fold)
