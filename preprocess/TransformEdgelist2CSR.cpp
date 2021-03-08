#include <iostream>
#include <algorithm>
#include <fstream>
#include <cstdio>
#include <vector>
#include <sstream> 
#include <string>
#include <cmath>
#include <map>

using namespace std;

struct edge_list
{
    vector<int> edge;
};
vector<edge_list> vertex;

struct edge
{
    int u,v;
};
vector<edge> edgelist;

int uCount=0, vCount=0, uMax=0, vMax=0, edgeCount;
// map<int,int> uMap,vMap;

bool cmp(int a,int b)
{
    return a>b;
}

void loadgraph(string filename)
{
    ifstream inFile(filename.c_str(), ios::in);
    if(!inFile) {
        cout << "error" <<endl;
        // return 0;
    }
    int x;
    int p=0;
    string line;
    stringstream ss;
    while(getline( inFile, line ))
	{
		if(line[0] < '0' || line[0] > '9')
			continue;
        ss.str("");
        ss.clear();
        ss << line;
        edge e;
        ss>>e.u>>e.v;
        e.u--;e.v--;
        edgelist.push_back(e);
        if (e.u>uMax) uMax=e.u;
        if (e.v>vMax) vMax=e.v;
    }
}
void deleteNoneNeighborVertex()
{
    int *uMap=new int[uMax+10];
    int *vMap=new int[vMax+10];
    
    for (int i=0;i<=uMax;i++)
    {
        uMap[i]=0;
    }
    for (int i=0;i<=vMax;i++)
    {
        vMap[i]=0;
    }
    for (int i=0;i<edgelist.size();i++)
    {
        uMap[edgelist[i].u]=1;
        vMap[edgelist[i].v]=1;
    }
    for (int i=0;i<=uMax;i++)
    {
        if (uMap[i]) 
        {
            uMap[i]=uCount;
            uCount++;
        }
    }
    for (int i=0;i<=vMax;i++)
    {
        if (vMap[i]) 
        {
            vMap[i]=vCount;            
            vCount++;
        }
    }
    vertex.resize(uCount+vCount+1);
    for (int i=0;i<edgelist.size();i++)
    {
        int u=uMap[edgelist[i].u];
        int v=vMap[edgelist[i].v]+uCount;
        vertex[u].edge.push_back(v);
    }
}
void deleteDuplicateEdge()
{
    edgeCount=0;
    for (int i = 0; i <= uCount; i++)
    {
        vector <int> x;
        x.swap(vertex[i].edge);
        sort(x.begin(),x.end(),cmp);
        int p=0,v=-1;
        while (!x.empty())
        {
            while (!x.empty()&&v==x.back())
            {
                x.pop_back();
            }
            if (x.empty()) break;
            v=x.back();
            x.pop_back();
            vertex[i].edge.push_back(v);
        }
        edgeCount+=vertex[i].edge.size();
    }
}
void addTwoDirectionEdge()
{
    for (int i = 0; i < uCount; i++)
    {
        int u=i;
        for (int j=0;j<vertex[i].edge.size();j++)
        {
            int v=vertex[i].edge[j];
            vertex[v].edge.push_back(u);
        }
    }
}
void storeGraphInCSR(string filename)
{
    ofstream beginFile(filename+"/begin.bin", ios::out|ios::binary);
    ofstream adjFile(filename+"/adj.bin", ios::out|ios::binary);
    long long sum=0;
    for (int i = 0; i < uCount+vCount; i++)
    {
        beginFile.write((char*)&sum,sizeof(long long));
        sum += vertex[i].edge.size();
        cout<<sum<<endl;
        adjFile.write((char*)&vertex[i].edge[0],sizeof(int)*vertex[i].edge.size());
    }
    beginFile.write((char*)&sum,sizeof(long long));
    ofstream propertiesFile(filename+"/properties.txt", ios::out);
    propertiesFile<<uCount<<' '<<vCount<<' '<<edgeCount<<endl;
}

int main(int argc, char* argv[])
{
    string Infilename="1.mmio";
    string Outfilename="1.txt";
    if (argc>1)
    {
        Infilename=argv[1];
    }
    if (argc>2)
    {
        Outfilename=argv[2];
    }
    loadgraph(Infilename);
    cout<<edgelist.size()<<endl;
    deleteNoneNeighborVertex();
    deleteDuplicateEdge();
    cout<<edgeCount<<endl;
    addTwoDirectionEdge();
    storeGraphInCSR(Outfilename);
}