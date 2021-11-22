#include <iostream>
#include <cub/cub.cuh>
#include <cub/util_type.cuh>
#ifdef DEBUG
#define DBGprint(...) printf(__VA_ARGS__)
#else
#define DBGprint(...)
#endif
#define MAXINT 2147483641
#define FULL_MASK 0xffffffff
using namespace std;

struct heap
{
    int element;
    int *now;
    int *end;
};

__device__ int *binarySearch(int *a, int *b, int x)
{
    while (a < b)
    {
        int *mid = a + ((b - a) / 2);
        if (*mid < x)
            a = mid + 1;
        else
            b = mid;
    }
    return a;
}

__device__ void heapBasedPerVertexCounting(int vertex, long long *beginPos, int *edgeList, int *hashTable, int uCount, int vCount, unsigned long long *count)
{
    struct heap H[11];
    H[0].element = -1;
    int k = 1;

    // first creat the heap
    for (int oneHopNeighborID = beginPos[vertex]; oneHopNeighborID < beginPos[vertex + 1]; oneHopNeighborID++)
    {
        int oneHopNeighbor = edgeList[oneHopNeighborID];
        // get the first neighbor in each oneHopNeighbor's neighbor list
        H[k].now = edgeList + beginPos[oneHopNeighbor];
        H[k].end = binarySearch(H[k].now, edgeList + beginPos[oneHopNeighbor + 1], vertex < oneHopNeighbor ? vertex : oneHopNeighbor);
        // printf("%d %d %d\n", *H[k].now, *H[k].end, vertex < oneHopNeighbor ? vertex : oneHopNeighbor);
        // for (int *aaaaa = H[k].now; aaaaa < H[k].end; aaaaa++)
        // {
        //     DBGprint("%d ", *aaaaa);
        // }
        // DBGprint("\n");
        if (H[k].now >= H[k].end)
            continue;
        H[k].element = *H[k].now;
        // update the heap
        int p = k;
        while (H[p].element < H[p / 2].element)
        {
            struct heap t;
            t = H[p];
            H[p] = H[p / 2];
            p /= 2;
            H[p] = t;
        }
        k++;
    }
    int previousElement = -1, cc = 1;
    // second pop the top element in heap and add new element from its corresponding neighbor list
    for (--k; k >= 1;)
    {
        // update the count of butterflies
        int nowElement = H[1].element;

        // if (iddd > 967 && iddd < 974)
        // {
        //     DBGprint("%d,,%d,,%d,,%d\n", cc, nowElement, previousElement, iddd);
        //     for (int aaaaa = 0; aaaaa < k; aaaaa++)
        //         DBGprint("%d ", H[aaaaa].element);
        //     DBGprint("\n");
        // }
        if (nowElement == previousElement)
        {
            cc++;
        }
        else
        {
            // if (cc > 1)
            //     DBGprint("%d,%d\n", previousElement, cc);
            *count += cc * (cc - 1) / 2;
            cc = 1;
            previousElement = nowElement;
        }

        // add the next element into heap
        H[1].now++;
        if (H[1].now >= H[1].end)
        {
            struct heap t;
            t = H[1];
            H[1] = H[k];
            H[k] = t;
            k--;
        }
        else
            H[1].element = *(H[1].now);

        // update the heap
        int p = 1;
        for (;;)
        {
            if (p * 2 > k)
                break;
            p *= 2;
            if (p + 1 <= k && H[p].element > H[p + 1].element)
                p++;
            if (H[p].element < H[p / 2].element)
            {
                struct heap t;
                t = H[p];
                H[p] = H[p / 2];
                H[p / 2] = t;
            }
            else
                break;
        }
    }
    DBGprint("%d\n", cc);
    *count += cc * (cc - 1) / 2; // the last series of element need to be added
}

