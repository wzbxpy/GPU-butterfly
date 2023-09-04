#include <iostream>
#include "../graph.h"
#include "../wtime.h"
#include "../util.h"
#include "butterfly-GPU.h"
#include <unistd.h>
// #include "edgeCentric.cuh"
// #include "hashCentric.cuh"
// #include <cooperative_groups.h>
// #include <cooperative_groups/memcpy_async.h>
// #include <cooperative_groups/reduce.h>
// #define dev 1
#define warpSize 32
#define FULL_MASK 0xffffffff
#define inf 0x7fffffff
#define MAXINT 2147483641
#define DEBUG
#define sharedSize 1024 * 8
#ifdef DEBUG
#define DBGprint(...) printf(__VA_ARGS__)
#else
#define DBGprint(...)
#endif
#define SHAREDTABLE
#define markerNum 32

using namespace std;
// using namespace cooperative_groups;
const int chunckSize = 1;
#define MAXINT 2147483641

// template <class T>
// int initializeCudaPara(int deviceId, int numThreads, T func)
// {
//     cudaSetDevice(deviceId);
//     int numBlocksPerSm = 0;
//     // Number of threads my_kernel will be launched with
//     cudaDeviceProp deviceProp;
//     cudaGetDeviceProperties(&deviceProp, deviceId);
//     cudaOccupancyMaxActiveBlocksPerMultiprocessor(&numBlocksPerSm, func, numThreads, 0);
//     // cout << deviceProp.multiProcessorCount << "  " << numBlocksPerSm << endl;
//     int numBlocks = deviceProp.multiProcessorCount * numBlocksPerSm;
//     return numBlocks;
// }

struct GPUgraph
{
    long long *beginPos;
    int *edgeList;
    int vertexCount;
    long long edgeCount;
    GPUgraph(int vertexNum, long long edgeNum)
    {
        vertexCount = vertexNum;
        edgeCount = edgeNum;
        HRR(cudaMalloc(&beginPos, sizeof(long long) * (long long)(vertexCount + 1)));
        HRR(cudaMalloc(&edgeList, sizeof(int) * edgeCount));
    }
    GPUgraph(string path)
    {
        graph *Gtmp = new graph;
        Gtmp->loadProperties(path);
        vertexCount = Gtmp->vertexCount;
        edgeCount = Gtmp->edgeCount;
        HRR(cudaMalloc(&beginPos, sizeof(long long) * (long long)(vertexCount + 1)));
        HRR(cudaMalloc(&edgeList, sizeof(int) * edgeCount));
        // delete Gtmp;
    }
    double loadGraph(int vertexNum, long long edgeNum, long long *CPU_beginPos, int *CPU_edgelist)
    {
        vertexCount = vertexNum;
        edgeCount = edgeNum;
        double startTime = wtime();
        HRR(cudaMemcpy(beginPos, CPU_beginPos, sizeof(long long) * (long long)(vertexCount + 1), cudaMemcpyHostToDevice));
        HRR(cudaMemcpy(edgeList, CPU_edgelist, sizeof(int) * (edgeCount), cudaMemcpyHostToDevice));
        return getDeltaTime(startTime);
    }
    double loadBeginPos(int vertexNum, long long *CPU_beginPos)
    {
        vertexCount = vertexNum;
        double startTime = wtime();
        HRR(cudaMemcpy(beginPos, CPU_beginPos, sizeof(long long) * (long long)(vertexCount + 1), cudaMemcpyHostToDevice));
        return getDeltaTime(startTime);
    }
    double loadGraphFromDisk(string path, graph *Gtmp)
    {
        double startTime = wtime();
        Gtmp->loadGraph(path);
        vertexCount = Gtmp->vertexCount;
        edgeCount = Gtmp->edgeCount;
        HRR(cudaMemcpy(beginPos, Gtmp->beginPos, sizeof(long long) * (long long)(vertexCount + 1), cudaMemcpyHostToDevice));
        HRR(cudaMemcpy(edgeList, Gtmp->edgeList, sizeof(int) * (edgeCount), cudaMemcpyHostToDevice));
        return getDeltaTime(startTime);
    }
};

__device__ void loadNextVertex(int &vertex, int *nextVertex, int &nextVertexshared, bool isFirstThread, int offsets)
{
    if ((vertex + 1 - offsets) % chunckSize != 0)
    {
        vertex++;
    }
    else
    {
        if (isFirstThread)
            nextVertexshared = atomicAdd(nextVertex, chunckSize);
        __syncthreads();
        vertex = nextVertexshared;
    }
}

