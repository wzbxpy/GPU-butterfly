#include <iostream>
#include "../globalPara.h"
#ifdef DEBUG
#define DBGprint(...) printf(__VA_ARGS__)
#else
#define DBGprint(...)
#endif
#define MAXINT 2147483641
#define FULL_MASK 0xffffffff
using namespace std;
#define subwarpSize 8
#define subwarpNum (32 / subwarpSize)
#define sharedElementSize blockSize *subwarpSize

struct marker
{
    int element;
    int *globalNow;
    int localNow;
    int len;
};
__device__ void mergeBasedPerVertexCounting__backup(int vertex, long long *beginPos, int *edgeList, int *hashTable, int uCount, int vCount, unsigned long long *count)
{

    int warpId = threadIdx.x / 32;
    int threadId = threadIdx.x % 32;
    struct marker h;
    h.element = MAXINT;
    int bound;

    // first creat the marker
    for (int oneHopNeighborID = beginPos[vertex] + threadId; oneHopNeighborID < beginPos[vertex + 1]; oneHopNeighborID += 32)
    {
        int oneHopNeighbor = edgeList[oneHopNeighborID];
        // get the first neighbor in each oneHopNeighbor's neighbor list
        bound = vertex < oneHopNeighbor ? vertex : oneHopNeighbor;

        int start = beginPos[oneHopNeighbor];
        int end = beginPos[oneHopNeighbor + 1];
        h.globalNow = edgeList + start;
        h.len = end - start;
        if (h.len > 0)
        {
            int element = *(h.globalNow);
            if (element < bound)
                h.element = element;
            else
                h.len = -1;
            h.len--;
            h.globalNow++;
        }
    }
    int previousElement = -1, cc = 1;
    // second pop the top element in marker and add new element from its corresponding neighbor list
    for (;;)
    {
        int element = __reduce_min_sync(FULL_MASK, h.element);
        if (element == MAXINT)
            break;
        int matched = element == h.element;
        if (matched)
        {
            h.element = MAXINT;
            if (h.len > 0)
            {
                int element = *(h.globalNow);
                if (element < bound)
                    h.element = element;
                else
                    h.len = -1;
                h.len--;
                h.globalNow++;
            }
        }
        matched = __reduce_add_sync(FULL_MASK, matched);
        if (threadId == 0)
            *count += matched * (matched - 1) / 2;
    }
}

__device__ void mergeBasedPerVertexCounting__activethread(int vertex, long long *beginPos, int *edgeList, int *hashTable, int uCount, int vCount, unsigned long long *count)
{

    int warpId = threadIdx.x / 32;
    int threadId = threadIdx.x % 32;
    struct marker h;
    h.element = MAXINT;
    int bound;
    __shared__ int activeThreads[blockSize / 32];

    // first creat the marker
    for (int oneHopNeighborID = beginPos[vertex] + threadId; oneHopNeighborID < beginPos[vertex + 1]; oneHopNeighborID += 32)
    {
        int oneHopNeighbor = edgeList[oneHopNeighborID];
        // get the first neighbor in each oneHopNeighbor's neighbor list
        bound = vertex < oneHopNeighbor ? vertex : oneHopNeighbor;

        int start = beginPos[oneHopNeighbor];
        int end = beginPos[oneHopNeighbor + 1];
        h.globalNow = edgeList + start;
        h.len = end - start;
        if (h.len > 0)
        {
            int element = *(h.globalNow);
            if (element < bound)
                h.element = element;
            else
                h.len = -1;
            h.len--;
            h.globalNow++;
        }
    }

    __syncwarp();
    int isActive = h.element < MAXINT;
    isActive = __reduce_add_sync(FULL_MASK, isActive);
    if (threadId == 0)
        activeThreads[warpId] = isActive;
    int previousElement = -1, cc = 1;
    __syncwarp();
    // second pop the top element in marker and add new element from its corresponding neighbor list
    for (; activeThreads[warpId] > 1;)
    {
        int element = __reduce_min_sync(FULL_MASK, h.element);
        if (element == MAXINT)
            break;
        int matched = element == h.element;
        if (matched)
        {
            h.element = MAXINT;
            if (h.len > 0)
            {
                int element = *(h.globalNow);
                if (element < bound)
                    h.element = element;
                else
                    h.len = -1;
                h.len--;
                if (h.len < 0)
                    atomicAdd(activeThreads + warpId, -1);
                h.globalNow++;
            }
        }
        matched = __reduce_add_sync(FULL_MASK, matched);
        if (threadId == 0)
            *count += matched * (matched - 1) / 2;
    }
}

__global__ void mergeBasedButterflyCounting(long long *beginPos, int *edgeList, int uCount, int vCount, unsigned long long *globalCount, int *perVertexCount, int *hashTable, int startVertex, int endVertex)
{
    __shared__ unsigned long long sharedCount;
    if (threadIdx.x == 0)
        sharedCount = 0;
    unsigned long long count = 0;
    int warpId = threadIdx.x / 32;
    int warpNum = blockDim.x / 32;
    for (int vertex = startVertex + blockIdx.x * warpNum + warpId; vertex < endVertex; vertex += gridDim.x * warpNum)
    {
        // count=0;
        mergeBasedPerVertexCounting__backup(vertex, beginPos, edgeList, hashTable, uCount, vCount, &count);
        // perVertexCount[vertex]=count;
    }
    if (threadIdx.x % 32 == 0)
    {
        atomicAdd(&sharedCount, count);
    }
    __syncthreads();
    if (threadIdx.x == 0)
    {
        atomicAdd(globalCount, sharedCount);
    }
}
