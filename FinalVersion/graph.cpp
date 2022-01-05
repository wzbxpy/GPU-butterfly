#include "graph.h"
#include "wtime.h"
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

void graph::loadProperties(string path)
{
    fstream propertiesFile(path + "/properties.txt", ios::in);
    propertiesFile >> uCount >> vCount >> edgeCount;
    vertexCount = uCount + vCount;
    propertiesFile.close();
}

double graph::loadGraph(string path)
{
    // cout << "Loading graph..." << path << endl;
    loadProperties(path);
    if (beginPos == nullptr)
        beginPos = new long long[vertexCount + 1];
    if (edgeList == nullptr)
        edgeList = new int[edgeCount];
    fstream beginFile(path + "/begin.bin", ios::in | ios::binary);
    fstream adjFile(path + "/adj.bin", ios::in | ios::binary);
    double startTime = clock();
    beginFile.read((char *)beginPos, sizeof(long long) * (vertexCount + 1));
    adjFile.read((char *)edgeList, sizeof(int) * (edgeCount));
    double time = (clock() - startTime) / CLOCKS_PER_SEC;
    // cout << "time: " << (clock() - startTime) / CLOCKS_PER_SEC << endl;
    // cout << "time: " << (wtime() - startTime)  << endl;
    beginFile.close();
    adjFile.close();
    return time;
    // int *deg = new int[vertexCount];
    // int n = vertexCount;
    // for (int i = 0; i < vertexCount; ++i)
    //     deg[i] = beginPos[i + 1] - beginPos[i];
    // breakVertex10 = lower_bound(deg, deg + n, 10, cmp1) - deg;
    // breakVertex32 = lower_bound(deg, deg + n, 32, cmp1) - deg;
    // delete (deg);
}

void graph::loadSubGraph(string path, int id, bool isSrc)
{
    cout << "load subgraph" << endl;
    //initialize path
    string prefix = isSrc ? "/src" : "/dst";
    prefix = path + prefix + to_string(id);

    //load data properties
    fstream propertiesFile(prefix + "properties.txt", ios::in);
    propertiesFile >> vertexCount >> edgeCount;
    propertiesFile.close();

    //check whether the space is allocated
    if (beginPos == nullptr)
        beginPos = new long long[vertexCount + 1];
    if (edgeList == nullptr)
        edgeList = new int[edgeCount];

    //load edges
    fstream beginFile(prefix + "begin.bin", ios::in | ios::binary);
    fstream adjFile(prefix + "adj.bin", ios::in | ios::binary);
    beginFile.read((char *)beginPos, sizeof(long long) * (vertexCount + 1));
    adjFile.read((char *)edgeList, sizeof(int) * (edgeCount));
    beginFile.close();
    adjFile.close();
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

void graph::partitionGraphSrc(int num)
{
    partitionNumSrc = num;
    subBeginPosFirst = new vector<long long>[num];
    subEdgeListFirst = new vector<int>[num];
    unique_ptr<long long[]> count{new long long[num]};
    for (int n = 0; n < num; n++)
        count[n] = 0;
    for (int i = 0; i < uCount + vCount; i++)
    {
        int n = i % num;
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
}

void graph::partitionGraphDst(int num)
{
    partitionNumDst = num;
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

void storeSubgraph(string prefix, vector<long long> subBeginPos, vector<int> subEdgeList)
{
    mkdir(prefix.c_str(), S_IRWXU | S_IRWXG | S_IRWXO);
    fstream propertiesFile(prefix + "properties.txt", ios::out);
    propertiesFile << 0 << ' ' << subBeginPos.size() - 1 << ' ' << subEdgeList.size() << endl;
    propertiesFile.close();
    fstream beginFile(prefix + "begin.bin", ios::out | ios::binary);
    beginFile.write((char *)&subBeginPos[0], sizeof(long long) * (subBeginPos.size()));
    beginFile.close();
    fstream adjFile(prefix + "adj.bin", ios::out | ios::binary);
    adjFile.write((char *)&subEdgeList[0], sizeof(int) * (subEdgeList.size()));
    adjFile.close();
}

void graph::storeGraph(string path)
{
    string partitionedFolder = path + "partition";
    // mkdir(partitionedFolder.c_str(), S_IRWXU | S_IRWXG | S_IRWXO);
    for (int i = 0; i < partitionNumSrc; i++)
    {
        storeSubgraph(partitionedFolder + to_string(partitionNumSrc) + "src" + to_string(i) + "/", subBeginPosFirst[i], subEdgeListFirst[i]);
    }
    for (int i = 0; i < partitionNumDst; i++)
    {
        storeSubgraph(partitionedFolder + to_string(partitionNumDst) + "dst" + to_string(i) + "/", subBeginPosSecond[i], subEdgeListSecond[i]);
    }
}

graph::~graph()
{

    if (beginPos != nullptr)
        delete (beginPos);
    if (edgeList != nullptr)
        delete (edgeList);
    // if (subEdgeListFirst != nullptr)
    //     delete (subEdgeListFirst);
    // if (subEdgeListSecond != nullptr)
    //     delete (subEdgeListSecond);
    // if (subBeginPosFirst != nullptr)
    //     delete (subBeginPosFirst);
    // if (subBeginPosSecond != nullptr)
    //     delete (subBeginPosSecond);
}