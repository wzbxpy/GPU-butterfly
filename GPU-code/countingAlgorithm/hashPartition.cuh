#ifndef HASHPARTITION
#define HASHPARTITION

__global__ void hashPartition(long long *beginPosFirst, int *edgeListFirst, long long *beginPosSecond, int *edgeListSecond, unsigned long long *globalCount, int *perVertexCount, int *hashTable, int startVertex, int endVertex, int length, int partitionNum);
#endif