__global__ void initializeBeginPosition_GPUkernel(long long beginPosition[], long long endPosition[], GPUgraph G, int boundary, bool isFirst, bool isLast, int startVertex)
{
    int threadId = threadIdx.x + blockIdx.x * blockDim.x;
    int warpId = threadId / 32;
    int threadInWarp = threadId % 32;
    // if (isFirst) // The first begin position need to be initialized
    // {
    //     for (int vertex = startVertex + threadId; vertex < G.vertexCount; vertex += blockDim.x * gridDim.x)
    //         beginPosition[vertex] = G.beginPos[vertex];
    // }
    if (isLast) // The last part of end position can be directly obtained
    {
        for (int vertex = startVertex + threadId; vertex < G.vertexCount; vertex += blockDim.x * gridDim.x)
            endPosition[vertex] = G.beginPos[vertex + 1];
    }
    else
    {
        // for (int vertex = startVertex + threadId; vertex < G.vertexCount; vertex += blockDim.x * gridDim.x)
        // {
        //     long long pos;
        //     for (pos = beginPosition[vertex]; pos < G.beginPos[vertex + 1]; pos++)
        //     {
        //         if (G.edgeList[pos] >= boundary)
        //             break;
        //     }
        //     endPosition[vertex] = pos;
        // }
        for (int vertex = startVertex + warpId; vertex < G.vertexCount; vertex += blockDim.x * gridDim.x / 32)
        {
            long long pos = beginPosition[vertex] + threadInWarp;
            int bound = boundary < vertex ? boundary : vertex;
            for (; pos < G.beginPos[vertex + 1]; pos += 32)
            {
                if (G.edgeList[pos] >= bound)
                    break;
            }
            pos = beginPosition[vertex] + __reduce_min_sync(__activemask(), int(pos - beginPosition[vertex]));
            // if (threadInWarp == 0)
            endPosition[vertex] = pos;
        }
    }
}

__global__ void edgeCentric_GPUkernel(GPUgraph G_src,
                                      GPUgraph G_dst,
                                      unsigned long long *globalCount,
                                      int *hashTable,
                                      int partitionNum,
                                      int vertexOffsets,
                                      int *nextVertex,
                                      long long maxVertexCount,
                                      long long beginPosition[],
                                      long long endPosition[],
                                      int dstOffsets,
                                      int subwarpSize,
                                      int degreeBoundForClearHashtable,
                                      int startVertex,
                                      int endVertex)
{
    __shared__ unsigned long long sharedCount;
    __shared__ int nextVertexshared;
    // __shared__ unsigned long long nextOneHopNeighborID;
    hashTable = hashTable + maxVertexCount * blockIdx.x;
    if (threadIdx.x == 0)
        sharedCount = 0;
    unsigned long long count = 0;

    // Initialize Hashtable
#ifdef SHAREDTABLE
    __shared__ int sharedHashTable[sharedSize + 1];
    for (int i = threadIdx.x; i < sharedSize; i += blockDim.x)
    {
        sharedHashTable[i] = 0;
    }
    for (int i = threadIdx.x + sharedSize; i < maxVertexCount; i += blockDim.x)
    {
        hashTable[i] = 0;
    }
#else
    for (int i = threadIdx.x; i < maxVertexCount; i += blockDim.x)
    {
        hashTable[i] = 0;
    }
#endif

    __syncthreads();

    // int subwarpSize = 2;
    int subwarpNum = blockDim.x / subwarpSize;
    for (int vertex = blockIdx.x * chunckSize + startVertex; vertex < endVertex;)
    {
        int vertexDegree = G_src.beginPos[vertex + 1] - G_src.beginPos[vertex];
        // if (vertexDegree * subwarpSize < 1024)
        // {
        //     subwarpSize *= 2;
        //     subwarpNum /= 2;
        // }
        // put the two hop neighbor of vertex into hash map
        // if (threadIdx.x == 0)
        //     nextOneHopNeighborID = G_src.beginPos[vertex] + subwarpNum;
        // __syncthreads();
        for (auto oneHopNeighborID = G_src.beginPos[vertex] + threadIdx.x / subwarpSize; oneHopNeighborID < G_src.beginPos[vertex + 1]; oneHopNeighborID += subwarpNum)
        // for (auto oneHopNeighborID = G_src.beginPos[vertex] + threadIdx.x / subwarpSize; oneHopNeighborID < G_src.beginPos[vertex + 1]; oneHopNeighborID += subwarpNum)
        {
            int oneHopNeighbor = G_src.edgeList[oneHopNeighborID];
            if (oneHopNeighbor < dstOffsets)
                continue;
            int bound = vertex * partitionNum + vertexOffsets < oneHopNeighbor ? vertex * partitionNum + vertexOffsets : oneHopNeighbor;
            for (auto twoHopNeighborID = beginPosition[oneHopNeighbor] + threadIdx.x % subwarpSize; twoHopNeighborID < endPosition[oneHopNeighbor]; twoHopNeighborID += subwarpSize)
            {
                int twoHopNeighbor = G_dst.edgeList[twoHopNeighborID];
                if (twoHopNeighbor >= bound)
                    break;
                int index = (twoHopNeighbor - dstOffsets) / partitionNum;
#ifdef SHAREDTABLE
                if (index < sharedSize)
                    count += atomicAdd(&sharedHashTable[index], 1);
                else
#endif
                    count += atomicAdd(&hashTable[index], 1);

                // hashTable[(twoHopNeighbor - dstOffsets) / partitionNum]++;
                // count++;
            }
        }
        __syncthreads();

        // reset the hash map
        // if (0)
        if (vertexDegree > degreeBoundForClearHashtable) // choose the lower costs method
        {
// hashTableShared[threadIdx.x] = 0;
#ifdef SHAREDTABLE
            for (int i = threadIdx.x; i < sharedSize; i += blockDim.x)
            {
                sharedHashTable[i] = 0;
            }
            for (int i = threadIdx.x + sharedSize; i < vertex; i += blockDim.x)
            {
                hashTable[i] = 0;
            }
#else
            for (int i = threadIdx.x; i < vertex; i += blockDim.x)
            {
                hashTable[i] = 0;
            }
#endif
        }
        else
        {
            for (auto oneHopNeighborID = G_src.beginPos[vertex] + threadIdx.x / subwarpSize; oneHopNeighborID < G_src.beginPos[vertex + 1]; oneHopNeighborID += subwarpNum)
            {
                int oneHopNeighbor = G_src.edgeList[oneHopNeighborID];
                if (oneHopNeighbor < dstOffsets)
                    continue;
                int bound = vertex * partitionNum + vertexOffsets < oneHopNeighbor ? vertex * partitionNum + vertexOffsets : oneHopNeighbor;
                for (auto twoHopNeighborID = beginPosition[oneHopNeighbor] + threadIdx.x % subwarpSize; twoHopNeighborID < endPosition[oneHopNeighbor]; twoHopNeighborID += subwarpSize)
                {
                    int twoHopNeighbor = G_dst.edgeList[twoHopNeighborID];
                    if (twoHopNeighbor >= bound)
                        break;
                    int index = (twoHopNeighbor - dstOffsets) / partitionNum;
#ifdef SHAREDTABLE
                    if (index < sharedSize)
                        sharedHashTable[index] = 0;
                    else
#endif
                        hashTable[index] = 0;
                }
            }
        }
        // if (count > 0)
        //     printf("%d %lld \n", vertex, count);
        // break;

        __syncthreads();
        loadNextVertex(vertex, nextVertex, nextVertexshared, threadIdx.x == 0, startVertex);
        // vertex += gridDim.x;
    }

    atomicAdd(&sharedCount, count);
    __syncthreads();
    if (threadIdx.x == 0)
        atomicAdd(globalCount, sharedCount);
}

