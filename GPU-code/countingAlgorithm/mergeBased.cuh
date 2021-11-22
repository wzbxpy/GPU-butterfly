#ifndef MERGEBASED_H
#define MERGEBASED_H

__global__ void mergeBasedButterflyCounting(long long *beginPos, int *edgeList, int uCount, int vCount, unsigned long long *globalCount, int *perVertexCount, int *hashTable, int startVertex, int endVertex);

#endif