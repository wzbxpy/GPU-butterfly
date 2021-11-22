#ifndef HEAPBASED_H
#define HEAPBASED_H

__global__ void heapBasedButterflyCounting(long long *beginPos, int *edgeList, int uCount, int vCount, unsigned long long *globalCount, int *perVertexCount, int *hashTable, int startVertex, int endVertex);

__global__ void heapBasedButterflyCounting_byWarp(long long *beginPos, int *edgeList, int uCount, int vCount, unsigned long long *globalCount, int *perVertexCount, int *hashTable, int startVertex, int endVertex);

#endif