struct marker
{
    int element;
    int *globalNow;
    int len;
    int bound;
};
__global__ void mergeBased(GPUgraph G_src,
                           GPUgraph G_dst,
                           unsigned long long *globalCount,
                           int partitionNum,
                           int vertexOffsets,
                           int *nextVertex,
                           int startVertex,
                           int endVertex)
{
    __shared__ unsigned long long sharedCount;
    __shared__ int nextVertexshared[32];
    if (threadIdx.x == 0)
        sharedCount = 0;
    unsigned long long count = 0;
    int warpId = threadIdx.x / 32;
    int threadId = threadIdx.x % 32;
    struct marker h[markerNum];
    for (int vertex = (blockIdx.x * 32 + warpId) * chunckSize + startVertex; vertex < endVertex;)
    // if (warpId != 0 || blockIdx.x != 0)
    //     return;
    { // first creat the marker
        int vertexDegree = G_src.beginPos[vertex + 1] - G_src.beginPos[vertex];
        int thisMarkerNum = (vertexDegree - 1) / 32 + 1;
        int markerIndex = 0;
        for (auto oneHopNeighborID = G_src.beginPos[vertex] + threadId; markerIndex < thisMarkerNum; oneHopNeighborID += 32, markerIndex++)
        {
            h[markerIndex].element = MAXINT;
            if (oneHopNeighborID >= G_src.beginPos[vertex + 1])
                break;
            auto oneHopNeighbor = G_src.edgeList[oneHopNeighborID];
            // get the first neighbor in each oneHopNeighbor's neighbor list
            h[markerIndex].bound = vertex * partitionNum + vertexOffsets < oneHopNeighbor ? vertex * partitionNum + vertexOffsets : oneHopNeighbor;

            auto start = G_dst.beginPos[oneHopNeighbor];
            auto end = G_dst.beginPos[oneHopNeighbor + 1];
            h[markerIndex].globalNow = G_dst.edgeList + start;
            h[markerIndex].len = end - start;
            if (h[markerIndex].len > 0)
            {
                int element = *(h[markerIndex].globalNow);
                if (element < h[markerIndex].bound)
                    h[markerIndex].element = element;
                else
                    h[markerIndex].len = -1;
                h[markerIndex].len--;
                h[markerIndex].globalNow++;
            }
        }
        // int previousElement = -1,cc = 1;
        // __syncwarp();
        // second pop the top element in marker and add new element from its corresponding neighbor list
        for (;;)
        {
            int element = __reduce_min_sync(FULL_MASK, h[0].element);
            for (int markerIndex = 1; markerIndex < thisMarkerNum; markerIndex++)
                element = min(element, __reduce_min_sync(FULL_MASK, h[markerIndex].element));
            if (element == MAXINT)
                break;
            int wedgeCount = 0;

            for (int markerIndex = 0; markerIndex < thisMarkerNum; markerIndex++)
            {
                int matched = element == h[markerIndex].element;
                if (matched)
                {
                    h[markerIndex].element = MAXINT;
                    if (h[markerIndex].len > 0)
                    {
                        int element = *(h[markerIndex].globalNow);
                        if (element < h[markerIndex].bound)
                            h[markerIndex].element = element;
                        else
                            h[markerIndex].len = -1;
                        h[markerIndex].len--;
                        h[markerIndex].globalNow++;
                    }
                }
                wedgeCount += __reduce_add_sync(FULL_MASK, matched);
            }
            if (threadId == 0)
            {
                count += wedgeCount * (wedgeCount - 1) / 2;
                // count += wedgeCount;
                // printf("wedge count %d count %lld \n", wedgeCount, count);
            }
            // if (threadId == 0 && blockIdx.x == 36)
            //     printf("%d %d %d\n", matched, element, vertex);
            // printf("%d %d\n", threadIdx.x, h.element);
        }
        // if (threadId == 0)
        // {
        //     int oneHopNeighbor = G_src.edgeList[G_src.beginPos[vertex]];
        //     int x = G_dst.edgeList[G_dst.beginPos[oneHopNeighbor]];
        //     int y = G_dst.edgeList[G_dst.beginPos[oneHopNeighbor + 1]];
        //     if (x == y)
        //         count++;
        // }
        // if (threadId == 0 && count > 0)
        //     printf("%d %lld\n", vertex, count);
        // break;

        // __syncthreads();
        // loadNextVertex(vertex, nextVertex, nextVertexshared[warpId], threadId == 0);
        vertex += 32 * gridDim.x;
        // if (threadIdx.x == 0 && blockIdx.x == 36)
        //     printf("%d %d %d %d\n", vertex, gridDim.x, chunckSize, dstOffsets);
        // vertex += gridDim.x;
    }
    if (threadId == 0)
        atomicAdd(&sharedCount, count);
    __syncthreads();
    if (threadIdx.x == 0)
        atomicAdd(globalCount, sharedCount);
}

