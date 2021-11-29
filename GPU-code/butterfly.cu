#include <iostream>
#include "graph.h"
#include "wtime.h"
#include "util.h"
#include "countingAlgorithm/sortBased.cuh"
#include "countingAlgorithm/hashBased.cuh"
#include "countingAlgorithm/heapBased.cuh"
#include "countingAlgorithm/mergeBased.cuh"
#include "countingAlgorithm/D_heapBased.cuh"
#include "countingAlgorithm/hashPartition.cuh"
#include "countingAlgorithm/hashCentric.cuh"
#include "globalPara.h"
#include <cooperative_groups.h>
#include <cooperative_groups/memcpy_async.h>
#include <cooperative_groups/reduce.h>
// #include <cooperative_groups/scan.h>
#define dev 1

using namespace std;
using namespace cooperative_groups;

__global__ void test(unsigned long long *count)
{
    if (this_thread_block().thread_rank() < 100)
        atomicAdd(count, 1);

    this_thread_block().sync();
    // __syncthreads();
    int x = *count;
    // __syncthreads();
    this_thread_block().sync();
    *count = 0;
    // this_thread_block().sync();
    __syncthreads();
    atomicAdd(count, x);
}

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

int BC_subgraph_centric(graph *G)
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
    int num_frT = 6, num_srT = 2;
    int *Sorted_List;
    int *host_list;
    HRR(cudaMallocManaged((void **)&Sorted_List, sizeof(int) * (G->edgeCount * 2)));
    int total_size = sizeof(int) * (G->edgeCount * 2);
    int *perVertexCount;
    // int * perVertexCount=new int[G->uCount+G->vCount+1];
    HRR(cudaMallocManaged((void **)&perVertexCount, sizeof(int) * (G->uCount + G->vCount + 1)));

    unsigned long long *globalCount;
    HRR(cudaMallocManaged(&globalCount, sizeof(unsigned long long)));
    *globalCount = 0;
    int *hashTable;
    HRR(cudaMalloc(&hashTable, sizeof(int) * (G->uCount + G->vCount) * numBlocks));

    test<<<1, 1024>>>(globalCount);
    HRR(cudaDeviceSynchronize());
    cout << "here " << *globalCount << endl;

    if (0)
    {

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
                startTime = wtime();
                HRR(cudaMemcpy(D_beginPos_second, &(G->subBeginPosSecond[i][0]), sizeof(long long) * (G->subBeginPosSecond[i].size()), cudaMemcpyHostToDevice));
                HRR(cudaMemcpy(D_edgeList_second, &(G->subEdgeListSecond[i][0]), sizeof(int) * (G->subEdgeListSecond[i].size()), cudaMemcpyHostToDevice));
                // *globalCount = 0;
                transferTime += wtime() - startTime;
                startTime = wtime();
                hashPartition<<<numBlocks, numThreads>>>(D_beginPos_first, D_edgeList_first, D_beginPos_second, D_edgeList_second, globalCount, perVertexCount, hashTable, 0, G->subBeginPosFirst[j].size() - 1, G->length, G->partitionNum, j);
                HRR(cudaDeviceSynchronize());
                computeTime += wtime() - startTime;
                // cout << G->uCount + G->vCount << endl;
            }
        }
        cout << *globalCount << endl;
        exectionTime = wtime() - startTime;
        cout << transferTime << ' ' << computeTime << endl;
        // cout << *globalCount << ' ' << exectionTime << endl;
    }

    cout << endl;

    // HRR(cudaMemcpy((void **)&host_list,(void **)&Sorted_List,sizeof(int)*(G->edgeCount), cudaMemcpyDeviceToHost));

    HRR(cudaFree(D_beginPos));
    HRR(cudaFree(D_edgeList));
    HRR(cudaFree(Sorted_List));

    // delete(perVertexCount);
    return 0;
}

int BC_hashtable_centric(graph *G)
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

// *globalCount = 0;
// startTime = wtime();
// *nextVertex = numBlocks;
// hashBasedButterflyCounting<<<numBlocks, 1024>>>(D_beginPos, D_edgeList, G->uCount, G->vCount, globalCount, perVertexCount, hashTable, 0, G->breakVertex32, nextVertex);
// HRR(cudaDeviceSynchronize());
// exectionTime = wtime() - startTime;
// cout << *globalCount << ' ' << exectionTime << endl;
// cout << "run degree<32 with merge： vertex num: " << G->uCount + G->vCount - G->breakVertex32 << endl;
// startTime = wtime();
// mergeBasedButterflyCounting<<<1024, blockSize>>>(D_beginPos, D_edgeList, G->uCount, G->vCount, globalCount, perVertexCount, hashTable, G->breakVertex32, G->uCount + G->vCount);
// HRR(cudaDeviceSynchronize());
// exectionTime = wtime() - startTime;
// cout << *globalCount << ' ' << exectionTime << endl;
// *globalCount = 0;

