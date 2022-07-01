#include <string>
#include <fstream>
#include <iostream>
#include <algorithm>
#include <vector>
#include <memory>
#include <cmath>

using namespace std;

long long *beginPos;
int *edgeList;
int *deg;
int uCount, vCount, breakVertex32, breakVertex10, vertexCount;
long long edgeCount;
bool cmp1(int a, int b)
{
    return a > b;
}
struct node
{
    int id;
    int degree;
};
struct node *nnn;
bool cmp_degree(struct node a, struct node b)
{
    return (a.degree > b.degree) || (a.degree == b.degree && a.id < b.id);
}
void removeDuplicatedEdgeAndSelfLoop(shared_ptr<vector<int>[]> b)
{
    for (int i = 0; i < vertexCount; i++)
    {
        sort(b[i].begin(), b[i].end());
        vector<int> a;
        int previous = -1;
        for (auto item : b[i])
        {
            if (item != previous)
            {
                previous = item;
                if (item != i)
                    a.push_back(item);
            }
        }
        b[i].swap(a);
    }
}
void printb(shared_ptr<vector<int>[]> b)
{
    for (int i = 0; i < vertexCount; i++)
    {
        cout << i << ":";
        for (auto dst : b[i])
            cout << dst << ' ';
        cout << endl;
    }
}

void loadEdgeList(string path)
{
    fstream edgeListFile(path, ios::in);
    long long vertexpower, degree;
    // edgeListFile >> vertexpower >> degree;
    // vertexCount = powl(2, vertexpower);
    // edgeCount = degree * vertexCount;
    edgeListFile >> vertexCount >> vertexCount >> edgeCount;
    cout << vertexCount << " " << edgeCount << endl;
    path = path.substr(0, path.rfind('/'));

    shared_ptr<vector<int>[]> b(new vector<int>[vertexCount]);
    for (int i = 0; i < edgeCount; i++)
    {
        int u, v;
        edgeListFile >> u >> v;
        u--;
        v--;
        // cout << u << " " << v << endl;
        b[u].push_back(v);
        b[v].push_back(u);
    }

    removeDuplicatedEdgeAndSelfLoop(b);
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
    for (int i = 0; i < vertexCount; i++)
    {
        for (auto &dst : b[i])
            dst = newid[dst];
        sort(b[i].begin(), b[i].end());
    }
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
    propertiesFile << 0 << ' ' << vertexCount << ' ' << sum << endl;
    beginFile.close();
    adjFile.close();
    propertiesFile.close();
}

void loadGeneratedGraph(string path)
{
    fstream propertiesInFile(path + "/properties1.txt", ios::in);
    long long vertexpower, degree;
    // propertiesInFile >> vertexpower >> degree;
    // vertexCount = powl(2, vertexpower);
    // edgeCount = degree * vertexCount;
    propertiesInFile >> vertexCount >> edgeCount;
    propertiesInFile.close();
    unique_ptr<uint32_t[]> a(new uint32_t[edgeCount * 2]);
    fstream file(path + "/edgelist", ios::in | ios::binary);
    file.read((char *)&a[0], sizeof(uint32_t) * (edgeCount)*2);
    file.close();

    shared_ptr<vector<int>[]> b(new vector<int>[vertexCount]);
    for (int i = 0; i < edgeCount; i++)
    {
        int u = a[i * 2], v = a[i * 2 + 1];
        b[u].push_back(v);
        b[v].push_back(u);
    }

    removeDuplicatedEdgeAndSelfLoop(b);
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
    for (int i = 0; i < vertexCount; i++)
    {
        for (auto &dst : b[i])
            dst = newid[dst];
        sort(b[i].begin(), b[i].end());
    }
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
    propertiesFile << 0 << ' ' << vertexCount << ' ' << sum << endl;
    beginFile.close();
    adjFile.close();
    propertiesFile.close();
}

void loadWangkaiGraph(string path)
{

    fstream Fin(path + "graph-sort.bin", ios::in | ios::binary);
    Fin.read((char *)&uCount, sizeof(int));
    int n;
    Fin.read((char *)&n, sizeof(int));
    vCount = n - uCount;
    Fin.read((char *)&edgeCount, sizeof(long long));
    int **con = new int *[n], *nid = new int[n], *oid = new int[n];
    deg = new int[n];
    beginPos = new long long[uCount + vCount + 1];
    edgeList = new int[edgeCount];
    Fin.read((char *)deg, sizeof(int) * n);
    Fin.read((char *)edgeList, sizeof(int) * edgeCount);
    Fin.read((char *)nid, sizeof(int) * n);
    Fin.read((char *)oid, sizeof(int) * n);

    Fin.close();

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
    delete (con);
    delete (oid);
    delete (nid);
    vertexCount = uCount + vCount;
}

void sortbydegree()
{
    int n = vertexCount;
    nnn = new struct node[n];
    for (int i = 0; i < n; i++)
    {
        nnn[i].id = i;
        nnn[i].degree = deg[i];
    }
    sort(nnn, nnn + n, cmp_degree);
}
void storeCSR(string path)
{
    int *a = new int[vertexCount];

    for (int i = 0; i < vertexCount; i++)
    {
        a[nnn[i].id] = i;
    }

    // give each edge new id
    for (int i = 0; i < edgeCount; i++)
        edgeList[i] = a[edgeList[i]];
    ofstream beginFile(path + "/begin.bin", ios::out | ios::binary);
    ofstream adjFile(path + "/adj.bin", ios::out | ios::binary);
    // beginFile.write((char*)beginPos,sizeof(long long)*(uCount+vCount+1));
    // adjFile.write((char*)edgeList,sizeof(int)*(edgeCount));
    long long sum = 0;
    for (int i = 0; i < vertexCount; i++)
    {
        int vertex = nnn[i].id;
        beginFile.write((char *)&sum, sizeof(long long));
        int degree = beginPos[vertex + 1] - beginPos[vertex];
        sum += degree;
        adjFile.write((char *)&edgeList[beginPos[vertex]], sizeof(int) * degree);
    }
    beginFile.write((char *)&sum, sizeof(long long));
    ofstream propertiesFile(path + "/properties.txt", ios::out);
    propertiesFile << uCount << ' ' << vCount << ' ' << edgeCount << endl;
}
int main(int argc, char *argv[])
{
    string path;
    if (argc > 1)
    {
        path = argv[1];
    }
    bool isGenerated = false;
    if (argc > 2)
    {
        isGenerated = atoi(argv[2]) > 0;
    }
    cout << path << endl;
    if (isGenerated)
    {
        loadGeneratedGraph(path);
    }
    else
    {
        cout << "here" << endl;
        // loadWangkaiGraph(path);
        // sortbydegree();
        // storeCSR(path + "sorted");
        loadEdgeList(path);
    }
}