__global__ void hashBased1HopPerThread(GPUgraph G_src, GPUgraph G_dst, unsigned long long *globalCount, int *hashTable, int partitionNum, int vertexOffsets, int *nextVertex, long long maxVertexCount, long long beginPosition[], long long endPosition[], int dstOffsets)
{
    __shared__ unsigned long long sharedCount;
    __shared__ int nextVertexshared;
    hashTable = hashTable + maxVertexCount * blockIdx.x;

    if (threadIdx.x == 0)
        sharedCount = 0;
    unsigned long long count = 0;

    for (int i = threadIdx.x; i < maxVertexCount; i += blockDim.x)
    {
        hashTable[i] = 0;
    }
    __syncthreads();

    for (int vertex = blockIdx.x * chunckSize + dstOffsets / partitionNum; vertex < G_src.vertexCount;)
    {
        int vertexDegree = G_src.beginPos[vertex + 1] - G_src.beginPos[vertex];
        if (vertexDegree < 1024)
            break;
        // put the two hop neighbor of vertex into hash map
        for (auto oneHopNeighborID = G_src.beginPos[vertex] + threadIdx.x; oneHopNeighborID < G_src.beginPos[vertex + 1]; oneHopNeighborID += blockDim.x)
        {
            int oneHopNeighbor = G_src.edgeList[oneHopNeighborID];
            if (oneHopNeighbor < dstOffsets)
                continue;
            int bound = vertex * partitionNum + vertexOffsets < oneHopNeighbor ? vertex * partitionNum + vertexOffsets : oneHopNeighbor;
            for (auto twoHopNeighborID = beginPosition[oneHopNeighbor]; twoHopNeighborID < endPosition[oneHopNeighbor]; twoHopNeighborID++)
            {
                int twoHopNeighbor = G_dst.edgeList[twoHopNeighborID];
                if (twoHopNeighbor >= bound)
                    break;
                count += atomicAdd(&hashTable[(twoHopNeighbor - dstOffsets) / partitionNum], 1);

                // hashTable[(twoHopNeighbor - dstOffsets) / partitionNum]++;
                // count++;
            }
        }
        __syncthreads();

        // reset the hash map
        // if (0)
        if (G_dst.edgeCount / G_dst.vertexCount > G_dst.vertexCount / vertexDegree) // choose the lower costs method
        {
            // hashTableShared[threadIdx.x] = 0;
            for (int i = threadIdx.x; i < vertex; i += blockDim.x)
            {
                hashTable[i] = 0;
            }
        }
        else
        {
            for (auto oneHopNeighborID = G_src.beginPos[vertex] + threadIdx.x; oneHopNeighborID < G_src.beginPos[vertex + 1]; oneHopNeighborID += blockDim.x)
            {
                int oneHopNeighbor = G_src.edgeList[oneHopNeighborID];
                if (oneHopNeighbor < dstOffsets)
                    continue;
                int bound = vertex * partitionNum + vertexOffsets < oneHopNeighbor ? vertex * partitionNum + vertexOffsets : oneHopNeighbor;
                for (auto twoHopNeighborID = beginPosition[oneHopNeighbor]; twoHopNeighborID < endPosition[oneHopNeighbor]; twoHopNeighborID++)
                {
                    int twoHopNeighbor = G_dst.edgeList[twoHopNeighborID];
                    if (twoHopNeighbor >= bound)
                        break;
                    hashTable[(twoHopNeighbor - dstOffsets) / partitionNum] = 0;
                }
            }
        }
        // if (count > 0)
        //     printf("%d %lld \n", vertex, count);
        // break;

        __syncthreads();
        loadNextVertex(vertex, nextVertex, nextVertexshared, threadIdx.x == 0, dstOffsets / partitionNum);
        // vertex += gridDim.x;
    }

    atomicAdd(&sharedCount, count);
    __syncthreads();
    if (threadIdx.x == 0)
        atomicAdd(globalCount, sharedCount);
}