__global__ void heapBasedButterflyCounting(long long *beginPos, int *edgeList, int uCount, int vCount, unsigned long long *globalCount, int *perVertexCount, int *hashTable, int startVertex, int endVertex)
{
    __shared__ unsigned long long sharedCount;
    if (threadIdx.x == 0)
        sharedCount = 0;
    unsigned long long count = 0;
    for (int vertex = startVertex + blockIdx.x * blockDim.x + threadIdx.x; vertex < endVertex; vertex += gridDim.x * blockDim.x)
    {
        // count=0;
        heapBasedPerVertexCounting(vertex, beginPos, edgeList, hashTable, uCount, vCount, &count);
        // perVertexCount[vertex]=count;
    }
    atomicAdd(&sharedCount, count);
    __syncthreads();
    if (threadIdx.x == 0)
        atomicAdd(globalCount, sharedCount);
}

__device__ void heapBasedPerVertexCounting_byWarp(int vertex, long long *beginPos, int *edgeList, int *hashTable, int uCount, int vCount, unsigned long long *count)
{

    int warpID = threadIdx.x / 32;
    int threadId = threadIdx.x % 32;
    struct heap h;
    h.element = MAXINT;
    int k = 1;

    // first creat the heap
    for (int oneHopNeighborID = beginPos[vertex] + threadId; oneHopNeighborID < beginPos[vertex + 1]; oneHopNeighborID += 32)
    {
        int oneHopNeighbor = edgeList[oneHopNeighborID];
        // get the first neighbor in each oneHopNeighbor's neighbor list
        h.now = edgeList + beginPos[oneHopNeighbor];
        h.end = binarySearch(h.now, edgeList + beginPos[oneHopNeighbor + 1], vertex < oneHopNeighbor ? vertex : oneHopNeighbor);
        if (h.now < h.end)
            h.element = *(h.now);
    }
    int previousElement = -1, cc = 1;
    // second pop the top element in heap and add new element from its corresponding neighbor list
    for (;;)
    {
        int element = h.element;

        int id = threadId;
        int needBreak = 0;
        for (int offset = 16; offset > 0; offset /= 2)
        {
            int otherElement = __shfl_down_sync(FULL_MASK, element, offset);
            int otherId = __shfl_down_sync(FULL_MASK, id, offset);
            if (otherElement < element)
            {
                element = otherElement;
                id = otherId;
            }
        }
        __syncwarp();

        if (threadId == 0)
        {
            // printf("%d %d\n", element, id);
            if (element == MAXINT)
            {
                needBreak = 1;
            }
            else if (element == previousElement)
            {
                cc++;
            }
            else
            {
                *count += cc * (cc - 1) / 2;
                cc = 1;
                previousElement = element;
            }
        }
        __syncwarp();
        needBreak = __shfl_sync(FULL_MASK, needBreak, 0);
        if (needBreak)
        {
            break;
        }
        id = __shfl_sync(FULL_MASK, id, 0);

        if (threadId == id)
        {
            h.now++;
            if (h.now < h.end)
                h.element = *(h.now);
            else
                h.element = MAXINT;
        }
    }
    *count += cc * (cc - 1) / 2; // the last series of element need to be added
}

__global__ void heapBasedButterflyCounting_byWarp(long long *beginPos, int *edgeList, int uCount, int vCount, unsigned long long *globalCount, int *perVertexCount, int *hashTable, int startVertex, int endVertex)
{
    __shared__ unsigned long long sharedCount;
    if (threadIdx.x == 0)
        sharedCount = 0;
    unsigned long long count = 0;
    int warpID = threadIdx.x / 32;
    int warpNum = blockDim.x / 32;
    for (int vertex = startVertex + blockIdx.x * warpNum + warpID; vertex < endVertex; vertex += gridDim.x * warpNum)
    {
        // count=0;
        heapBasedPerVertexCounting_byWarp(vertex, beginPos, edgeList, hashTable, uCount, vCount, &count);
        // perVertexCount[vertex]=count;
    }
    if (threadIdx.x % 32 == 0)
        atomicAdd(&sharedCount, count);
    __syncthreads();
    if (threadIdx.x == 0)
        atomicAdd(globalCount, sharedCount);
}