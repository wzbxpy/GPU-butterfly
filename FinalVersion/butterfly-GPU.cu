#include <iostream>
#include "graph.h"
#include "wtime.h"
#include "util.h"
#include "countingAlgorithm-GPU/hashPartition.cuh"
#include "countingAlgorithm-GPU/hashCentric.cuh"
#define dev 1

using namespace std;

template <class T>
int initializeCudaPara(int deviceId, int numThreads, T func)
{
    cudaSetDevice(deviceId);
    int numBlocksPerSm = 0;
    // Number of threads my_kernel will be launched with
    cudaDeviceProp deviceProp;
    cudaGetDeviceProperties(&deviceProp, deviceId);
    cudaOccupancyMaxActiveBlocksPerMultiprocessor(&numBlocksPerSm, func, numThreads, 0);
    cout << deviceProp.multiProcessorCount << "  " << numBlocksPerSm << endl;
    int numBlocks = deviceProp.multiProcessorCount * numBlocksPerSm;
    return numBlocks;
}

int BC_edge_centric(graph *G)
{
    double startTime, exectionTime;

    int numThreads = 1024;
    int numBlocks = initializeCudaPara(dev, numThreads, hashCentric);
    numBlocks = 128;

    long long *D_beginPos;
    int *D_edgeList;

    HRR(cudaMalloc(&D_beginPos, sizeof(long long) * (G->uCount + G->vCount + 1)));
    HRR(cudaMalloc(&D_edgeList, sizeof(int) * (G->edgeCount)));
    startTime = wtime();
    HRR(cudaMemcpy(D_beginPos, G->beginPos, sizeof(long long) * (G->uCount + G->vCount + 1), cudaMemcpyHostToDevice));
    HRR(cudaMemcpy(D_edgeList, G->edgeList, sizeof(int) * (G->edgeCount), cudaMemcpyHostToDevice));
    exectionTime = wtime() - startTime;
    cout << "load graph elapsed time: " << exectionTime << endl;
    int total_size = sizeof(int) * (G->edgeCount * 2);
    int *perVertexCount;
    HRR(cudaMallocManaged((void **)&perVertexCount, sizeof(int) * (G->uCount + G->vCount + 1)));

    unsigned long long *globalCount;
    HRR(cudaMallocManaged(&globalCount, sizeof(unsigned long long)));
    *globalCount = 0;
    int *nextVertex;
    HRR(cudaMallocManaged(&nextVertex, sizeof(int)));
    int *hashTable;
    HRR(cudaMalloc(&hashTable, sizeof(int) * (G->uCount + G->vCount) * numBlocks));

    long long *D_beginPos_first;
    int *D_edgeList_first;
    long long *D_beginPos_second;
    int *D_edgeList_second;

    HRR(cudaMalloc(&D_beginPos_first, sizeof(long long) * G->subBeginPosFirst[0].size()));
    HRR(cudaMalloc(&D_edgeList_first, sizeof(int) * (G->subEdgeListFirst[0].size())));
    HRR(cudaMalloc(&D_beginPos_second, sizeof(long long) * (G->uCount + G->vCount + 1)));
    HRR(cudaMalloc(&D_edgeList_second, sizeof(int) * (G->subEdgeListSecond[0].size())));

    startTime = wtime();
    double transferTime = 0, computeTime = 0;
    for (int j = 0; j < G->partitionNum; j++)
    // for (int j = 0; j < 1; j++)
    {

        HRR(cudaMemcpy(D_beginPos_first, &(G->subBeginPosFirst[j][0]), sizeof(long long) * (G->subBeginPosFirst[j].size()), cudaMemcpyHostToDevice));
        HRR(cudaMemcpy(D_edgeList_first, &(G->subEdgeListFirst[j][0]), sizeof(int) * (G->subEdgeListFirst[j].size()), cudaMemcpyHostToDevice));
        for (int i = 0; i < G->partitionNum; i++)
        {
            // cout << i << ' ' << j << endl;
            *nextVertex = numBlocks;
            startTime = wtime();
            HRR(cudaMemcpy(D_beginPos_second, &(G->subBeginPosSecond[i][0]), sizeof(long long) * (G->subBeginPosSecond[i].size()), cudaMemcpyHostToDevice));
            HRR(cudaMemcpy(D_edgeList_second, &(G->subEdgeListSecond[i][0]), sizeof(int) * (G->subEdgeListSecond[i].size()), cudaMemcpyHostToDevice));
            // *globalCount = 0;
            transferTime += wtime() - startTime;
            startTime = wtime();
            hashPartition<<<numBlocks, numThreads>>>(D_beginPos_first, D_edgeList_first, D_beginPos_second, D_edgeList_second, globalCount, perVertexCount, hashTable, 0, G->subBeginPosFirst[j].size() - 1, G->length, G->partitionNum, j, nextVertex);
            HRR(cudaDeviceSynchronize());
            computeTime += wtime() - startTime;
            // cout << G->uCount + G->vCount << endl;
        }
    }
    cout << *globalCount << endl;
    exectionTime = wtime() - startTime;
    cout << transferTime << ' ' << computeTime << endl;
    // cout << *globalCount << ' ' << exectionTime << endl;

    cout << endl;

    // HRR(cudaMemcpy((void **)&host_list,(void **)&Sorted_List,sizeof(int)*(G->edgeCount), cudaMemcpyDeviceToHost));

    HRR(cudaFree(D_beginPos));
    HRR(cudaFree(D_edgeList));

    // delete(perVertexCount);
    return 0;
}

