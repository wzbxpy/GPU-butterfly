#ifndef GRAPH_H
#define GRAPH_H
#include <string>

using namespace std;
class graph
{
    public:
    long long* beginPos;
    int* edgeList;
    int uCount,vCount,breakVertex32,breakVertex10,vertexCount;
    long long edgeCount;
    void loadgraph(string folderName);
    void loadWangkaiGraph(string folderName);
    ~graph();
};

#endif