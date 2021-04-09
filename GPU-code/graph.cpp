#include "graph.h"
#include <string>
#include <fstream>
#include <iostream>
#include <algorithm>

using namespace std;
bool cmp1(int a, int b)
{
    return a>b ;
}

void graph::loadgraph(string path)
{
 printf( "Loading graph...\n" );
    fstream propertiesFile(path+"/properties.txt", ios::in);
    propertiesFile>>uCount>>vCount>>edgeCount;
    cout<<"properties: "<<uCount<<" "<<vCount<<" "<<edgeCount<<endl;
    edgeCount*=2;
    beginPos = new long long[uCount+vCount+1];
    edgeList = new int[edgeCount];
    propertiesFile.close();    
    fstream beginFile(path+"/begin.bin", ios::in|ios::binary);
    fstream adjFile(path+"/adj.bin", ios::in|ios::binary);
    beginFile.read((char*)beginPos,sizeof(long long)*(uCount+vCount+1));
    adjFile.read((char*)edgeList,sizeof(int)*(edgeCount));
    beginFile.close();
    adjFile.close();

    int* deg = new int[uCount+vCount];
    int n=uCount+vCount;
    for( int i = 0; i < uCount+vCount; ++i ) 
        deg[i]=beginPos[i+1]-beginPos[i];
    breakVertex10=lower_bound(deg,deg+n,10,cmp1)-deg;
    breakVertex32=lower_bound(deg,deg+n,32,cmp1)-deg;
    vertexCount=uCount+vCount;
    delete(deg);
}


void graph::loadWangkaiGraph(string path)
{

	 printf( "Loading wangkai graph...");
   cout<<path<<endl;
    fstream Fin(path+"graph-sort.bin", ios::in|ios::binary);
    Fin.read((char*)&uCount, sizeof(int));
    int n;
    Fin.read((char*)&n, sizeof(int));
    vCount=n-uCount;
    Fin.read((char*)&edgeCount, sizeof(long long));
    int* deg = new int[n],  **con = new int*[n], *nid = new int[n], *oid = new int[n];
    beginPos = new long long[uCount+vCount+1];
    edgeList = new int[edgeCount];
    Fin.read((char*)deg, sizeof(int)*n);
    Fin.read((char*)edgeList, sizeof(int)*edgeCount);
    Fin.read((char*)nid, sizeof(int)*n);
    Fin.read((char*)oid, sizeof(int)*n);

    Fin.close();
    // auto xx=upper_bound(deg,deg+n,10,cmp1);
    // breakVertex10=distance(deg,xx);
    int ppp=0;
    for (int i=1;i<n;i++)
    {
        if (deg[i]<deg[i+1]) ppp=1;
    }
    if (ppp) cout<<path<<" this dataset is not sorted"<<endl; else cout<<path<<" this dataset is sorted"<<endl;
    beginPos[0]=0;
    uCount--;
    vCount--;
    long long p = 0;
    for( int i = 0; i < n; ++i ) {
        // con[i] = edgeList+p; 
        p+=deg[i];beginPos[i+1]=p;}
    // if( is_original ) {
    //     printf( "obtaining original graph...\n" );
        // for( int i = 0; i < n; ++i ) {
        //     for( int j = 0; j < deg[i]; ++j ) con[i][j] = nid[con[i][j]];
        //         sort(con[i], con[i] + deg[i]);
        // }
    // }
    // for( int i = 0; i < n-1; ++i ) {
    //     // cout<<deg[i]<<' '<<nid[i]<<' '<<oid[i]<<endl;
    //     cout<<dd[i].degree<<' '<<dd[i].newid<<endl;
    //     // if (dd[i+1].newid-dd[i].newid!=1) cout<<dd[i].newid<<endl;
    //     // for( int j = 0; j < deg[i]; ++j ) cout<<con[i][j]<<' ';
    // }
    // printf( "%s: n=%d,n1=%d,m=%lld\n", path.c_str(), n, n1, m );
    
    breakVertex10=lower_bound(deg,deg+n,10,cmp1)-deg;
    breakVertex32=lower_bound(deg,deg+n,32,cmp1)-deg;
    vertexCount=uCount+vCount;
    delete(deg);
    delete(con);
    delete(oid);
    delete(nid);
}
graph::~graph()
{
    delete(beginPos);
    delete(edgeList);
}