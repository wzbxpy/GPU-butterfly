#ifndef GRAPH_H
#define GRAPH_H
#include <string>

using namespace std;
class graph
{
    public:
    long long* beginPos;
    int* edgeList;
    int uCount,vCount,edgeCount;
    void loadgraph(string folderName);
    void loadWangkaiGraph(string folderName);
};

#endif