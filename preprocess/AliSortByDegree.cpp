#include <string>
#include <fstream>
#include <iostream>
#include <algorithm>
#include <vector>
#include <memory>
#include <cmath>
#include <unordered_map>

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
void removeDuplicatedEdgeAndSelfLoop(vector<vector<int>> &b)
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
int find(unordered_map<long long, int> &map, long long key)
{
    if (map.find(key) != map.end())
    {
        return map[key];
    }
    else
    {
        map[key] = map.size();
        return map[key];
    }
}

void loadGeneratedGraph(string path)
{
    long long vertexpower, degree;
    vector<vector<int>> b;
    unordered_map<long long, int> left, right;

    fstream filename(path + "filenames.txt", ios::in);
    string name;
    while (filename >> name)
    {
        fstream graphFile(path + name, ios::in);
        long long u, v;
        string s;
        while (getline(graphFile, s, ','))
        {
            u = stoll(s);
            getline(graphFile, s);
            v = stoll(s);
            u = find(left, u);
            v = find(right, v);
            if (b.size() <= u)
                b.resize(u + 1);
            b[u].push_back(v);
        }
    }
    cout << "here" << endl;
    vertexCount = left.size() + right.size();
    b.resize(vertexCount);
    cout << "here" << endl;

    for (auto i = 0; i < left.size(); i++)
        for (auto &neighbor : b[i])
        {
            neighbor += left.size();
            b[neighbor].push_back(i);
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

    loadGeneratedGraph(path);
}