#include <iostream>
#include <cub/cub.cuh>
#include <cub/util_type.cuh>
using namespace std;

__device__ void hashBasedPerVertexWithPartition(int vertex, long long *beginPosFirst, int *edgeListFirst, long long *beginPosSecond, long long *endPosSecond, int *edgeListSecond, int *hashTable, int length, unsigned long long *count, int partitionNum, int decNum)
{
    int vertexDegree = beginPosFirst[vertex + 1] - beginPosFirst[vertex];

    // put the two hop neighbor of vertex into hash map
    for (int oneHopNeighborID = beginPosFirst[vertex] + threadIdx.x / 32; oneHopNeighborID < beginPosFirst[vertex + 1]; oneHopNeighborID += 32)
    {
        int oneHopNeighbor = edgeListFirst[oneHopNeighborID];
        int bound = vertex < oneHopNeighbor ? vertex : oneHopNeighbor;
        for (int twoHopNeighborID = beginPosSecond[oneHopNeighbor] + threadIdx.x % 32; twoHopNeighborID < beginPosSecond[oneHopNeighbor + 1]; twoHopNeighborID += 32)
        {
            int twoHopNeighbor = edgeListSecond[twoHopNeighborID];
            if (twoHopNeighbor >= bound)
                break;
            *count += atomicAdd(&hashTable[(twoHopNeighbor / partitionNum) - decNum + blockIdx.x * (length)], 1);
        }
    }
    __syncthreads();

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
            int bound = vertex < oneHopNeighbor ? vertex : oneHopNeighbor;
            for (int twoHopNeighborID = beginPosSecond[oneHopNeighbor] + threadIdx.x % 32; twoHopNeighborID < beginPosSecond[oneHopNeighbor + 1]; twoHopNeighborID += 32)
            {
                int twoHopNeighbor = edgeListSecond[twoHopNeighborID];
                if (twoHopNeighbor >= bound)
                    break;
                hashTable[(twoHopNeighbor / partitionNum) - decNum + blockIdx.x * (length)] = 0;
            }
        }
    }
    __syncthreads();
}

__global__ void hashPartition(long long *beginPosFirst, int *edgeListFirst, long long *beginPosSecond, int *edgeListSecond, unsigned long long *globalCount, int *perVertexCount, int *hashTable, int startVertex, int endVertex, int length, int partitionNum)
{
    __shared__ unsigned long long sharedCount;
    if (threadIdx.x == 0)
        sharedCount = 0;
    unsigned long long count = 0;
    for (int i = threadIdx.x + blockIdx.x * (length); i < (1 + blockIdx.x) * (length); i += blockDim.x)
    {
        hashTable[i] = 0;
    }
    __syncthreads();
    for (int vertex = startVertex + blockIdx.x; vertex < endVertex; vertex += gridDim.x)
    {
        hashBasedPerVertexWithPartition(vertex, beginPosFirst, edgeListFirst, beginPosSecond, beginPosSecond + 1, edgeListSecond, hashTable, length, &count, partitionNum, 0);
    }

    atomicAdd(&sharedCount, count);
    __syncthreads();
    if (threadIdx.x == 0)
        atomicAdd(globalCount, sharedCount);
}