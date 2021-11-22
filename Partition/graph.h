#ifndef GRAPH_H
#define GRAPH_H
#include <string>
#include <vector>

using namespace std;
class graph
{
public:
    long long *beginPos;
    int *edgeList;
    vector<long long> *subBeginPosFirst;
    vector<int> *subEdgeListFirst;
    vector<long long> *subBeginPosSecond;
    vector<int> *subEdgeListSecond;
    int uCount, vCount, breakVertex32, breakVertex10, vertexCount;
    long long edgeCount;
    int length;
    int partitionNum;
    void loadGraph(string folderName);
    void loadWangkaiGraph(string folderName);
    void patitionGraph(int num);
    void storeGraph(string folderName);
    ~graph();
};

#endif