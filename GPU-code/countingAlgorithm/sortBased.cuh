#ifndef SORTBASED_H
#define SORTBASED_H

__global__ 
void sortBasedButterflyCounting(long long *beginPos, int *edgeList, int uCount, int vCount, unsigned long long* globalCount, int* perVertexCount, int* hashTable, int startVertex, int endVertex);

#endif