// if (0)
// {
//     //for test
//     if (0) //hash>10
//     {
//         cout << "run all vertex with hash" << endl;
//         startTime = wtime();
//         hashBasedButterflyCounting<<<numBlocks, 1024>>>(D_beginPos, D_edgeList, G->uCount, G->vCount, globalCount, perVertexCount, hashTable, 0, G->uCount + G->vCount);
//         HRR(cudaDeviceSynchronize());
//         exectionTime = wtime() - startTime;
//         cout << *globalCount << ' ' << exectionTime << endl;
//         *globalCount = 0;
//     }

//     if (0) //heap<10
//     {
//         cout << "run degree<10 with heap： vertex num: " << G->uCount + G->vCount - G->breakVertex10 << endl;
//         startTime = wtime();
//         heapBasedButterflyCounting<<<256, 256>>>(D_beginPos, D_edgeList, G->uCount, G->vCount, globalCount, perVertexCount, hashTable, G->breakVertex10, G->uCount + G->vCount);
//         HRR(cudaDeviceSynchronize());
//         exectionTime = wtime() - startTime;
//         cout << *globalCount << ' ' << exectionTime << endl;
//         *globalCount = 0;
//     }
//     if (0) //heap<10
//     {
//         cout << "run degree<10 with heap on warp： vertex num: " << G->uCount + G->vCount - G->breakVertex10 << endl;
//         startTime = wtime();
//         heapBasedButterflyCounting_byWarp<<<512, 1024>>>(D_beginPos, D_edgeList, G->uCount, G->vCount, globalCount, perVertexCount, hashTable, G->breakVertex10, G->uCount + G->vCount);
//         HRR(cudaDeviceSynchronize());
//         exectionTime = wtime() - startTime;
//         cout << *globalCount << ' ' << exectionTime << endl;
//         *globalCount = 0;
//     }

//     if (1) //merge<32
//     {
//         cout << "run degree<32 with merge： vertex num: " << G->uCount + G->vCount - G->breakVertex32 << endl;
//         startTime = wtime();
//         mergeBasedButterflyCounting<<<1024, blockSize>>>(D_beginPos, D_edgeList, G->uCount, G->vCount, globalCount, perVertexCount, hashTable, G->breakVertex32, G->uCount + G->vCount);
//         HRR(cudaDeviceSynchronize());
//         exectionTime = wtime() - startTime;
//         cout << *globalCount << ' ' << exectionTime << endl;
//         *globalCount = 0;
//     }
//     if (1) //merge<10
//     {
//         cout << "run degree<10 with merge： vertex num: " << G->uCount + G->vCount - G->breakVertex10 << endl;
//         startTime = wtime();
//         mergeBasedButterflyCounting<<<1024, blockSize>>>(D_beginPos, D_edgeList, G->uCount, G->vCount, globalCount, perVertexCount, hashTable, G->breakVertex10, G->uCount + G->vCount);
//         HRR(cudaDeviceSynchronize());
//         exectionTime = wtime() - startTime;
//         cout << *globalCount << ' ' << exectionTime << endl;
//         *globalCount = 0;
//     }

//     if (1) //hash<32
//     {
//         cout << "run degree<32 with hash" << endl;
//         startTime = wtime();
//         hashBasedButterflyCounting<<<numBlocks, 1024>>>(D_beginPos, D_edgeList, G->uCount, G->vCount, globalCount, perVertexCount, hashTable, G->breakVertex32, G->uCount + G->vCount);
//         HRR(cudaDeviceSynchronize());
//         exectionTime = wtime() - startTime;
//         cout << *globalCount << ' ' << exectionTime << endl;
//         *globalCount = 0;
//     }
//     if (1) //hash<10
//     {
//         cout << "run degree<10 with hash" << endl;
//         startTime = wtime();
//         hashBasedButterflyCounting<<<numBlocks, 1024>>>(D_beginPos, D_edgeList, G->uCount, G->vCount, globalCount, perVertexCount, hashTable, G->breakVertex10, G->uCount + G->vCount);
//         HRR(cudaDeviceSynchronize());
//         exectionTime = wtime() - startTime;
//         cout << *globalCount << ' ' << exectionTime << endl;
//         *globalCount = 0;
//     }

