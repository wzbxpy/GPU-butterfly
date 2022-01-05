#include <iostream>
#include "graph.h"
#include "butterfly-GPU.h"
#include "countingAlgorithm-CPU/butterfly-CPU.h"
#include <string>
#include <cstdlib>
#include <cstdio>
#include <atomic>
#include <thread>
#include <cmath>

using namespace std;

void printGraph(graph *bipartiteGraph)
{
    int pre = 999999;
    for (int i = 0; i < bipartiteGraph->uCount + bipartiteGraph->vCount; i++)
    {
        if (bipartiteGraph->beginPos[i + 1] - bipartiteGraph->beginPos[i] > pre)
            cout << "err " << i << ' ' << pre << " " << bipartiteGraph->beginPos[i + 1] - bipartiteGraph->beginPos[i] << endl;
        pre = bipartiteGraph->beginPos[i + 1] - bipartiteGraph->beginPos[i];
    }
    // for (int i = 0; i < bipartiteGraph->uCount + bipartiteGraph->vCount + 1; i++)
    //     cout << bipartiteGraph->beginPos[i] << ' ';
    // cout << endl;
    // for (int i = 0; i < bipartiteGraph->edgeCount; i++)
    //     cout << bipartiteGraph->edgeList[i] << ' ';
    // cout << endl;
}

int main(int argc, char *argv[])
{
    string path;
    if (argc > 1)
    {
        path = argv[1];
    }
    graph *G = new graph;
    parameter para;
    string loadOption = "default";
    if (argc > 2)
    {
        loadOption = argv[2];
    }
    if (loadOption == "default")
    {
        if (argc > 3)
        {
            para.partitionNum = atoi(argv[3]);
        }
        // bipartiteGraph->loadGraph(path);
        // bipartiteGraph->loadGraph("/home/wzb/bc/dataset/twitter");
    }
    if (loadOption == "Partition")
    {
        G->loadGraph(path);
        if (argc > 3)
        {
            para.partitionNum = atoi(argv[3]);
            if (argc > 4)
            {
                string a4 = argv[4];
                if (argc > 5)
                    para.memorySize = atol(argv[5]);
                if (argc > 6)
                    para.processorNum = atoi(argv[6]);
                if (argc > 7)
                    para.batchNum = atoi(argv[7]);
                if (a4 == "wedge-centric")
                {
                    para.partitionNum = ceil(G->vertexCount / sqrt(para.memorySize / sizeof(atomic<int>)));
                    cout << "wc partition num: " << para.partitionNum << " ";
                    para.varient = wedgecentric;
                }
                else
                {
                    para.partitionNum = ceil((G->edgeCount + G->vertexCount * para.processorNum / para.batchNum) / (para.memorySize / sizeof(int)));
                    cout << "size:" << G->edgeCount << " " << para.memorySize << " " << G->edgeCount / (para.memorySize / sizeof(int)) << endl;
                    cout << "ec partition num: " << para.partitionNum << " ";
                    para.varient = edgecentric;
                }
            }
            G->partitionGraphSrc(para.partitionNum);
            G->partitionGraphDst(para.partitionNum * para.batchNum);
            G->storeGraph(path);
        }
        else
        {
            cout << "Need number of partitions" << endl;
            return 0;
        }
    }
    BC_CPU(path, G, para, false);

    // CPU benchmark
    // vector<int> threadsNumList = {1, 2, 4, 8, 16, 32, 56, 112};
    // vector<int> threadsNumList = {1};
    // for (auto i : threadsNumList)
    // {
    //     BC_CPU(path, bipartiteGraph, i, computationPattern, false, partitionNum);
    //     // BC_CPU(path, bipartiteGraph, i, wedgecentric, false, partitionNum);
    //     // BC_CPU(path, bipartiteGraph, i, edgecentric, true, partitionNum);
    //     // BC_CPU(bipartiteGraph, i, true, true);
    // }

    // BC_CPU(bipartiteGraph, 1, true, false);

    // GPU benchmark
    // vector<int> blocksNumList = {1, 2, 4, 8, 16, 32, 64, 108, 216};
    // // vector<int> blocksNumList = {108};
    // for (auto i : blocksNumList)
    // {
    //     BC_GPU(bipartiteGraph, i, true);
    // }

    // BC_GPU(bipartiteGraph, 112, true);
    // BC_wedge_centric(bipartiteGraph);

    delete (G);
    return 0;
}