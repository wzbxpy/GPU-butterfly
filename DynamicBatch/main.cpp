#define GPU
#include <iostream>
#include "graph.h"
#ifdef GPU
#include "countingAlgorithm-GPU/butterfly-GPU.h"
#endif
#include "countingAlgorithm-CPU/butterfly-CPU.h"
#include <string>
#include <cstdlib>
#include <cstdio>
#include <atomic>
#include <thread>
#include <cmath>
#include <unistd.h>
#include "wtime.h"
double alpha = 0.2;

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
    string loadOption = "Partition";
    string Platform = "GPU";
    if (argc > 2)
    {
        Platform = argv[2];
    }

    // different hardware has different preference of optimization
    // if (Platform == "CPU")
    // {
    //     alpha = 0.2;
    // }
    // else
    // {
    //     alpha = 0.2;
    // }
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
        G->loadProperties(path);
        cout << "prperties " << G->vertexCount << " " << G->edgeCount << " ";
        if (argc > 3)
        {
            string option = argv[3];
            para.option = radixHash;
            if (option == "random")
                para.option = randomHash;
            if (option == "range")
                para.option = rangeHash;
            if (argc > 4)
            {
                string a4 = argv[4];
                if (argc > 5)
                    para.memorySize = atol(argv[5]);
                if (argc > 6)
                    para.processorNum = atoi(argv[6]);
                if (argc > 7)
                    para.batchNum = atoi(argv[7]);
                else
                    para.batchNum = -1;
                if (a4 == "wedge-centric")
                {
                    // double memoryForWedges = (para.memorySize - (double)G->vertexCount * sizeof(long long) * 2) / sizeof(int);
                    double memoryForWedges = (para.memorySize) / sizeof(int);
                    if (para.batchNum == -1)
                        para.batchNum = ceil(G->edgeCount * 2 / memoryForWedges);
                    double edgeSize = G->edgeCount * 2 / para.batchNum;
                    para.partitionNum = ceil(G->vertexCount / sqrt(memoryForWedges) + edgeSize / memoryForWedges);
                    cout << "wc partition num: " << para.partitionNum << ' ';
                    cout << para.batchNum << endl;
                    para.varient = wedgecentric;
                }
                else
                {
                    // double memoryForEdges = (para.memorySize - (double)G->vertexCount * sizeof(long long) * 3) / sizeof(int);
                    double memoryForEdges = (para.memorySize) / sizeof(int);
                    double suggestPartitionNum = ceil(G->edgeCount * 2 * (1 + alpha) / memoryForEdges);
                    double suggestBathNum = ceil(((long long)G->vertexCount * para.processorNum / suggestPartitionNum) / (memoryForEdges - G->edgeCount * 2 / suggestPartitionNum));
                    if (para.batchNum == -1)
                        para.batchNum = suggestBathNum;
                    // cout << "suggestion: " << suggestPartitionNum << " " << suggestBathNum << endl;
                    para.partitionNum = ceil((G->edgeCount * 2 + ((long long)G->vertexCount) / para.batchNum * para.processorNum) / memoryForEdges);
                    // set p,q
                    // cout << endl;
                    // cout << "possible " << endl;
                    // for (int p = ceil((G->edgeCount * 2 / memoryForEdges)); p < ceil((G->edgeCount * 2 + ((long long)G->vertexCount) * para.processorNum) / memoryForEdges); p++)
                    // {
                    //     int q = ceil(((long long)G->vertexCount * para.processorNum / p) / (memoryForEdges - G->edgeCount * 2 / p));
                    //     cout << q * p * p << ' ' << q * p << ' ' << p << ' ' << q << endl;
                    // }
                    // return 0;
                    // cout << "memory consumption: " << (double)G->vertexCount * sizeof(long long) * 3 << ' ' << G->edgeCount * 2 * sizeof(int) << ' ' << ((long long)G->vertexCount) / para.batchNum * para.processorNum * sizeof(int) << endl;
                    cout << "ec partition num: " << para.partitionNum << ' ';
                    cout << para.batchNum << endl;
                    if (para.partitionNum > 1000 || para.partitionNum < 1)
                    {
                        cout << endl;
                        return 0;
                    }
                    para.varient = edgecentric;
                }
            }
            if (Platform == "IO")
            {
                cout << "0 " << G->vertexCount * sizeof(long long) * para.partitionNum * 2 + G->edgeCount * sizeof(int) * 2 * para.partitionNum << " 0 0" << endl;
                return 0;
            }
            if (isSubgraphExist(path, para.partitionNum))
            // if (0)
            {
                // if (Platform == "GPU")
                //     G->loadAllSubgraphs(path, para.partitionNum);
            }
            else
            {

                G->partitionAndStore(para.partitionNum, path, false, para.option);
            }
            // G->loadGraph(path);
        }
        else
        {
            cout << "Need number of partitions" << endl;
            return 0;
        }
    }
    para.path = path;
#ifdef GPU
    if (Platform == "GPU")
        BC_GPU(G, para);
#endif
    if (Platform == "CPU")
        BC_CPU(path, G, para, false, false);
    if (Platform == "EMRC")
        BC_CPU(path, G, para, false, true);
    if (Platform == "sharedHashtable")
        BC_CPU(path, G, para, true, false);

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