int BC_edge_centric(graph *G, parameter para)
{
    double startTime, transferTime = 0, initializeTime = 0;
    double computeTime_block_largeWorkload = 0, computeTime_warp_smallWorkload = 0;
    double computeTime_block[100] = {0}, computeTime_warp[100] = {0};

    int numThreads = 1024;
    int numBlocks = para.processorNum;
    int partitionNum = para.partitionNum;
    int degreeBoundForClearHashtable;
    // numBlocks = 1;

    unsigned long long *globalCount;
    HRR(cudaMallocManaged(&globalCount, sizeof(unsigned long long)));
    *globalCount = 0;
    int *nextVertex;
    HRR(cudaMallocManaged(&nextVertex, sizeof(int)));
    int *hashTable;
    long long maxVertexCountInBatch = ceil(G->vertexCount / (double)para.batchNum / (double)partitionNum);
    HRR(cudaMalloc(&hashTable, maxVertexCountInBatch * numBlocks * sizeof(int)));
    // GPUgraph G_src(G->subBeginPosFirst[0].size() - 1, G->subEdgeListFirst[0].size());
    // GPUgraph G_dst(G->subBeginPosSecond[0].size() - 1, G->subEdgeListSecond[0].size());
    GPUgraph G_src(subgraphFold(para.path, partitionNum, 0, true));
    GPUgraph G_dst(subgraphFold(para.path, partitionNum, 0, false));
    graph *Gtmp = new graph;
    Gtmp->loadGraph(subgraphFold(para.path, partitionNum, 0, false));
    Gtmp->loadGraph(subgraphFold(para.path, partitionNum, 0, true));
    int vertex32 = Gtmp->findBreakVertex(32);
    int vertex1 = Gtmp->findBreakVertex(1);
    int breakVertex[10000];
    for (int i = 1; i < 1025; i++)
    {
        breakVertex[i] = Gtmp->findBreakVertex(i);
    }

    if (para.hashRecy == adaptiveRecy)
        degreeBoundForClearHashtable = (long long)G->vertexCount * G->vertexCount / G->edgeCount;
    if (para.hashRecy == scanWedgeRecy)
        degreeBoundForClearHashtable = G->vertexCount;
    if (para.hashRecy == scanHashtableRecy)
        degreeBoundForClearHashtable = 0;
    // cout << degreeBoundForClearHashtable << " " << Gtmp->findBreakVertex(degreeBoundForClearHashtable) << endl;

    long long *D_Position;
    HRR(cudaMalloc(&D_Position, sizeof(long long) * G->vertexCount * 2));

    startTime = wtime();
    for (int i = 0; i < partitionNum; i++)
    {
        transferTime += G_src.loadGraphFromDisk(subgraphFold(para.path, partitionNum, i, true), Gtmp);
        // transferTime += G_src.loadGraph(G->subBeginPosFirst[i].size() - 1, G->subEdgeListFirst[i].size(), &(G->subBeginPosFirst[i][0]), &(G->subEdgeListFirst[i][0]));
        for (int j = 0; j < partitionNum; j++)
        {
            transferTime += G_dst.loadGraphFromDisk(subgraphFold(para.path, partitionNum, j, false), Gtmp);
            // transferTime += G_dst.loadGraph(G->subBeginPosSecond[j].size() - 1, G->subEdgeListSecond[j].size(), &(G->subBeginPosSecond[j][0]), &(G->subEdgeListSecond[j][0]));
            for (int b = 0; b < para.batchNum; b++)
            {
                int dstOffsets = maxVertexCountInBatch * partitionNum * b;
                startTime = wtime();
                if (b == 0)
                    HRR(cudaMemcpy(D_Position, G_dst.beginPos, sizeof(long long) * (G_dst.vertexCount + 1), cudaMemcpyDeviceToDevice));
                initializeBeginPosition_GPUkernel<<<numBlocks, numThreads>>>(&D_Position[(b % 2) * G->vertexCount], &D_Position[((b + 1) % 2) * G->vertexCount], G_dst, maxVertexCountInBatch * partitionNum * (b + 1), b == 0, b == para.batchNum - 1, dstOffsets);
                HRR(cudaDeviceSynchronize());
                initializeTime += getDeltaTime(startTime);
                *nextVertex = numBlocks * chunckSize + maxVertexCountInBatch * b;
                startTime = wtime();
                edgeCentric_GPUkernel<<<numBlocks, numThreads>>>(G_src,
                                                                 G_dst,
                                                                 globalCount,
                                                                 hashTable,
                                                                 partitionNum,
                                                                 i,
                                                                 nextVertex,
                                                                 maxVertexCountInBatch,
                                                                 &D_Position[(b % 2) * G->vertexCount],
                                                                 &D_Position[((b + 1) % 2) * G->vertexCount],
                                                                 dstOffsets,
                                                                 para.subwarpSize,
                                                                 degreeBoundForClearHashtable,
                                                                 maxVertexCountInBatch * b,
                                                                 vertex32);
                HRR(cudaDeviceSynchronize());
                computeTime_block_largeWorkload += getDeltaTime(startTime);
                if (para.smallWorkload == blockForSmallWorkload)
                {
                    for (int degreeRange = 0; degreeRange <= markerNum; degreeRange++)
                    {
                        int startVertex = breakVertex[(degreeRange + 1) * 32];
                        startVertex = max(int(maxVertexCountInBatch * b), startVertex);
                        if (degreeRange == markerNum)
                            startVertex = (maxVertexCountInBatch * b);
                        *nextVertex = numBlocks * chunckSize + startVertex;
                        int endVertex = breakVertex[degreeRange * 32];
                        if (degreeRange == 0)
                            endVertex = breakVertex[1];
                        startTime = wtime();
                        edgeCentric_GPUkernel<<<numBlocks, numThreads>>>(G_src,
                                                                         G_dst,
                                                                         globalCount,
                                                                         hashTable,
                                                                         partitionNum,
                                                                         i,
                                                                         nextVertex,
                                                                         maxVertexCountInBatch,
                                                                         &D_Position[(b % 2) * G->vertexCount],
                                                                         &D_Position[((b + 1) % 2) * G->vertexCount],
                                                                         dstOffsets,
                                                                         para.subwarpSize,
                                                                         degreeBoundForClearHashtable,
                                                                         startVertex,
                                                                         endVertex);
                        HRR(cudaDeviceSynchronize());
                        computeTime_block[degreeRange] += getDeltaTime(startTime);
                    }
                }
                // cout << i << " " << j << " " << b << " " << G->vertexCount << endl;
                // for (int xxx = G->vertexCount - 5; xxx < G->vertexCount; xxx++)
                //     cout << D_Position[(b % 2) * G->vertexCount + xxx] << ' ' << D_Position[((b + 1) % 2) * G->vertexCount + xxx] << endl;
                // cout << G->vertexCount << endl;
            }

            startTime = wtime();
            mergeBased<<<numBlocks, numThreads>>>(G_src,
                                                  G_dst,
                                                  globalCount,
                                                  partitionNum,
                                                  i,
                                                  nextVertex,
                                                  vertex32,
                                                  vertex1);
            HRR(cudaDeviceSynchronize());
            computeTime_warp_smallWorkload += getDeltaTime(startTime);
            if (para.smallWorkload == blockForSmallWorkload)
            {
                for (int degreeRange = 0; degreeRange < markerNum; degreeRange++)
                {
                    int startVertex = breakVertex[(degreeRange + 1) * 32];
                    *nextVertex = numBlocks * 32 * chunckSize + startVertex;
                    int endVertex = breakVertex[degreeRange * 32];
                    if (degreeRange == 0)
                        endVertex = breakVertex[1];
                    startTime = wtime();
                    mergeBased<<<numBlocks, numThreads>>>(G_src,
                                                          G_dst,
                                                          globalCount,
                                                          partitionNum,
                                                          i,
                                                          nextVertex,
                                                          startVertex,
                                                          endVertex);
                    HRR(cudaDeviceSynchronize());
                    computeTime_warp[degreeRange] += getDeltaTime(startTime);
                }
            }
        }
    }
    cout << *globalCount << ' ';
    cout << initializeTime << " " << computeTime_block_largeWorkload << " " << computeTime_warp_smallWorkload << " " << transferTime << endl;

    if (para.smallWorkload == blockForSmallWorkload)
    {
        for (int degreeRange = 0; degreeRange <= markerNum; degreeRange++)
        {
            cout << computeTime_block[degreeRange] << " " << computeTime_warp[degreeRange] << endl;
        }
    }
    // cout << initializeTime << ' ' << computeTime * partitionNum * partitionNum << " " << transferTime * partitionNum * partitionNum << endl;
    delete Gtmp;
    return 0;
}

