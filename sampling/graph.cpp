#include "graph.h"
#include <string>
#include <fstream>
#include <iostream>
#include <algorithm>

using namespace std;

void graph::loadgraph(string path)
{
    fstream propertiesFile(path+"/properties.txt", ios::in);
    propertiesFile>>uCount>>vCount>>edgeCount;
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
}

void graph::loadWangkaiGraph(string path)
{

	printf( "Loading graph...\n" );
    FILE* fin = fopen( (path+"graph-sort.bin").c_str(), "rb" );
    int n;
    fread( &uCount, sizeof(int), 1, fin );
    fread( &n, sizeof(int), 1, fin );
    cout<<n<<endl;
    vCount=n-uCount;
    fread( &edgeCount, sizeof(long long), 1, fin );
    int* deg = new int[n],  **con = new int*[n], *nid = new int[n], *oid = new int[n];
    beginPos = new long long[uCount+vCount+1];
    edgeList = new int[edgeCount];
    fread( deg, sizeof(int), n, fin );
    fread( edgeList, sizeof(int), edgeCount, fin );
    fread( nid, sizeof(int), n, fin );
    fread( oid, sizeof(int), n, fin );
    fclose(fin);
    beginPos[0]=0;
    uCount--;
    vCount--;
    
    long long p = 0;
    for( int i = 0; i < n; ++i ) {con[i] = edgeList+p; p+=deg[i];beginPos[i+1]=p;}
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
    free(deg);
}