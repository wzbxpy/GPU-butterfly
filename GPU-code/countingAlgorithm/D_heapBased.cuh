#ifndef D_HEAPBASED_H
#define D_HEAPBASED_H

__global__ 
void D_heapBasedButterflyCounting(long long *beginPos, int *edgeList, int *Sorted_NB, int total_size,int num_srT, int num_frT, int uCount, int vCount, unsigned long long* globalCount, int* perVertexCount, int* hashTable, int startVertex, int endVertex);
#endif