//     if (0) //for debug
//     {
//         for (int i = 71869 - 2; i <= 71869; i++)
//         {
//             *globalCount = 0;
//             startTime = wtime();
//             mergeBasedButterflyCounting<<<1, blockSize>>>(D_beginPos, D_edgeList, G->uCount, G->vCount, globalCount, perVertexCount, hashTable, i, i + 1);
//             HRR(cudaDeviceSynchronize());
//             exectionTime = wtime() - startTime;
//             int res1 = *globalCount;
//             *globalCount = 0;
//             startTime = wtime();
//             heapBasedButterflyCounting<<<numBlocks, 1024>>>(D_beginPos, D_edgeList, G->uCount, G->vCount, globalCount, perVertexCount, hashTable, i, i + 1);
//             HRR(cudaDeviceSynchronize());
//             exectionTime = wtime() - startTime;
//             int res2 = *globalCount;
//             if (res1 != res2)
//                 printf("%d,%d,%d\n", res1, res2, i);
//             *globalCount = 0;
//         }
//     }
//     if (0) //heap<10
//     {
//         cout << "run degree<10 with D_heap" << endl;
//         startTime = wtime();
//         D_heapBasedButterflyCounting<<<numBlocks, 128>>>(D_beginPos, D_edgeList, Sorted_List, total_size, num_frT, num_srT, G->uCount, G->vCount, globalCount, perVertexCount, hashTable, G->breakVertex10, G->uCount + G->vCount);
//         HRR(cudaDeviceSynchronize());
//         exectionTime = wtime() - startTime;
//         cout << *globalCount << ' ' << exectionTime << endl;
//         *globalCount = 0;
//     }
//     if (0) //heap<100
//     {
//         cout << "run all vertex with D_heap" << endl;
//         startTime = wtime();
//         D_heapBasedButterflyCounting<<<numBlocks, 128>>>(D_beginPos, D_edgeList, Sorted_List, total_size, num_frT, num_srT, G->uCount, G->vCount, globalCount, perVertexCount, hashTable, 0, G->uCount + G->vCount);
//         HRR(cudaDeviceSynchronize());
//         exectionTime = wtime() - startTime;
//         cout << *globalCount << ' ' << exectionTime << endl;
//         *globalCount = 0;
//     }
//     if (0) //hash>32
//     {
//         startTime = wtime();
//         hashBasedButterflyCounting<<<numBlocks, 1024>>>(D_beginPos, D_edgeList, G->uCount, G->vCount, globalCount, perVertexCount, hashTable, 0, G->breakVertex32);
//         HRR(cudaDeviceSynchronize());
//         exectionTime = wtime() - startTime;
//         cout << ' ' << exectionTime;
//     }
//     if (0) //hash<32
//     {
//         startTime = wtime();
//         hashBasedButterflyCounting<<<numBlocks, 1024>>>(D_beginPos, D_edgeList, G->uCount, G->vCount, globalCount, perVertexCount, hashTable, G->breakVertex32, G->uCount + G->vCount);
//         HRR(cudaDeviceSynchronize());
//         exectionTime = wtime() - startTime;
//         cout << ' ' << exectionTime;
//     }
//     if (0) //sort<32
//     {
//         startTime = wtime();
//         sortBasedButterflyCounting<<<numBlocks, 1024>>>(D_beginPos, D_edgeList, G->uCount, G->vCount, globalCount, perVertexCount, hashTable, G->breakVertex32, G->uCount + G->vCount);
//         HRR(cudaDeviceSynchronize());
//         exectionTime = wtime() - startTime;
//         cout << ' ' << exectionTime;
//     }
//     if (0) //10<hash<32
//     {
//         startTime = wtime();
//         hashBasedButterflyCounting<<<numBlocks, 1024>>>(D_beginPos, D_edgeList, G->uCount, G->vCount, globalCount, perVertexCount, hashTable, G->breakVertex32, G->breakVertex10);
//         HRR(cudaDeviceSynchronize());
//         exectionTime = wtime() - startTime;
//         cout << ' ' << exectionTime;
//     }
// }

// if (0) //combined several method
// {
//     startTime = wtime();
//     hashBasedButterflyCounting<<<numBlocks, 1024>>>(D_beginPos, D_edgeList, G->uCount, G->vCount, globalCount, perVertexCount, hashTable, 0, G->breakVertex10);
//     HRR(cudaDeviceSynchronize());
//     exectionTime = wtime() - startTime;
//     cout << *globalCount << ' ' << exectionTime << endl;

//     startTime = wtime();
//     heapBasedButterflyCounting<<<numBlocks, 128>>>(D_beginPos, D_edgeList, G->uCount, G->vCount, globalCount, perVertexCount, hashTable, G->breakVertex10, G->uCount + G->vCount);
//     HRR(cudaDeviceSynchronize());
//     exectionTime = wtime() - startTime;
//     cout << *globalCount << ' ' << exectionTime << endl;
//     *globalCount = 0;
// }

// *globalCount=0;
// startTime=wtime();
// sortBasedButterflyCounting<<<numBlocks,1024>>>(D_beginPos,D_edgeList,G->uCount,G->vCount,globalCount,perVertexCount2,hashTable,G->breakVertex32,G->vertexCount);
// HRR(cudaDeviceSynchronize());
// exectionTime=wtime()-startTime;
// cout<<*globalCount<<' '<<exectionTime;
// for (int i=G->breakVertex32;i<G->breakVertex10;i++)
//     if (perVertexCount[i]!=perVertexCount2[i])
//         cout<<i<<endl;