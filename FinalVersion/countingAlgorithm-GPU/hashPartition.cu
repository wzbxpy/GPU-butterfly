#include <iostream>
#include <cooperative_groups.h>
#include <cooperative_groups/memcpy_async.h>
#include <cooperative_groups/reduce.h>
// #include <cooperative_groups/scan.h>
using namespace std;
using namespace cooperative_groups;
// #define subgroupSize 32
#define dynamic_scheduling

__global__ void hashPartition(long long *beginPosFirst, int *edgeListFirst, long long *beginPosSecond, int *edgeListSecond, unsigned long long *globalCount, int *perVertexCount, int *hashTable, int startVertex, int endVertex, int length, int partitionNum, int vertexOffsets, int *nextVertex)
{
    __shared__ unsigned long long sharedCount;
#ifdef dynamic_scheduling
    __shared__ int nextVertexshared;
#endif
    if (threadIdx.x == 0)
        sharedCount = 0;
    unsigned long long count = 0;
    for (int i = threadIdx.x + blockIdx.x * (length); i < (1 + blockIdx.x) * (length); i += blockDim.x)
    {
        hashTable[i] = 0;
    }
    __syncthreads();

#ifdef dynamic_scheduling
    for (int vertex = startVertex + blockIdx.x; vertex < endVertex;)
    {
        if (threadIdx.x == 0)
            nextVertexshared = atomicAdd(nextVertex, 1);
        __syncthreads();
        vertex = nextVertexshared;
#else
    for (int vertex = startVertex + blockIdx.x; vertex < endVertex; vertex += gridDim.x)
    {
#endif
        int vertexDegree = beginPosFirst[vertex + 1] - beginPosFirst[vertex];

        // put the two hop neighbor of vertex into hash map

        for (int oneHopNeighborID = beginPosFirst[vertex] + threadIdx.x / 32; oneHopNeighborID < beginPosFirst[vertex + 1]; oneHopNeighborID += 32)
        {
            int oneHopNeighbor = edgeListFirst[oneHopNeighborID];
            int bound = vertex * partitionNum + vertexOffsets < oneHopNeighbor ? vertex * partitionNum + vertexOffsets : oneHopNeighbor;
            for (int twoHopNeighborID = beginPosSecond[oneHopNeighbor] + threadIdx.x % 32; twoHopNeighborID < beginPosSecond[oneHopNeighbor + 1]; twoHopNeighborID += 32)
            {
                int twoHopNeighbor = edgeListSecond[twoHopNeighborID];
                if (twoHopNeighbor >= bound)
                    break;
                count += atomicAdd(&hashTable[(twoHopNeighbor / partitionNum) + blockIdx.x * (length)], 1);
            }
        }
        // thisBlock.sync();
        // this_thread_block().sync();
        __syncthreads();
        // if (threadIdx.x + blockIdx.x == 0)
        //     printf("%d thread num\n", thisBlock.size());

        // reset the hash map
        if (vertexDegree * vertexDegree > length) //choose the lower costs method
        // if (1)
        {
            int start = 0, end = length;
            start += blockIdx.x * (length), end += blockIdx.x * (length);
            for (int i = start + threadIdx.x; i < end; i += blockDim.x)
            {
                hashTable[i] = 0;
            }
        }
        else
        {
            for (int oneHopNeighborID = beginPosFirst[vertex] + threadIdx.x / 32; oneHopNeighborID < beginPosFirst[vertex + 1]; oneHopNeighborID += 32)
            {
                int oneHopNeighbor = edgeListFirst[oneHopNeighborID];
                int bound = vertex * partitionNum + vertexOffsets < oneHopNeighbor ? vertex * partitionNum + vertexOffsets : oneHopNeighbor;
                for (int twoHopNeighborID = beginPosSecond[oneHopNeighbor] + threadIdx.x % 32; twoHopNeighborID < beginPosSecond[oneHopNeighbor + 1]; twoHopNeighborID += 32)
                {
                    int twoHopNeighbor = edgeListSecond[twoHopNeighborID];
                    if (twoHopNeighbor >= bound)
                        break;
                    hashTable[(twoHopNeighbor / partitionNum) + blockIdx.x * (length)] = 0;
                }
            }
        }
        __syncthreads();
        // this_thread_block().sync();
    }

    atomicAdd(&sharedCount, count);
    __syncthreads();
    if (threadIdx.x == 0)
        atomicAdd(globalCount, sharedCount);
}