static int computeEndPosition(long long beginPos1[], long long beginPos2[], int previousVertex, int lastVertex, long long batchsize, int &breakPoint)
{
    int l = previousVertex, r = lastVertex;
    long long previouscount = beginPos1[previousVertex] + beginPos2[previousVertex];
    while (l < r)
    {
        int mid = (l + r + 1) / 2;
        if (beginPos1[mid] + beginPos2[mid] - previouscount > batchsize)
        {
            r = mid - 1;
        }
        else
        {
            l = mid;
        }
    }
    breakPoint = beginPos1[l] - beginPos1[previousVertex];
    return l;
}

__global__ void wedgeCentric_GPUkernel(long long *beginPosFirst, int *edgeListFirst, long long *beginPosSecond, int *edgeListSecond, unsigned long long *globalCount, int *hashTable, int *nextVertex, int partitionNum, long long maxVertexCount, int lastVertex, int previousVertex)
{
    __shared__ unsigned long long sharedCount;
    __shared__ int nextVertexshared;
    if (threadIdx.x == 0)
        sharedCount = 0;
    __syncthreads();
    unsigned long long count = 0;
    int threadId = threadIdx.x & 0x1f;
    int warpId = (blockDim.x * blockIdx.x + threadIdx.x) / warpSize;
    int warpDim = gridDim.x * blockDim.x / warpSize;
    long long beginPosFirstOffset = beginPosFirst[previousVertex];
    long long beginPosSecondOffset = beginPosSecond[previousVertex];
    for (int vertex = previousVertex + blockIdx.x; vertex < lastVertex;)
    {
        for (auto firstNeighborID = beginPosFirst[vertex]; firstNeighborID < beginPosFirst[vertex + 1]; firstNeighborID += blockDim.x)
        {
            int firstNeighbor = firstNeighborID + threadIdx.x < beginPosFirst[vertex + 1] ? edgeListFirst[firstNeighborID + threadIdx.x - beginPosFirstOffset] : -1;
            // int bound = vertex < firstNeighbor ? vertex : firstNeighbor;
            long long secondOffset = beginPosSecond[vertex] - beginPosSecondOffset;
            int secondDegree = beginPosSecond[vertex + 1] - beginPosSecond[vertex];
            for (auto index = 0; index < secondDegree; index += warpSize)
            {
                int secondNeighborCached = index + threadId < secondDegree ? edgeListSecond[(index + threadId) + secondOffset] : inf;
                int p = 0;
                for (auto thread = 0; thread < warpSize; thread++)
                {
                    int secondNeighbor = __shfl_sync(FULL_MASK, secondNeighborCached, thread);
                    if (secondNeighbor >= vertex)
                    {
                        p = 1;
                        break;
                    }
                    if (secondNeighbor >= firstNeighbor)
                        continue;
                    // count += (firstNeighbor / partitionNum) + (secondNeighbor / partitionNum) * maxVertexCount;
                    // hashTable[threadIdx.x + blockDim.x * blockIdx.x]++;
                    count += atomicAdd(&hashTable[(firstNeighbor / partitionNum) + (secondNeighbor / partitionNum) * maxVertexCount], 1);
                }
                if (p)
                    break;
            }
        }
        __syncthreads();
        loadNextVertex(vertex, nextVertex, nextVertexshared, threadIdx.x == 0, previousVertex);
        // vertex += gridDim.x;

        // if (threadIdx.x == 0)
        // {
        //     vertex = (vertex + 1) % chunckSize != 0 ? vertex + 1 : atomicAdd(nextVertex, chunckSize);
        //     // printf("vertex:%d\n", vertex);
        // }
        // vertex = __shfl_sync(FULL_MASK, vertex, 0);
    }
    atomicAdd(&sharedCount, count);
    __syncthreads();
    if (threadIdx.x == 0)
        atomicAdd(globalCount, sharedCount);
}

