#include <iostream>
#include "graph.h"
#include <string>
#include <cstdlib>
#include <cstdio>

using namespace std;

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
    int p = 0;
    if (argc > 1)
    {
        p = atoi(argv[2]);
    }
    graph *bipartiteGraph = new graph;
    if (p)
    {
        bipartiteGraph->loadGraph(path);
    }
    else
    {
        bipartiteGraph->loadWangkaiGraph(path);
    }
    int num = 10;

    if (argc > 3)
    {
        num = atoi(argv[3]);
        bipartiteGraph->patitionGraph(num);
    }
    bipartiteGraph->storeGraph(path);
    // delete (bipartiteGraph);
    return 0;
}