#ifndef HASHCENTRIC
#define HASHCENTRIC

__global__ void hashCentric(long long *beginPosFirst, int *edgeListFirst, long long *beginPosSecond, int *edgeListSecond, unsigned long long *globalCount, int *hashTable, int startVertex, int endVertex, int length, int partitionNum);

__global__ void clearHashTable(int *hashTable, int length);
#endif