#include <iostream>
#include "graph.h"
#include "butterfly.h"
#include <string>

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
    string folerName;
    if (argc>1)
    {
        folerName=argv[1];
    }
    graph bipartiteGraph;
    bipartiteGraph.loadgraph(folerName);
    cout<<bipartiteGraph.edgeCount<<endl;

    // printGraph(bipartiteGraph);
    BC(bipartiteGraph);
}