int BC_wedge_centric(graph *G)
{

    double startTime, exectionTime;

    long long *D_beginPos;
    int *D_edgeList;
    int numThreads = 1024;
    int numBlocks = initializeCudaPara(dev, numThreads, hashCentric);

    HRR(cudaMalloc(&D_beginPos, sizeof(long long) * (G->uCount + G->vCount + 1)));
    HRR(cudaMalloc(&D_edgeList, sizeof(int) * (G->edgeCount)));
    startTime = wtime();
    HRR(cudaMemcpy(D_beginPos, G->beginPos, sizeof(long long) * (G->uCount + G->vCount + 1), cudaMemcpyHostToDevice));
    HRR(cudaMemcpy(D_edgeList, G->edgeList, sizeof(int) * (G->edgeCount), cudaMemcpyHostToDevice));
    exectionTime = wtime() - startTime;
    cout << "load graph elapsed time: " << exectionTime << endl;
    unsigned long long *globalCount;
    HRR(cudaMallocManaged(&globalCount, sizeof(unsigned long long)));
    *globalCount = 0;
    int *nextVertex;
    HRR(cudaMallocManaged(&nextVertex, sizeof(int)));
    int *hashTable;
    HRR(cudaMalloc(&hashTable, sizeof(int) * G->length * G->length));

    long long *D_beginPos_first;
    int *D_edgeList_first;
    long long *D_beginPos_second;
    int *D_edgeList_second;

    HRR(cudaMalloc(&D_beginPos_first, sizeof(long long) * (G->uCount + G->vCount + 1)));
    HRR(cudaMalloc(&D_edgeList_first, sizeof(int) * (G->subEdgeListSecond[0].size())));
    HRR(cudaMalloc(&D_beginPos_second, sizeof(long long) * (G->uCount + G->vCount + 1)));
    HRR(cudaMalloc(&D_edgeList_second, sizeof(int) * (G->subEdgeListSecond[0].size())));

    cout << G->vertexCount / 100 << " number of vetrex" << endl;
    *globalCount = 0;
    startTime = wtime();
    double transferTime = 0, computeTime = 0;
    for (int i = 0; i < G->partitionNum; i++)
    {
        HRR(cudaMemcpy(D_beginPos_first, &(G->subBeginPosSecond[i][0]), sizeof(long long) * (G->subBeginPosSecond[i].size()), cudaMemcpyHostToDevice));
        HRR(cudaMemcpy(D_edgeList_first, &(G->subEdgeListSecond[i][0]), sizeof(int) * (G->subEdgeListSecond[i].size()), cudaMemcpyHostToDevice));
        for (int j = 0; j < G->partitionNum; j++)
        {
            // cout << i << ' ' << j << endl;
            *nextVertex = numBlocks;
            startTime = wtime();
            HRR(cudaMemcpy(D_beginPos_second, &(G->subBeginPosSecond[j][0]), sizeof(long long) * (G->subBeginPosSecond[j].size()), cudaMemcpyHostToDevice));
            HRR(cudaMemcpy(D_edgeList_second, &(G->subEdgeListSecond[j][0]), sizeof(int) * (G->subEdgeListSecond[j].size()), cudaMemcpyHostToDevice));
            // *globalCount = 0;
            transferTime += wtime() - startTime;
            startTime = wtime();
            // clearHashTable<<<G->length, 1024>>>(hashTable, G->length);
            // HRR(cudaDeviceSynchronize());
            int startVertex = 0;
            void *kernelArgs[] = {&D_beginPos_first, &D_edgeList_first, &D_beginPos_second, &D_edgeList_second, &globalCount, &hashTable, &startVertex, &G->vertexCount, &G->length, &G->partitionNum};
            cudaLaunchCooperativeKernel((void *)hashCentric, numBlocks, numThreads, kernelArgs);
            // hashCentric<<<numBlocks, 1024>>>(D_beginPos_first, D_edgeList_first, D_beginPos_second, D_edgeList_second, globalCount, hashTable, 0, G->uCount + G->vCount, G->length, G->partitionNum);
            HRR(cudaDeviceSynchronize());
            computeTime += wtime() - startTime;
            // cout << *globalCount << endl;
            // cout << G->uCount + G->vCount << endl;
        }
    }
    cout << *globalCount << endl;
    exectionTime = wtime() - startTime;
    cout << transferTime << ' ' << computeTime << endl;
    // cout << *globalCount << ' ' << exectionTime << endl;

    HRR(cudaFree(D_beginPos));
    HRR(cudaFree(D_edgeList));

    return 0;
}

int BC_GPU(graph *G, bool isEdgeCentric)
{
    if (isEdgeCentric)
        BC_edge_centric(G);
    else
        BC_wedge_centric(G);
}