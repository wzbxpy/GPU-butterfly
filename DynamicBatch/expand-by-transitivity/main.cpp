#include <iostream>
#include <fstream>
#include "../graph.h"
#include <string>
#include <cstdlib>
#include <cstdio>
#include <atomic>
#include <thread>
#include <cmath>
#include <unistd.h>
#include <set>
#include <unordered_set>
#include <algorithm>
#include "../wtime.h"
double alpha = 0.1;

using namespace std;
struct node
{
    int id;
    int degree;
};
bool cmp_degree(struct node a, struct node b)
{
    return (a.degree > b.degree) || (a.degree == b.degree && a.id < b.id);
}

void sortAndStore(int vertexCount, vector<vector<int>> b, string path)
{
    double startTime = wtime();
    struct node *idDegree = new struct node[vertexCount];
    for (int i = 0; i < vertexCount; i++)
    {
        idDegree[i].id = i;
        idDegree[i].degree = b[i].size();
    }
    sort(idDegree, idDegree + vertexCount, cmp_degree);
    unique_ptr<int[]> newid(new int[vertexCount]);
    for (int i = 0; i < vertexCount; i++)
    {
        newid[idDegree[i].id] = i;
    }
    cout << "reorder over " << getDeltaTime(startTime) << endl;
    for (int i = 0; i < vertexCount; i++)
    {
        for (auto &dst : b[i])
            dst = newid[dst];
        sort(b[i].begin(), b[i].end());
    }
    cout << "sort neighbor over " << getDeltaTime(startTime) << endl;
    ofstream beginFile(path + "/begin.bin", ios::out | ios::binary);
    ofstream adjFile(path + "/adj.bin", ios::out | ios::binary);
    long long sum = 0;
    for (int i = 0; i < vertexCount; i++)
    {
        int vertex = idDegree[i].id;
        beginFile.write((char *)&sum, sizeof(long long));
        sum += idDegree[i].degree;
        adjFile.write((char *)&b[vertex][0], sizeof(int) * idDegree[i].degree);
    }
    beginFile.write((char *)&sum, sizeof(long long));
    ofstream propertiesFile(path + "/properties.txt", ios::out);
    cout << sum / vertexCount << endl;
    propertiesFile << 0 << ' ' << vertexCount << ' ' << sum << endl;
    beginFile.close();
    adjFile.close();
    propertiesFile.close();

    cout << "write file over " << getDeltaTime(startTime) << endl;
}

void expend(vector<vector<int>> &old, vector<vector<int>> &now, int threadId, int threadNum)
{
    bool *tmp = new bool[old.size()];
    for (int i = 0; i < old.size(); i++)
        tmp[i] = true;
    for (int u = threadId; u < old.size(); u += threadNum)
    {
        now[u].clear();
        tmp[u] = false;
        for (auto v : old[u])
        {
            if (tmp[v])
            {
                tmp[v] = false;
                now[u].push_back(v);
            }
            for (auto w : old[v])
                if (tmp[w])
                {
                    tmp[w] = false;
                    now[u].push_back(w);
                }
        }
        for (auto v : now[u])
            tmp[v] = true;
        tmp[u] = true;
    }
    delete[] tmp;
}

int main(int argc, char *argv[])
{
    string path, storePath;
    if (argc > 1)
    {
        path = argv[1];
        storePath = path;
    }
    if (argc > 2)
    {
        storePath = argv[2];
    }
    int threadNum = 112;
    if (argc > 3)
    {
        threadNum = atoi(argv[3]);
    }
    graph *G = new graph;
    G->loadGraph(path);
    long long count = 0;
    vector<vector<int>> old, now;
    for (int i = 0; i < G->vertexCount; i++)
    {
        vector<int> tmp(G->edgeList + G->beginPos[i], G->edgeList + G->beginPos[i + 1]);
        old.push_back(move(tmp));
        now.push_back({});
    }
    double time = wtime();
    thread threads[threadNum];
    for (int threadId = 0; threadId < threadNum; threadId++)
        threads[threadId] = thread(expend, ref(old), ref(now), threadId, threadNum);
    for (auto &t : threads)
        t.join();
    sortAndStore(G->vertexCount, now, storePath);
    // cout << G->vertexCount << " " << G->edgeCount << " " << count << " " << count / G->vertexCount << endl;
    // for (int threadId = 0; threadId < threadNum; threadId++)
    //     threads[threadId] = thread(expend, ref(now), ref(old), threadId, threadNum);
    // for (auto &t : threads)
    //     t.join();
    // count = 0;
    // cout << getDeltaTime(time) << endl;
    // for (auto &x : old)
    //     // count = count + pow(x.size(), 2);
    //     count += x.size();
    // cout << G->vertexCount << " " << G->edgeCount << " " << count << " " << count / G->vertexCount << endl;
    delete (G);
    return 0;
}