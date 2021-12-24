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
    void loadgraph(string folderName);
    void loadSubgraph(string foldername, int id, bool isSrc);
    void loadWangkaiGraph(string folderName);
    void partitionGraphSrc(int num);
    void partitionGraphDst(int num);
    void storeGraph(string path);
    ~graph();
};

#endif