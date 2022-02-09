#ifndef GRAPH_H
#define GRAPH_H
#include <string>
#include <vector>

using namespace std;
class graph
{
public:
    long long *beginPos = nullptr;
    int *edgeList = nullptr;
    vector<long long> *subBeginPosFirst;
    vector<int> *subEdgeListFirst;
    vector<long long> *subBeginPosSecond;
    vector<int> *subEdgeListSecond;
    int uCount, vCount, breakVertex32, breakVertex10, vertexCount;
    long long edgeCount;
    int length;
    int partitionNumSrc;
    int partitionNumDst;
    double loadGraph(string folderName);
    void loadProperties(string folderName);
    void loadBeginPos(string folderName);
    void loadSubGraph(string foldername, int id, bool isSrc);
    void loadWangkaiGraph(string folderName);
    void partitionGraphSrc(int num);
    void partitionGraphDst(int num);
    void storeGraph(string path);
    void loadAllSubgraphs(string path, int partitionNum);
    ~graph();
};

enum computationPattern
{
    wedgecentric,
    edgecentric
};

struct parameter
{
    int partitionNum;
    int batchNum;
    double memorySize;
    computationPattern varient;
    int processorNum;
    parameter()
    {
        partitionNum = 1;
        batchNum = 1;
        processorNum = 1;
        varient = edgecentric;
        memorySize = 1024 * 1024 * 1024;
    }
};

bool isSubgraphExist(string path, int partitionNum);

#endif