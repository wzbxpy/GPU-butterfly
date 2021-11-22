#include "graph.h"
#include <string>
#include <fstream>
#include <iostream>
#include <algorithm>
#include <string.h>
using namespace std;
bool cmp1(int a, int b)
{
    return a>b ;
}

void graph::loadgraph(string path,int bound)
{
    printf( "Loading graph " );
    cout << path << endl;
    fstream propertiesFile(path+"/properties.txt", ios::in);
    propertiesFile>>uCount>>vCount>>edgeCount;
    cout<<"properties: "<<uCount<<" "<<vCount<<" "<<edgeCount<<endl;
    edgeCount*=2;
    beginPos1 = new long long[uCount+vCount+1];
    beginPos = new int [uCount + vCount + 1];
    edgeList = new int[edgeCount];
    vertexCount = uCount + vCount;
    propertiesFile.close();   
    fstream beginFile(path+"/begin.bin", ios::in|ios::binary);
    fstream adjFile(path+"/adj.bin", ios::in|ios::binary);
    beginFile.read((char*)beginPos1,sizeof(long long)*(uCount+vCount+1));
    adjFile.read((char*)edgeList,sizeof(int)*(edgeCount));
    beginFile.close();
    adjFile.close();
    cout << "start!" << endl;
}



graph::~graph()
{
    delete(beginPos);
    delete(edgeList);
}