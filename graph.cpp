#include "graph.h"
#include <string>
#include <fstream>
#include <iostream>

using namespace std;

void graph::loadgraph(string folderName)
{
    fstream propertiesFile(folderName+"/properties.txt", ios::in);
    propertiesFile>>uCount>>vCount>>edgeCount;
    edgeCount*=2;
    beginPos = new long long[uCount+vCount+1];
    edgeList = new int[edgeCount];
    propertiesFile.close();    
    fstream beginFile(folderName+"/begin.bin", ios::in|ios::binary);
    fstream adjFile(folderName+"/adj.bin", ios::in|ios::binary);
    beginFile.read((char*)beginPos,sizeof(long long)*(uCount+vCount+1));
    adjFile.read((char*)edgeList,sizeof(int)*(edgeCount));
    beginFile.close();
    adjFile.close();
}