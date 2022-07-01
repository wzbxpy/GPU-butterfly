#ifndef GRAPH_H
#define GRAPH_H
#include <string>
#include <vector>

using namespace std;

enum partitionOption
{
    radixHash,
    randomHash,
    rangeHash
};

class graph
{
public:
    long long *beginPos = nullptr;
    int *edgeList = nullptr;
    vector<long long> *subBeginPosFirst = nullptr;
    vector<int> *subEdgeListFirst = nullptr;
    vector<long long> *subBeginPosSecond = nullptr;
    vector<int> *subEdgeListSecond = nullptr;
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
    void partitionAndStore(int num, string path, bool isInMemory, partitionOption option);
    void partitionAndStoreSrc(int num, string path, vector<int> part, vector<int> index);
    void partitionAndStoreDst(int num, string path, vector<int> part, vector<int> index);
    void storeGraph(string path);
    void loadAllSubgraphs(string path, int partitionNum);
    graph();
    ~graph();
};

enum computationPattern
{
    wedgecentric,
    edgecentric
};

// enum algorithmName
// {
//     EMRC,
//     sharedHashtable,
//     BCHM,
// };

struct parameter
{
    int partitionNum;
    int batchNum;
    double memorySize;
    computationPattern varient;
    partitionOption option;
    int processorNum;
    string path;
    parameter()
    {
        partitionNum = 1;
        batchNum = 1;
        processorNum = 1;
        varient = edgecentric;
        option = radixHash;
        memorySize = 1024 * 1024 * 1024;
        path = "";
    }
};

bool isSubgraphExist(string path, int partitionNum);

string subgraphFold(string path, int partitionNum, int index, bool isSrc);

#endif