#include <string>
#include <fstream>
#include <iostream>
#include <algorithm>

using namespace std;


long long* beginPos;
int* edgeList;
int* deg;
int uCount,vCount,breakVertex32,breakVertex10;
long long edgeCount;
bool cmp1(int a, int b)
{
    return a>b ;
}
struct node
{
    int id;
    int degree;
};
struct node* nnn;
bool cmp_degree(struct node a, struct node b)
{
    return (a.degree>b.degree)||(a.degree==b.degree&&a.id<b.id);
}


void loadWangkaiGraph(string path)
{

    fstream Fin(path+"graph-sort.bin", ios::in|ios::binary);
    Fin.read((char*)&uCount, sizeof(int));
    int n;
    Fin.read((char*)&n, sizeof(int));
    vCount=n-uCount;
    Fin.read((char*)&edgeCount, sizeof(long long));
    int   **con = new int*[n], *nid = new int[n], *oid = new int[n];
    deg = new int[n];
    beginPos = new long long[uCount+vCount+1];
    edgeList = new int[edgeCount];
    Fin.read((char*)deg, sizeof(int)*n);
    Fin.read((char*)edgeList, sizeof(int)*edgeCount);
    Fin.read((char*)nid, sizeof(int)*n);
    Fin.read((char*)oid, sizeof(int)*n);

    Fin.close();

    beginPos[0]=0;
    uCount--;
    vCount--;
    long long p = 0;
    for( int i = 0; i < n; ++i ) {
        // con[i] = edgeList+p; 
        p+=deg[i];beginPos[i+1]=p;}
    delete(con);
    delete(oid);
    delete(nid);
}

void sortbydegree()
{
    int n=uCount+vCount;
    nnn=new struct node[n];
    for (int i=0;i<n;i++)
    {
        nnn[i].id=i;
        nnn[i].degree=deg[i];
    }
    sort(nnn,nnn+n-2,cmp_degree);
}
void storeCSR(string path)
{
    int *a=new int[uCount+vCount];
    
    for (int i = 0; i < uCount+vCount; i++)
    {
        a[nnn[i].id]=i;
    }
    
    //give each edge new id
    for (int i=0;i<edgeCount;i++)
        edgeList[i]=a[edgeList[i]];
    ofstream beginFile(path+"/begin.bin", ios::out|ios::binary);
    ofstream adjFile(path+"/adj.bin", ios::out|ios::binary);
    // beginFile.write((char*)beginPos,sizeof(long long)*(uCount+vCount+1));
    // adjFile.write((char*)edgeList,sizeof(int)*(edgeCount));
    long long sum=0;
    for (int i = 0; i < uCount+vCount; i++)
    {
        int vertex=nnn[i].id;
        beginFile.write((char*)&sum,sizeof(long long));
        int degree=beginPos[vertex+1]-beginPos[vertex];
        sum += degree;
        adjFile.write((char*)&edgeList[beginPos[vertex]],sizeof(int)*degree);
    }
    beginFile.write((char*)&sum,sizeof(long long));
    ofstream propertiesFile(path+"/properties.txt", ios::out);
    propertiesFile<<uCount<<' '<<vCount<<' '<<edgeCount<<endl;
}
int main(int argc, char* argv[])
{
    string path;
    if (argc>1)
    {
        path=argv[1];
    }
    cout<<path<<endl;
    loadWangkaiGraph(path);
    sortbydegree();
    storeCSR(path+"sorted");
}