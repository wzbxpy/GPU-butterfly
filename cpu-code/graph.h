#ifndef GRAPH_H
#define GRAPH_H
#include <string>

using namespace std;
struct res{
    double totalTime, calcTime;
    long long ans;
    res(){
        totalTime = 0;
        calcTime = 0;
        ans = 0;
    }
    res(double _totalTime, double _calcTime, long long _ans){
        totalTime = _totalTime;
        calcTime = _calcTime;
        ans = _ans;
    }
};

class graph
{
    public:
    long long* beginPos1;
    int* beginPos;
    int* edgeList;
    int* deg;
    int uCount,vCount,breakVertex32,breakVertex10,vertexCount;
    long long edgeCount;
    void loadgraph(string folderName,int bound);
    int* beginPos16;
    int s16;
    ~graph();
};

#endif