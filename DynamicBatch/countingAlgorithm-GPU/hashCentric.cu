#include <iostream>
#include <cooperative_groups.h>
#include <cooperative_groups/memcpy_async.h>
#include <cooperative_groups/reduce.h>
using namespace std;
using namespace cooperative_groups;
#define warpSize 32

__global__ void hashCentric(long long *beginPosFirst, int *edgeListFirst, long long *beginPosSecond, int *edgeListSecond, unsigned long long *globalCount, int *hashTable, int startVertex, int endVertex, int length, int partitionNum)
{
    for (int j = blockIdx.x; j < length; j += gridDim.x)
        for (int i = threadIdx.x + j * (length); i < (1 + j) * (length); i += blockDim.x)
            hashTable[i] = 0;
    auto grid = this_grid();
    grid.sync();
    __shared__ unsigned long long sharedCount;
    if (threadIdx.x == 0)
        sharedCount = 0;
    unsigned long long count = 0;
    int threadId = threadIdx.x % warpSize;
    int warpId = (blockDim.x * blockIdx.x + threadIdx.x) / warpSize;
    int warpDim = gridDim.x * blockDim.x / warpSize;
    for (int vertex = startVertex + warpId; vertex < endVertex; vertex += warpDim)
    {
        // if (threadIdx.x + blockIdx.x == 0)
        //     printf("%d\n", vertex);
        for (int firstNeighborID = beginPosFirst[vertex] + threadId; firstNeighborID < beginPosFirst[vertex + 1]; firstNeighborID += warpSize)
        {
            int firstNeighbor = edgeListFirst[firstNeighborID];
            int bound = vertex < firstNeighbor ? vertex : firstNeighbor;
            for (int secondNeighborID = beginPosSecond[vertex]; secondNeighborID < beginPosSecond[vertex + 1]; secondNeighborID += 1)
            {
                int secondNeighbor = edgeListSecond[secondNeighborID];
                if (secondNeighbor >= bound)
                    break;
                // if (firstNeighbor >= length || secondNeighbor >= length)
                //     printf("%d %d\n", firstNeighbor, secondNeighbor);
                count += atomicAdd(&hashTable[firstNeighbor / partitionNum * length + secondNeighbor / partitionNum], 1);
            }
        }
        __syncthreads();
    }
    atomicAdd(&sharedCount, count);
    __syncthreads();
    if (threadIdx.x == 0)
        atomicAdd(globalCount, sharedCount);
}

__global__ void clearHashTable(int *hashTable, int length)
{
    for (int j = blockIdx.x; j < length; j += gridDim.x)
        for (int i = threadIdx.x + j * (length); i < (1 + j) * (length); i += blockDim.x)
            hashTable[i] = 0;
}