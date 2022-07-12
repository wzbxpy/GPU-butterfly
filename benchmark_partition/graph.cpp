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
#include <functional>
#include <unordered_set>
#include <cstdlib>
#include <cmath>

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

void graph::loadBeginPos(string path)
{
    loadProperties(path);
    if (beginPos == nullptr)
        beginPos = new long long[vertexCount + 1];
    fstream beginFile(path + "/begin.bin", ios::in | ios::binary);
    beginFile.read((char *)beginPos, sizeof(long long) * (long long)(vertexCount + 1));
    beginFile.close();
}

double graph::loadGraph(string path)
{
    // cout << "Loading graph..." << path << endl;
    loadBeginPos(path);
    if (edgeList == nullptr)
        edgeList = new int[edgeCount];
    double startTime = clock();
    fstream adjFile(path + "/adj.bin", ios::in | ios::binary);
    adjFile.read((char *)edgeList, sizeof(int) * (edgeCount));
    adjFile.close();
    double time = (clock() - startTime) / CLOCKS_PER_SEC;
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
    // initialize path
    string prefix = isSrc ? "/src" : "/dst";
    prefix = path + prefix + to_string(id);

    // load data properties
    fstream propertiesFile(prefix + "properties.txt", ios::in);
    propertiesFile >> vertexCount >> edgeCount;
    propertiesFile.close();

    // check whether the space is allocated
    if (beginPos == nullptr)
        beginPos = new long long[vertexCount + 1];
    if (edgeList == nullptr)
        edgeList = new int[edgeCount];

    // load edges
    fstream beginFile(prefix + "begin.bin", ios::in | ios::binary);
    fstream adjFile(prefix + "adj.bin", ios::in | ios::binary);
    beginFile.read((char *)beginPos, sizeof(long long) * (long long)(vertexCount + 1));
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

void loadOneSubgraph(string prefix, vector<long long> &subBeginPos, vector<int> &subEdgeList)
{
    fstream propertiesFile(prefix + "properties.txt", ios::in);
    long long a, b, c;
    propertiesFile >> a >> b >> c;
    a = a + b + 1;
    propertiesFile.close();
    subBeginPos.resize(a);
    fstream beginFile(prefix + "begin.bin", ios::in | ios::binary);
    beginFile.read((char *)&subBeginPos[0], sizeof(long long) * a);
    beginFile.close();
    subEdgeList.resize(c);
    fstream adjFile(prefix + "adj.bin", ios::in | ios::binary);
    adjFile.read((char *)&subEdgeList[0], sizeof(int) * c);
    adjFile.close();
}
void graph::loadAllSubgraphs(string path, int num)
{
    partitionNumSrc = num;
    partitionNumDst = num;
    string partitionedFolder = path + "partition";

    subBeginPosFirst = new vector<long long>[num];
    subEdgeListFirst = new vector<int>[num];
    subBeginPosSecond = new vector<long long>[num];
    subEdgeListSecond = new vector<int>[num];
    for (int i = 0; i < partitionNumSrc; i++)
    {
        loadOneSubgraph(partitionedFolder + to_string(partitionNumSrc) + "src" + to_string(i) + "/", subBeginPosFirst[i], subEdgeListFirst[i]);
    }
    for (int i = 0; i < partitionNumDst; i++)
    {
        loadOneSubgraph(partitionedFolder + to_string(partitionNumDst) + "dst" + to_string(i) + "/", subBeginPosSecond[i], subEdgeListSecond[i]);
    }
}

bool isSubgraphExist(string path, int partitionNum)
{
    int x;
    string pathSrc = path + "partition" + to_string(partitionNum) + "src" + to_string(partitionNum - 1) + "/properties.txt";
    fstream propertiesSrc(pathSrc, ios::in);
    if (!propertiesSrc.good())
        return false;
    propertiesSrc >> x >> x >> x;
    if (x == 0)
        return false;
    return true;
    // string pathDst = path + "partition" + to_string(partitionNum) + "dst" + to_string(i) + "/properties.txt";
}
struct Files
{
    fstream properties;
    fstream begin;
    fstream adj;
};

struct Props
{
    long long vertices;
    long long edges;
    Props()
    {
        vertices = 0;
        edges = 0;
    };
};

void graph::partitionAndStoreSrc(int num, string partitionedFolder, vector<int> part, vector<int> index, long long &maxEdges, long long &minEdges, int &maxVertives)
{
    partitionNumSrc = num;
    Files *files = new Files[num];
    Props *props = new Props[num];
    // open files of each subgraph
    for (int i = 0; i < partitionNumSrc; i++)
    {
        string prefix = partitionedFolder + to_string(partitionNumSrc) + "src" + to_string(i) + "/";
        mkdir(prefix.c_str(), S_IRWXU | S_IRWXG | S_IRWXO);
        files[i].properties.open(prefix + "properties.txt", ios::out);
        files[i].begin.open(prefix + "begin.bin", ios::out | ios::binary);
        files[i].adj.open(prefix + "adj.bin", ios::out | ios::binary);
    }
    // write the corresponding neighbors in the memory
    for (int i = 0; i < uCount + vCount; i++)
    {
        int n = part[i];
        files[n].begin.write((char *)&props[n].edges, sizeof(long long));
        props[n].edges += beginPos[i + 1] - beginPos[i];
        props[n].vertices++;
        files[n].adj.write((char *)&edgeList[beginPos[i]], sizeof(int) * (beginPos[i + 1] - beginPos[i]));
    }
    // write properties
    maxVertives = 0;
    maxEdges = 0;
    minEdges = props[0].edges;
    for (int n = 0; n < num; n++)
    {
        maxEdges = max(maxEdges, props[n].edges);
        minEdges = min(minEdges, props[n].edges);
        maxVertives = max(maxVertives, int(props[n].vertices));
        files[n].begin.write((char *)&props[n].edges, sizeof(long long));
        files[n].properties << 0 << " " << props[n].vertices << " " << props[n].edges << endl;
        files[n].properties.close();
        files[n].begin.close();
        files[n].adj.close();
    }

    delete[] files;
    delete[] props;
}

void graph::partitionAndStoreDst(int num, string partitionedFolder, vector<int> part, vector<int> index)
{
    partitionNumDst = num;
    Files *files = new Files[num];
    Props *props = new Props[num];
    // open file
    for (int i = 0; i < partitionNumDst; i++)
    {
        string prefix = partitionedFolder + to_string(partitionNumDst) + "dst" + to_string(i) + "/";
        mkdir(prefix.c_str(), S_IRWXU | S_IRWXG | S_IRWXO);
        files[i].properties.open(prefix + "properties.txt", ios::out);
        files[i].begin.open(prefix + "begin.bin", ios::out | ios::binary);
        files[i].adj.open(prefix + "adj.bin", ios::out | ios::binary);
    }
    vector<int> *a = new vector<int>[num];

    for (int i = 0; i < uCount + vCount; i++)
    {
        // record the neighbors
        for (auto j = beginPos[i]; j < beginPos[i + 1]; j++)
        {
            int dstVertex = edgeList[j];
            int n = part[dstVertex];
            a[n].push_back(dstVertex);
        }
        // put into files
        for (int n = 0; n < num; n++)
        {
            files[n].begin.write((char *)&props[n].edges, sizeof(long long));
            props[n].edges += a[n].size();
            props[n].vertices++;
            files[n].adj.write((char *)&a[n][0], sizeof(int) * (a[n].size()));
            a[n].clear();
        }
    }

    for (int n = 0; n < num; n++)
    {
        files[n].begin.write((char *)&props[n].edges, sizeof(long long));
        files[n].properties << 0 << " " << props[n].vertices << " " << props[n].edges << endl;
        files[n].properties.close();
        files[n].begin.close();
        files[n].adj.close();
    }

    delete[] files;
    delete[] props;
    delete[] a;
}
void graph::partitionAndStore(int num, string path, bool isInMemory, partitionOption option, parameter para)
{
    loadGraph(path);
    cout << "load graph ";
    for (;;)
    {

        srand(0);
        vector<int> part, index;
        vector<int> nextIndexOfPart(num);
        for (int i = 0; i < vertexCount; i++)
        {
            int p;
            switch (option)
            {
            case radixHash:
                p = i % num;
                break;
            case randomHash:
                p = rand() % num;
                break;
            case rangeHash:
                p = i / (vertexCount / num + 1);
            default:
                break;
            }
            part.push_back(p);
            index.push_back(nextIndexOfPart[p]);
            nextIndexOfPart[p]++;
        }
        long long maxEdges, minEdges;
        int maxVertices;
        partitionAndStoreSrc(num, path + "partition", part, index, maxEdges, minEdges, maxVertices);
        bool fitIntoMemory = false;
        if (para.varient == edgecentric)
        {
            long long size = (maxEdges * 2 + maxVertices * para.processorNum / para.batchNum) * sizeof(int);
            if (size < para.memorySize)
                fitIntoMemory = true;
        }
        if (para.varient == wedgecentric)
        {
            para.batchNum = ceil(2 * (maxEdges * sizeof(int)) / (para.memorySize - (long long)maxVertices * maxVertices * sizeof(int)));
            fitIntoMemory = true;
        }
        cout << para.memorySize << " " << maxVertices << " " << maxEdges << " " << minEdges << " " << maxEdges / double(minEdges) << endl;

        if (fitIntoMemory)
        {
            cout << "fited";
            partitionAndStoreDst(num, path + "partition", part, index);
            // creat index mapping
            for (int i = 0; i < num; i++)
                indexToRawId.push_back({});
            for (int i = 0; i < vertexCount; i++)
            {
                indexToRawId[part[i]].push_back(i);
            }
            indexToNewId.swap(index);
            cout << endl;
            cout << "final partiton: " << para.partitionNum << " batch:" << para.batchNum << endl;
            break;
        }
        else
        {
            cout << "not fited";
            cout << "final partiton: " << para.partitionNum << " batch:" << para.batchNum << endl;
            num = num * 1.5;
            para.partitionNum = num;
        }
    }
    delete[] edgeList;
    delete[] beginPos;
    edgeList = nullptr;
    beginPos = nullptr;
}
graph::graph()
{
    beginPos = nullptr;
    edgeList = nullptr;
    subEdgeListFirst = nullptr;
    subEdgeListSecond = nullptr;
    subBeginPosFirst = nullptr;
    subBeginPosSecond = nullptr;
}

graph::~graph()
{

    if (beginPos != nullptr)
        delete (beginPos);
    if (edgeList != nullptr)
        delete (edgeList);
    if (subEdgeListFirst != nullptr)
        delete[](subEdgeListFirst);
    if (subEdgeListSecond != nullptr)
        delete[](subEdgeListSecond);
    if (subBeginPosFirst != nullptr)
        delete[](subBeginPosFirst);
    if (subBeginPosSecond != nullptr)
        delete[](subBeginPosSecond);
}

void graph::partitionGraphSrc(int num)
{
    partitionNumSrc = num;
    subBeginPosFirst = new vector<long long>[num];
    subEdgeListFirst = new vector<int>[num];
    unique_ptr<long long[]> count{new long long[num]}; // record the edges in each partition
    for (int n = 0; n < num; n++)
        count[n] = 0;
    for (int i = 0; i < uCount + vCount; i++)
    {
        int n = i % num;
        subBeginPosFirst[n].push_back(count[n]);
        count[n] += beginPos[i + 1] - beginPos[i];
        for (auto j = beginPos[i]; j < beginPos[i + 1]; j++)
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
    vector<int> *a = new vector<int>[num * (uCount + vCount)];

    cout << endl
         << "inital a ";
    getProcessMemory();
    for (int i = 0; i < uCount + vCount; i++)
    {
        for (auto j = beginPos[i]; j < beginPos[i + 1]; j++)
        {
            int dstVertex = edgeList[j];
            int id = dstVertex % num;
            a[id * (uCount + vCount) + i].push_back(dstVertex);
        }
    }
    cout << "push a ";

    getProcessMemory();

    for (int n = 0; n < num; n++)
    {
        long long count = 0;
        for (int i = 0; i < uCount + vCount; i++)
        {
            subBeginPosSecond[n].push_back(count);
            count += a[n * (uCount + vCount) + i].size();
            vector<int> tmp;
            tmp.swap(a[n * (uCount + vCount) + i]);
            for (auto element : tmp)
                // for (auto element : a[n * (uCount + vCount) + i])
                subEdgeListSecond[n].push_back(element);
        }
        subBeginPosSecond[n].push_back(count);
    }
    cout << "before delete ";
    getProcessMemory();
    delete[] a;
}

void storeSubgraph(string prefix, vector<long long> &subBeginPos, vector<int> &subEdgeList)
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

string subgraphFold(string path, int partitionNum, int index, bool isSrc)
{
    string direction = isSrc ? "src" : "dst";
    return path + "partition" + to_string(partitionNum) + direction + to_string(index) + "/";
}
