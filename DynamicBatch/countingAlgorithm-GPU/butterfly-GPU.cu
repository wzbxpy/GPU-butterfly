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
#define chunckSize 1
#define warpSize 32
#define FULL_MASK 0xffffffff
#define inf 0x7fffffff

using namespace std;
// using namespace cooperative_groups;

template <class T>
int initializeCudaPara(int deviceId, int numThreads, T func)
{
    cudaSetDevice(deviceId);
    int numBlocksPerSm = 0;
    // Number of threads my_kernel will be launched with
    cudaDeviceProp deviceProp;
    cudaGetDeviceProperties(&deviceProp, deviceId);
    cudaOccupancyMaxActiveBlocksPerMultiprocessor(&numBlocksPerSm, func, numThreads, 0);
    // cout << deviceProp.multiProcessorCount << "  " << numBlocksPerSm << endl;
    int numBlocks = deviceProp.multiProcessorCount * numBlocksPerSm;
    return numBlocks;
}

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
        HRR(cudaMalloc(&beginPos, sizeof(long long) * (vertexCount + 1)));
        HRR(cudaMalloc(&edgeList, sizeof(int) * edgeCount));
    }
    double loadGraph(int vertexNum, long long edgeNum, long long *CPU_beginPos, int *CPU_edgelist)
    {
        vertexCount = vertexNum;
        edgeCount = edgeNum;
        double startTime = wtime();
        HRR(cudaMemcpy(beginPos, CPU_beginPos, sizeof(long long) * (vertexCount + 1), cudaMemcpyHostToDevice));
        HRR(cudaMemcpy(edgeList, CPU_edgelist, sizeof(int) * (edgeCount), cudaMemcpyHostToDevice));
        return getDeltaTime(startTime);
    }
    double loadBeginPos(int vertexNum, long long *CPU_beginPos)
    {
        vertexCount = vertexNum;
        double startTime = wtime();
        HRR(cudaMemcpy(beginPos, CPU_beginPos, sizeof(long long) * (vertexCount + 1), cudaMemcpyHostToDevice));
        return getDeltaTime(startTime);
    }
};

__device__ void loadNextVertex(int &vertex, int *nextVertex, int &nextVertexshared)
{
    if ((vertex + 1) % chunckSize != 0)
    {
        vertex++;
    }
    else
    {
        if (threadIdx.x == 0)
            nextVertexshared = atomicAdd(nextVertex, chunckSize);
        __syncthreads();
        vertex = nextVertexshared;
    }
}

__global__ void initializeBeginPosition_GPUkernel(long long beginPosition[], long long endPosition[], GPUgraph G, int boundary, bool isFirst, bool isLast)
{
    int threadId = threadIdx.x + blockIdx.x * blockDim.x;
    if (isFirst) // The first begin position need to be initialized
    {
        for (int vertex = threadId; vertex < G.vertexCount; vertex += blockDim.x * gridDim.x)
            beginPosition[vertex] = G.beginPos[vertex];
    }
    if (isLast) // The last part of end position can be directly obtained
    {
        for (int vertex = threadId; vertex < G.vertexCount; vertex += blockDim.x * gridDim.x)
            endPosition[vertex] = G.beginPos[vertex + 1];
    }
    else
    {
        for (int vertex = threadId; vertex < G.vertexCount; vertex += blockDim.x * gridDim.x)
        {
            long long pos;
            for (pos = beginPosition[vertex]; pos < G.beginPos[vertex + 1]; pos++)
            {
                if (G.edgeList[pos] >= boundary)
                    break;
            }
            endPosition[vertex] = pos;
        }
    }
}

__global__ void
edgeCentric_GPUkernel(GPUgraph G_src, GPUgraph G_dst, unsigned long long *globalCount, int *hashTable, int startVertex, int endVertex, int partitionNum, int vertexOffsets, int *nextVertex, long long maxVertexCount, long long beginPosition[], long long endPosition[], int dstOffsets)
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

    for (int vertex = startVertex + blockIdx.x * chunckSize; vertex < endVertex;)
    {
        auto vertexDegree = G_src.beginPos[vertex + 1] - G_src.beginPos[vertex];
        // put the two hop neighbor of vertex into hash map
        for (auto oneHopNeighborID = G_src.beginPos[vertex] + threadIdx.x / 32; oneHopNeighborID < G_src.beginPos[vertex + 1]; oneHopNeighborID += 32)
        {
            int oneHopNeighbor = G_src.edgeList[oneHopNeighborID];
            int bound = vertex * partitionNum + vertexOffsets < oneHopNeighbor ? vertex * partitionNum + vertexOffsets : oneHopNeighbor;
            for (auto twoHopNeighborID = beginPosition[oneHopNeighbor] + threadIdx.x % 32; twoHopNeighborID < endPosition[oneHopNeighbor]; twoHopNeighborID += 32)
            {
                int twoHopNeighbor = G_dst.edgeList[twoHopNeighborID];
                if (twoHopNeighbor >= bound)
                    break;
                count += atomicAdd(&hashTable[((twoHopNeighbor - dstOffsets) / partitionNum)], 1);
            }
        }
        __syncthreads();

        // reset the hash map
        if (vertexDegree * vertexDegree > G_dst.vertexCount) // choose the lower costs method
        // if (1)
        {
            for (int i = threadIdx.x; i < maxVertexCount; i += blockDim.x)
            {
                hashTable[i] = 0;
            }
        }
        else
        {
            for (auto oneHopNeighborID = G_src.beginPos[vertex] + threadIdx.x / 32; oneHopNeighborID < G_src.beginPos[vertex + 1]; oneHopNeighborID += 32)
            {
                int oneHopNeighbor = G_src.edgeList[oneHopNeighborID];
                int bound = vertex * partitionNum + vertexOffsets < oneHopNeighbor ? vertex * partitionNum + vertexOffsets : oneHopNeighbor;
                for (auto twoHopNeighborID = beginPosition[oneHopNeighbor] + threadIdx.x % 32; twoHopNeighborID < endPosition[oneHopNeighbor]; twoHopNeighborID += 32)
                {
                    int twoHopNeighbor = G_dst.edgeList[twoHopNeighborID];
                    if (twoHopNeighbor >= bound)
                        break;
                    hashTable[((twoHopNeighbor - dstOffsets) / partitionNum)] = 0;
                }
            }
        }

        __syncthreads();
        loadNextVertex(vertex, nextVertex, nextVertexshared);
        // vertex += gridDim.x;
    }

    atomicAdd(&sharedCount, count);
    __syncthreads();
    if (threadIdx.x == 0)
        atomicAdd(globalCount, sharedCount);
}

