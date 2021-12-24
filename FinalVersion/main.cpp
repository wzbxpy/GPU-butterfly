#include <iostream>
#include "graph.h"
#include "butterfly-GPU.h"
#include "countingAlgorithm-CPU/edgeCentric.h"
#include <string>
#include <cstdlib>
#include <cstdio>

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
    graph *bipartiteGraph = new graph;
    string loadOption = "default";
    if (argc > 1)
    {
        loadOption = argv[2];
    }
    if (loadOption == "default")
    {
        if (argc > 3)
        {
            int num = atoi(argv[3]);
            bipartiteGraph->partitionNum = num;
        }
        bipartiteGraph->loadgraph(path);
    }
    if (loadOption == "Wangkai")
        bipartiteGraph->loadWangkaiGraph(path);
    if (loadOption == "Partition")
    {
        if (argc > 3)
        {
            int num = atoi(argv[3]);
            bipartiteGraph->partitionNum = num;
        }
        else
        {
            cout << "Need number of partitions" << endl;
            return 0;
        }
    }

    // cout<<bipartiteGraph.edgeCount<<endl;
    // cout<<bipartiteGraph.uCount<<' '<<bipartiteGraph.vCount<<endl;
    // printGraph(bipartiteGraph);
    // cout<<path<<endl;
    int num = 1;
    // bipartiteGraph->partitionGraphSrc(num);
    // bipartiteGraph->partitionGraphDst(num);

    // test(bipartiteGraph, 112);
    BC_GPU(bipartiteGraph, true);
    // BC_wedge_centric(bipartiteGraph);
    delete (bipartiteGraph);
    return 0;
}