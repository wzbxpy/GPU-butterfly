#include <string>
#include <fstream>
#include <iostream>
#include <algorithm>
#include <vector>
#include <memory>
#include <queue>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/time.h>

using namespace std;
bool cmp1(int a, int b)
{
    return a > b;
}
double wtime()
{
    double time[2];
    struct timeval time1;
    gettimeofday(&time1, NULL);

    time[0] = time1.tv_sec;
    time[1] = time1.tv_usec;

    return time[0] + time[1] * 1.0e-6;
}

double getDeltaTime(double &startTime)
{
    double deltaTime = wtime() - startTime;
    startTime = wtime();
    return deltaTime;
}

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
    ~graph();
};

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
    beginFile.read((char *)beginPos, sizeof(long long) * (vertexCount + 1));
    beginFile.close();
}

double graph::loadGraph(string path)
{
    // cout << "Loading graph..." << path << endl;
    double startTime = clock();
    loadBeginPos(path);
    if (edgeList == nullptr)
        edgeList = new int[edgeCount];
    fstream adjFile(path + "/adj.bin", ios::in | ios::binary);
    adjFile.read((char *)edgeList, sizeof(int) * (edgeCount));
    adjFile.close();
    double time = (clock() - startTime) / CLOCKS_PER_SEC;
    return time;
}

int main(int argc, char *argv[])
{
    string path;
    if (argc > 1)
    {
        path = argv[1];
    }
    graph *G = new graph;
    G->loadGraph(path);
    int VC = G->vertexCount;
    cout << VC << endl;
    int p[2] = {0, 1}; // next vertex id
    int *a = new int[VC];
    for (int i = 0; i < VC; i++)
    {
        a[i] = -1;
    }
    queue<int> Q;
    int nextVertex = 0;
    fstream edgelistFile(path + "/edgelist.txt", ios::out);
    cout << "here" << endl;
    while ((p[0] + p[1]) / 2 < VC)
    {
        if (Q.empty())
        {
            while (a[nextVertex] != -1)
            {
                nextVertex++;
            }
            Q.push(nextVertex);
            a[0] = p[0];
            p[0] += 2;
        }
        int u = Q.front();
        int &nextId = p[(a[u] + 1) % 2];
        Q.pop();
        for (int i = G->beginPos[u]; i < G->beginPos[u + 1]; i++)
        {
            int v = G->edgeList[i];
            if (a[v] == -1)
            {
                a[v] = nextId;
                nextId += 2;
                Q.push(v);
            }
        }
    }
    cout << "here" << endl;
    for (int u = 0; u < VC; u++)
    {
        if (a[u] % 2)
            continue;
        for (int i = G->beginPos[u]; i < G->beginPos[u + 1]; i++)
        {
            int v = G->edgeList[i];
            edgelistFile << a[u] / 2 + 1 << ' ' << a[v] / 2 + 1 << endl;
        }
    }
    edgelistFile.close();
}