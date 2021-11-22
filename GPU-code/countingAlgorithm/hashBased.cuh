#ifndef HASHBASED
#define HASHBASED

__global__ void hashBasedButterflyCounting(long long *beginPos, int *edgeList, int uCount, int vCount, unsigned long long *globalCount, int *perVertexCount, int *hashTable, int startVertex, int endVertex, int *nextVertex);

#endif