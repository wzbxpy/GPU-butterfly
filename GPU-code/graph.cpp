#include "graph.h"
// #include "wtime.h"
#include <string>
#include <fstream>
#include <iostream>
#include <algorithm>
#include <vector>
#include <memory>

using namespace std;
bool cmp1(int a, int b)
{
    return a > b;
}

void graph::loadgraph(string path)
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

    double startTime = clock();
    beginFile.read((char *)beginPos, sizeof(long long) * (uCount + vCount + 1));
    adjFile.read((char *)edgeList, sizeof(int) * (edgeCount));
    cout << "time: " << (clock() - startTime) / CLOCKS_PER_SEC << endl;
    // cout << "time: " << (wtime() - startTime)  << endl;

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

void graph::loadSubgraph(string path, int id)
{
    for (int i = 0; i < 10; i++)
        for (int j = 0; j < 10; j++)
        {
        }
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

void graph::partitionGraphFirst(int num)
{
    partitionNum = num;
    subBeginPosFirst = new vector<long long>[num];
    subEdgeListFirst = new vector<int>[num];
    long long *count = new long long[num];
    for (int n = 0; n < num; n++)
        count[n] = 0;
    for (int i = 0; i < uCount + vCount; i++)
    {
        int n = i % partitionNum;
        subBeginPosFirst[n].push_back(count[n]);
        count[n] += beginPos[i + 1] - beginPos[i];
        for (int j = beginPos[i]; j < beginPos[i + 1]; j++)
            subEdgeListFirst[n].push_back(edgeList[j]);
        // subEdgeListFirst[n].insert(subEdgeListFirst[n].end(), edgeList + beginPos[i], edgeList + beginPos[i + 1]);
    }
    for (int n = 0; n < num; n++)
    {
        subBeginPosFirst[n].push_back(count[n]);
        // cout << "id:" << n << " edgenum:" << subEdgeListFirst[n].size() << endl;
    }
    delete (count);
}

void graph::partitionGraphSecond(int num)
{
    partitionNum = num;
    subBeginPosSecond = new vector<long long>[num];
    subEdgeListSecond = new vector<int>[num];
    unique_ptr<vector<vector<int>>[]> a(new vector<vector<int>>[num]);
    length = (uCount + vCount) / num + 1;
    for (int i = 0; i < num; i++)
        a[i].resize(uCount + vCount);
    for (int i = 0; i < uCount + vCount; i++)
    {
        for (long long j = beginPos[i]; j < beginPos[i + 1]; j++)
        {
            int dstVertex = edgeList[j];
            int id = dstVertex % num;
            a[id][i].push_back(dstVertex);
        }
    }
    for (int n = 0; n < num; n++)
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
    for (int n = 0; n < num; n++)
    {
        sum += subEdgeListSecond[n].size();
        // cout << "id:" << n << " edgenum:" << subEdgeListSecond[n].size() << endl;
    }
}
graph::~graph()
{
    delete (beginPos);
    delete (edgeList);
}