#include <iostream>
#include "graph.h"
#include <string>
#include <cstdlib>
#include <cstdio>

using namespace std;

void printGraph(graph bipartiteGraph)
{
    for (int i=0;i<bipartiteGraph.uCount+bipartiteGraph.vCount+1;i++)
        cout<<bipartiteGraph.beginPos[i]<<' ';
    cout<<endl;
    for (int i=0;i<bipartiteGraph.edgeCount;i++)
        cout<<bipartiteGraph.edgeList[i]<<' ';
}
int main(int argc, char* argv[])
{
    string path;
    if (argc>1)
    {
        path=argv[1];
    }
    int p=0;
    if (argc>1)
    {
        p=atoi(argv[2]);
    }
    graph bipartiteGraph;
    if (p)
    {
        bipartiteGraph.loadgraph(path);
    }
    else
    {
        bipartiteGraph.loadWangkaiGraph(path);
    }

    cout<<bipartiteGraph.edgeCount<<endl;
    cout<<bipartiteGraph.uCount<<' '<<bipartiteGraph.vCount<<endl;
    // printGraph(bipartiteGraph);
    // BC(bipartiteGraph);
}