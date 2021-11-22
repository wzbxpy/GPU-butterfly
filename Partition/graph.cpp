#include "graph.h"
#include <string>
#include <fstream>
#include <iostream>
#include <algorithm>
#include <vector>
#include <memory>
#include <sys/stat.h>
#include <sys/types.h>

using namespace std;
bool cmp1(int a, int b)
{
    return a > b;
}

void graph::loadGraph(string path)
{
    printf("Loading graph...\n");
    fstream propertiesFile(path + "/properties.txt", ios::in);
    propertiesFile >> uCount >> vCount >> edgeCount;
    cout << "properties: " << uCount << " " << vCount << " " << edgeCount << endl;
    edgeCount *= 2;
    beginPos = new long long[uCount + vCount + 1];
    edgeList = new int[edgeCount];
    propertiesFile.close();
    fstream beginFile(path + "/begin.bin", ios::in | ios::binary);
    fstream adjFile(path + "/adj.bin", ios::in | ios::binary);
    beginFile.read((char *)beginPos, sizeof(long long) * (uCount + vCount + 1));
    adjFile.read((char *)edgeList, sizeof(int) * (edgeCount));
    beginFile.close();
    adjFile.close();

    int *deg = new int[uCount + vCount];
    int n = uCount + vCount;
    for (int i = 0; i < uCount + vCount; ++i)
        deg[i] = beginPos[i + 1] - beginPos[i];
    breakVertex10 = lower_bound(deg, deg + n, 10, cmp1) - deg;
    breakVertex32 = lower_bound(deg, deg + n, 32, cmp1) - deg;
    vertexCount = uCount + vCount;
    delete (deg);
}

void graph::loadWangkaiGraph(string path)
{

    printf("Loading wangkai graph...");
    cout << path << endl;
    fstream Fin(path + "graph-sort.bin", ios::in | ios::binary);
    Fin.read((char *)&uCount, sizeof(int));
    int n;
    Fin.read((char *)&n, sizeof(int));
    vCount = n - uCount;
    Fin.read((char *)&edgeCount, sizeof(long long));
    int *deg = new int[n], **con = new int *[n], *nid = new int[n], *oid = new int[n];
    beginPos = new long long[uCount + vCount + 1];
    edgeList = new int[edgeCount];
    Fin.read((char *)deg, sizeof(int) * n);
    Fin.read((char *)edgeList, sizeof(int) * edgeCount);
    Fin.read((char *)nid, sizeof(int) * n);
    Fin.read((char *)oid, sizeof(int) * n);

    Fin.close();
    // auto xx=upper_bound(deg,deg+n,10,cmp1);
    // breakVertex10=distance(deg,xx);
    int ppp = 0;
    for (int i = 1; i < n; i++)
    {
        if (deg[i] < deg[i + 1])
            ppp = 1;
    }
    if (ppp)
        cout << path << " this dataset is not sorted" << endl;
    else
        cout << path << " this dataset is sorted" << endl;
    beginPos[0] = 0;
    uCount--;
    vCount--;
    long long p = 0;
    for (int i = 0; i < n; ++i)
    {
        // con[i] = edgeList+p;
        p += deg[i];
        beginPos[i + 1] = p;
    }

    breakVertex10 = lower_bound(deg, deg + n, 10, cmp1) - deg;
    breakVertex32 = lower_bound(deg, deg + n, 32, cmp1) - deg;
    vertexCount = uCount + vCount;
    delete (deg);
    delete (con);
    delete (oid);
    delete (nid);
}

void graph::patitionGraph(int num)
{
    partitionNum = num;
    subBeginPosSecond = new vector<long long>[partitionNum];
    subEdgeListSecond = new vector<int>[partitionNum];
    unique_ptr<vector<vector<int>>[]> a(new vector<vector<int>>[partitionNum]);
    length = (uCount + vCount) / partitionNum + 1;
    for (int i = 0; i < partitionNum; i++)
        a[i].resize(uCount + vCount);
    for (int i = 0; i < uCount + vCount; i++)
    {
        for (long long j = beginPos[i]; j < beginPos[i + 1]; j++)
        {
            int dstVertex = edgeList[j];
            int id = dstVertex % partitionNum;
            a[id][i].push_back(dstVertex);
        }
    }
    for (int n = 0; n < partitionNum; n++)
    {
        long long count = 0;
        for (int i = 0; i < uCount + vCount; i++)
        {
            subBeginPosSecond[n].push_back(count);
            count += a[n][i].size();
            for (auto element : a[n][i])
                subEdgeListSecond[n].push_back(element);
        }
        subBeginPosSecond[n].push_back(count);
    }
    int sum = 0;
    for (int n = 0; n < partitionNum; n++)
    {
        sum += subEdgeListSecond[n].size();
        cout << "id:" << n << " edgenum:" << subEdgeListSecond[n].size() << endl;
    }
}

void graph::storeGraph(string path)
{
    string partitionedFolder = path + "partition" + to_string(partitionNum) + '/';
    mkdir(partitionedFolder.c_str(), S_IRWXU | S_IRWXG | S_IRWXO);
    for (int i = 0; i <= partitionNum; i++)
    {
        fstream propertiesFile(partitionedFolder + "/properties" + to_string(i) + ".txt", ios::out);
        propertiesFile << subBeginPosSecond[i].size() << subEdgeListSecond[i].size() << endl;
        propertiesFile.close();
        fstream beginFile(partitionedFolder + "/begin" + to_string(i) + ".bin", ios::out | ios::binary);
        beginFile.write((char *)subBeginPosSecond, sizeof(long long) * (subBeginPosSecond[i].size()));
        beginFile.close();
        fstream adjFile(partitionedFolder + "/adj" + to_string(i) + ".bin", ios::out | ios::binary);
        adjFile.write((char *)subEdgeListSecond, sizeof(int) * (subEdgeListSecond[i].size()));
        adjFile.close();
    }
}

graph::~graph()
{
    delete (beginPos);
    delete (edgeList);
    delete (subEdgeListFirst);
    delete (subEdgeListSecond);
    delete (subBeginPosFirst);
    delete (subBeginPosSecond);
}