int BC_edge_centric(graph *G, parameter para)
{
    double startTime, transferTime = 0, computeTime = 0, initializeTime = 0;

    int numThreads = 1024;
    int numBlocks = para.processorNum;
    int partitionNum = para.partitionNum;
    // numBlocks = 1;

    // long long *D_beginPos;
    // int *D_edgeList;
    // HRR(cudaMalloc(&D_beginPos, sizeof(long long) * (G->vertexCount + 1)));
    // HRR(cudaMalloc(&D_edgeList, sizeof(int) * (G->edgeCount)));
    // startTime = wtime();
    // HRR(cudaMemcpy(D_beginPos, G->beginPos, sizeof(long long) * (G->vertexCount + 1), cudaMemcpyHostToDevice));
    // HRR(cudaMemcpy(D_edgeList, G->edgeList, sizeof(int) * (G->edgeCount), cudaMemcpyHostToDevice));
    // exectionTime = getDeltaTime(startTime);
    // cout << "load graph elapsed time: " << exectionTime << endl;

    unsigned long long *globalCount;
    HRR(cudaMallocManaged(&globalCount, sizeof(unsigned long long)));
    *globalCount = 0;
    int *nextVertex;
    HRR(cudaMallocManaged(&nextVertex, sizeof(int)));
    int *hashTable;
    long long maxVertexCountInBatch = ceil(G->vertexCount / (double)para.batchNum / (double)partitionNum);
    HRR(cudaMalloc(&hashTable, maxVertexCountInBatch * numBlocks * sizeof(int)));
    GPUgraph G_src(G->subBeginPosFirst[0].size() - 1, G->subEdgeListFirst[0].size());
    GPUgraph G_dst(G->subBeginPosSecond[0].size() - 1, G->subEdgeListSecond[0].size());

    long long *D_Position;
    HRR(cudaMalloc(&D_Position, sizeof(long long) * G->vertexCount * 2));

    startTime = wtime();
    for (int i = 0; i < partitionNum; i++)
    {
        transferTime += G_src.loadGraph(G->subBeginPosFirst[i].size() - 1, G->subEdgeListFirst[i].size(), &(G->subBeginPosFirst[i][0]), &(G->subEdgeListFirst[i][0]));
        for (int j = 0; j < partitionNum; j++)
        {
            transferTime += G_dst.loadGraph(G->subBeginPosSecond[j].size() - 1, G->subEdgeListSecond[j].size(), &(G->subBeginPosSecond[j][0]), &(G->subEdgeListSecond[j][0]));
            for (int b = 0; b < para.batchNum; b++)
            {
                startTime = wtime();
                initializeBeginPosition_GPUkernel<<<numBlocks, numThreads>>>(&D_Position[(b % 2) * G->vertexCount], &D_Position[((b + 1) % 2) * G->vertexCount], G_dst, maxVertexCountInBatch * partitionNum * (b + 1), b == 0, b == para.batchNum - 1);
                HRR(cudaDeviceSynchronize());
                initializeTime += getDeltaTime(startTime);
                *nextVertex = numBlocks * chunckSize;
                startTime = wtime();
                edgeCentric_GPUkernel<<<numBlocks, numThreads>>>(G_src, G_dst, globalCount, hashTable, 0, 100000, G->partitionNumSrc, i, nextVertex, maxVertexCountInBatch, &D_Position[(b % 2) * G->vertexCount], &D_Position[((b + 1) % 2) * G->vertexCount], maxVertexCountInBatch * partitionNum * b);
                HRR(cudaDeviceSynchronize());
                computeTime += getDeltaTime(startTime);
                // cout << G->vertexCount << endl;
            }
        }
    }
    cout << *globalCount << ' ';
    cout << initializeTime + computeTime << " " << transferTime << endl;

    // cout << initializeTime << ' ' << computeTime * partitionNum * partitionNum << " " << transferTime * partitionNum * partitionNum << endl;

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
        loadNextVertex(vertex, nextVertex, nextVertexshared);
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
    cout << clearTime + computeTime << ' ' << transferTime << endl;

    return 0;
}

int BC_GPU(graph *G, parameter para)
{
    cudaSetDevice(1);
    // int a, b;
    // HRR(cudaOccupancyMaxPotentialBlockSize(&a, &b, edgeCentric_GPUkernel));
    // cout << a << " " << b << endl;
    cout << "numblocks" << initializeCudaPara(1, 1024, edgeCentric_GPUkernel) << endl;

    if (para.varient == edgecentric)
        BC_edge_centric(G, para);
    else
        BC_wedge_centric(G, para);
}