int BC_wedge_centric(graph *G, parameter para)
{
    double startTime, transferTime = 0, computeTime = 0, clearTime = 0;
    int numThreads = 1024;
    int numBlocks = para.processorNum;
    // numThreads = 32;
    // numBlocks = 1;
    int partitionNum = para.partitionNum;
    GPUgraph G_first(G->subBeginPosSecond[0].size() - 1, 0);
    GPUgraph G_second(G->subBeginPosSecond[0].size() - 1, 0);
    long long maxVertexCount = ceil(G->vertexCount / (double)partitionNum);

    unsigned long long *globalCount;
    HRR(cudaMallocManaged(&globalCount, sizeof(unsigned long long)));
    *globalCount = 0;
    int *nextVertex;
    HRR(cudaMallocManaged(&nextVertex, sizeof(int)));
    int *hashTable;
    HRR(cudaMalloc(&hashTable, sizeof(int) * maxVertexCount * maxVertexCount));
    int *edgeList;
    int batchSize = G->subEdgeListSecond[0].size() * 2 / para.batchNum + 100;
    HRR(cudaMallocManaged(&edgeList, sizeof(int) * batchSize));

    for (int i = 0; i < partitionNum; i++)
    {
        for (int j = 0; j < partitionNum; j++)
        {
            // load begin position
            long long *CPUbegPos_first = &G->subBeginPosSecond[i][0];
            long long *CPUbegPos_second = &G->subBeginPosSecond[j][0];
            int *CPUedgeList_first = &G->subEdgeListSecond[i][0];
            int *CPUedgeList_second = &G->subEdgeListSecond[j][0];
            transferTime += G_first.loadBeginPos(G->subBeginPosSecond[i].size() - 1, CPUbegPos_first);
            transferTime += G_second.loadBeginPos(G->subBeginPosSecond[j].size() - 1, CPUbegPos_second);
            // for (int a = 0; a < G->subBeginPosSecond[i].size() - 1; a += 1000)
            //     cout << CPUbegPos_first[a + 1] - CPUbegPos_first[a] << endl;
            int previousEnd = 0;
            int thisEnd = 0;
            int breakPoint = 0;
            // clean the hashtable
            startTime = wtime();
            HRR(cudaMemset(hashTable, 0, maxVertexCount * maxVertexCount * sizeof(int)));
            HRR(cudaDeviceSynchronize());
            clearTime += getDeltaTime(startTime);
            for (auto ttt = 1;; ttt++)
            {
                thisEnd = computeEndPosition(CPUbegPos_first, CPUbegPos_second, previousEnd, G_first.vertexCount, batchSize, breakPoint);
                if (thisEnd == previousEnd)
                    break;
                *nextVertex = previousEnd + numBlocks * chunckSize;
                startTime = wtime();
                HRR(cudaMemcpy(edgeList, &CPUedgeList_first[CPUbegPos_first[previousEnd]], sizeof(int) * (CPUbegPos_first[thisEnd] - CPUbegPos_first[previousEnd]), cudaMemcpyHostToDevice));
                HRR(cudaMemcpy(&edgeList[breakPoint], &CPUedgeList_second[CPUbegPos_second[previousEnd]], sizeof(int) * (CPUbegPos_second[thisEnd] - CPUbegPos_second[previousEnd]), cudaMemcpyHostToDevice));
                transferTime += getDeltaTime(startTime);
                wedgeCentric_GPUkernel<<<numBlocks, numThreads>>>(G_first.beginPos, edgeList, G_second.beginPos, edgeList + breakPoint, globalCount, hashTable, nextVertex, partitionNum, maxVertexCount, thisEnd, previousEnd);
                HRR(cudaDeviceSynchronize());
                computeTime += getDeltaTime(startTime);

                previousEnd = thisEnd;
            }
        }
    }
    cout << *globalCount << ' ';
    cout << clearTime << " " << computeTime << ' ' << transferTime << endl;

    return 0;
}

int BC_GPU(graph *G, parameter para)
{
    cudaSetDevice(0);
    // int a, b;
    // HRR(cudaOccupancyMaxPotentialBlockSize(&a, &b, edgeCentric_GPUkernel));
    // cout << a << " " << b << endl;
    // cout << "numblocks" << initializeCudaPara(1, 1024, edgeCentric_GPUkernel) << endl;

    if (para.varient == edgecentric)
        BC_edge_centric(G, para);
    else
        BC_wedge_centric(G, para);
}
