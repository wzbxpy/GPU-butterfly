#include <iostream>
#include "graph.h"
#include "butterfly.h"
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
// int* binarySearchs(int* a, int* b, int x)
// {
//     while (a<b)
//     {
//         int* mid=a+((b-a)/2);
//         if (*mid<=x) a=mid+1; else b=mid;
//     }
//     return a;
// }
int main(int argc, char *argv[])
{
    // int a[3]={16055,71899,99412};
    // printf("%d %d 66\n",a,binarySearchs(a,a+3,71899));
    // sort_test();
    // return 0;
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
        bipartiteGraph->loadgraph(path);
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
    bipartiteGraph->patitionGraph(100);

    BC_hashtable_centric(bipartiteGraph);
    delete (bipartiteGraph);
    return 0;
}