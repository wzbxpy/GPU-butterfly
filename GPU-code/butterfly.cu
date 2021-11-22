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
#include "globalPara.h"

#define blocknumber 128

using namespace std;

int BC_subgraph_centric(graph *G)
{

    double startTime, exectionTime;

    long long *D_beginPos;
    int *D_edgeList;

    cudaSetDevice(1);
    HRR(cudaMalloc(&D_beginPos, sizeof(long long) * (G->uCount + G->vCount + 1)));
    HRR(cudaMalloc(&D_edgeList, sizeof(int) * (G->edgeCount)));
    // HRR(cudaHostAlloc(&D_beginPos, sizeof(long long) * (G->uCount + G->vCount + 1), cudaHostAllocMapped));
    // HRR(cudaHostAlloc(&D_edgeList, sizeof(int) * (G->edgeCount), cudaHostAllocMapped));
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
    int *perVertexCount2;
    // int * perVertexCount=new int[G->uCount+G->vCount+1];
    HRR(cudaMallocManaged((void **)&perVertexCount2, sizeof(int) * (G->uCount + G->vCount + 1)));

    unsigned long long *globalCount;
    HRR(cudaMallocManaged(&globalCount, sizeof(unsigned long long)));
    *globalCount = 0;
    int *nextVertex;
    HRR(cudaMallocManaged(&nextVertex, sizeof(int)));
    int *hashTable;
    HRR(cudaMalloc(&hashTable, sizeof(int) * (G->uCount + G->vCount) * blocknumber));

    // startTime = wtime();
    // HRR(cudaMemcpy(D_beginPos, G->beginPos, sizeof(long long) * (G->uCount + G->vCount + 1), cudaMemcpyHostToDevice));
    // HRR(cudaMemcpy(D_edgeList, G->edgeList, sizeof(int) * (G->edgeCount), cudaMemcpyHostToDevice));
    // exectionTime = wtime() - startTime;
    // cout << "load graph elapsed time: " << exectionTime << endl;

    if (1)
    {

        long long *D_beginPos_first;
        int *D_edgeList_first;
        long long *D_beginPos_second;
        int *D_edgeList_second;

        HRR(cudaMalloc(&D_beginPos_second, sizeof(long long) * (G->uCount + G->vCount + 1)));
        HRR(cudaMalloc(&D_edgeList_second, sizeof(int) * (G->subEdgeListSecond[0].size())));

        startTime = wtime();
        double transferTime = 0, computeTime = 0;
        for (int i = 0; i < G->partitionNum; i++)
        {
            startTime = wtime();
            HRR(cudaMemcpy(D_beginPos, G->beginPos, sizeof(long long) * (G->uCount + G->vCount + 1), cudaMemcpyHostToDevice));
            HRR(cudaMemcpy(D_edgeList, G->edgeList, sizeof(int) * (G->edgeCount), cudaMemcpyHostToDevice));
            HRR(cudaMemcpy(D_beginPos_second, &(G->subBeginPosSecond[i][0]), sizeof(long long) * (G->subBeginPosSecond[i].size()), cudaMemcpyHostToDevice));
            HRR(cudaMemcpy(D_edgeList_second, &(G->subEdgeListSecond[i][0]), sizeof(int) * (G->subEdgeListSecond[i].size()), cudaMemcpyHostToDevice));
            *globalCount = 0;
            transferTime += wtime() - startTime;
            startTime = wtime();
            hashPartition<<<blocknumber, 1024>>>(D_beginPos, D_edgeList, D_beginPos_second, D_edgeList_second, globalCount, perVertexCount, hashTable, 0, G->uCount + G->vCount, G->length, G->partitionNum);
            HRR(cudaDeviceSynchronize());
            computeTime += wtime() - startTime;
            cout << *globalCount << endl;
            // cout << G->uCount + G->vCount << endl;
        }
        exectionTime = wtime() - startTime;
        cout << transferTime << ' ' << computeTime << endl;
        // cout << *globalCount << ' ' << exectionTime << endl;
    }

    *globalCount = 0;
    startTime = wtime();
    *nextVertex = blocknumber;
    hashBasedButterflyCounting<<<blocknumber, 1024>>>(D_beginPos, D_edgeList, G->uCount, G->vCount, globalCount, perVertexCount, hashTable, 0, G->breakVertex32, nextVertex);
    HRR(cudaDeviceSynchronize());
    exectionTime = wtime() - startTime;
    cout << *globalCount << ' ' << exectionTime << endl;
    cout << "run degree<32 with merge： vertex num: " << G->uCount + G->vCount - G->breakVertex32 << endl;
    startTime = wtime();
    mergeBasedButterflyCounting<<<1024, blockSize>>>(D_beginPos, D_edgeList, G->uCount, G->vCount, globalCount, perVertexCount, hashTable, G->breakVertex32, G->uCount + G->vCount);
    HRR(cudaDeviceSynchronize());
    exectionTime = wtime() - startTime;
    cout << *globalCount << ' ' << exectionTime << endl;
    *globalCount = 0;

    // if (0)
    // {
    //     //for test
    //     if (0) //hash>10
    //     {
    //         cout << "run all vertex with hash" << endl;
    //         startTime = wtime();
    //         hashBasedButterflyCounting<<<blocknumber, 1024>>>(D_beginPos, D_edgeList, G->uCount, G->vCount, globalCount, perVertexCount, hashTable, 0, G->uCount + G->vCount);
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
    //         hashBasedButterflyCounting<<<blocknumber, 1024>>>(D_beginPos, D_edgeList, G->uCount, G->vCount, globalCount, perVertexCount, hashTable, G->breakVertex32, G->uCount + G->vCount);
    //         HRR(cudaDeviceSynchronize());
    //         exectionTime = wtime() - startTime;
    //         cout << *globalCount << ' ' << exectionTime << endl;
    //         *globalCount = 0;
    //     }
    //     if (1) //hash<10
    //     {
    //         cout << "run degree<10 with hash" << endl;
    //         startTime = wtime();
    //         hashBasedButterflyCounting<<<blocknumber, 1024>>>(D_beginPos, D_edgeList, G->uCount, G->vCount, globalCount, perVertexCount, hashTable, G->breakVertex10, G->uCount + G->vCount);
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
    //             heapBasedButterflyCounting<<<blocknumber, 1024>>>(D_beginPos, D_edgeList, G->uCount, G->vCount, globalCount, perVertexCount, hashTable, i, i + 1);
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
    //         D_heapBasedButterflyCounting<<<blocknumber, 128>>>(D_beginPos, D_edgeList, Sorted_List, total_size, num_frT, num_srT, G->uCount, G->vCount, globalCount, perVertexCount, hashTable, G->breakVertex10, G->uCount + G->vCount);
    //         HRR(cudaDeviceSynchronize());
    //         exectionTime = wtime() - startTime;
    //         cout << *globalCount << ' ' << exectionTime << endl;
    //         *globalCount = 0;
    //     }
    //     if (0) //heap<100
    //     {
    //         cout << "run all vertex with D_heap" << endl;
    //         startTime = wtime();
    //         D_heapBasedButterflyCounting<<<blocknumber, 128>>>(D_beginPos, D_edgeList, Sorted_List, total_size, num_frT, num_srT, G->uCount, G->vCount, globalCount, perVertexCount, hashTable, 0, G->uCount + G->vCount);
    //         HRR(cudaDeviceSynchronize());
    //         exectionTime = wtime() - startTime;
    //         cout << *globalCount << ' ' << exectionTime << endl;
    //         *globalCount = 0;
    //     }
    //     if (0) //hash>32
    //     {
    //         startTime = wtime();
    //         hashBasedButterflyCounting<<<blocknumber, 1024>>>(D_beginPos, D_edgeList, G->uCount, G->vCount, globalCount, perVertexCount, hashTable, 0, G->breakVertex32);
    //         HRR(cudaDeviceSynchronize());
    //         exectionTime = wtime() - startTime;
    //         cout << ' ' << exectionTime;
    //     }
    //     if (0) //hash<32
    //     {
    //         startTime = wtime();
    //         hashBasedButterflyCounting<<<blocknumber, 1024>>>(D_beginPos, D_edgeList, G->uCount, G->vCount, globalCount, perVertexCount, hashTable, G->breakVertex32, G->uCount + G->vCount);
    //         HRR(cudaDeviceSynchronize());
    //         exectionTime = wtime() - startTime;
    //         cout << ' ' << exectionTime;
    //     }
    //     if (0) //sort<32
    //     {
    //         startTime = wtime();
    //         sortBasedButterflyCounting<<<blocknumber, 1024>>>(D_beginPos, D_edgeList, G->uCount, G->vCount, globalCount, perVertexCount, hashTable, G->breakVertex32, G->uCount + G->vCount);
    //         HRR(cudaDeviceSynchronize());
    //         exectionTime = wtime() - startTime;
    //         cout << ' ' << exectionTime;
    //     }
    //     if (0) //10<hash<32
    //     {
    //         startTime = wtime();
    //         hashBasedButterflyCounting<<<blocknumber, 1024>>>(D_beginPos, D_edgeList, G->uCount, G->vCount, globalCount, perVertexCount, hashTable, G->breakVertex32, G->breakVertex10);
    //         HRR(cudaDeviceSynchronize());
    //         exectionTime = wtime() - startTime;
    //         cout << ' ' << exectionTime;
    //     }
    // }

    // if (0) //combined several method
    // {
    //     startTime = wtime();
    //     hashBasedButterflyCounting<<<blocknumber, 1024>>>(D_beginPos, D_edgeList, G->uCount, G->vCount, globalCount, perVertexCount, hashTable, 0, G->breakVertex10);
    //     HRR(cudaDeviceSynchronize());
    //     exectionTime = wtime() - startTime;
    //     cout << *globalCount << ' ' << exectionTime << endl;

    //     startTime = wtime();
    //     heapBasedButterflyCounting<<<blocknumber, 128>>>(D_beginPos, D_edgeList, G->uCount, G->vCount, globalCount, perVertexCount, hashTable, G->breakVertex10, G->uCount + G->vCount);
    //     HRR(cudaDeviceSynchronize());
    //     exectionTime = wtime() - startTime;
    //     cout << *globalCount << ' ' << exectionTime << endl;
    //     *globalCount = 0;
    // }

    // *globalCount=0;
    // startTime=wtime();
    // sortBasedButterflyCounting<<<blocknumber,1024>>>(D_beginPos,D_edgeList,G->uCount,G->vCount,globalCount,perVertexCount2,hashTable,G->breakVertex32,G->vertexCount);
    // HRR(cudaDeviceSynchronize());
    // exectionTime=wtime()-startTime;
    // cout<<*globalCount<<' '<<exectionTime;
    // for (int i=G->breakVertex32;i<G->breakVertex10;i++)
    //     if (perVertexCount[i]!=perVertexCount2[i])
    //         cout<<i<<endl;
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

    cudaSetDevice(1);
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
    int vertexNum = (G->uCount + G->vCount) / G->partitionNum + 1;
    HRR(cudaMalloc(&hashTable, sizeof(int) * vertexNum * vertexNum));

    long long *D_beginPos_first;
    int *D_edgeList_first;
    long long *D_beginPos_second;
    int *D_edgeList_second;

    HRR(cudaMalloc(&D_beginPos_second, sizeof(long long) * (G->uCount + G->vCount + 1)));
    HRR(cudaMalloc(&D_edgeList_second, sizeof(int) * (G->subEdgeListSecond[0].size())));

    startTime = wtime();
    double transferTime = 0, computeTime = 0;
    for (int i = 0; i < G->partitionNum; i++)
    {
        startTime = wtime();
        HRR(cudaMemcpy(D_beginPos_second, &(G->subBeginPosSecond[i][0]), sizeof(long long) * (G->subBeginPosSecond[i].size()), cudaMemcpyHostToDevice));
        HRR(cudaMemcpy(D_edgeList_second, &(G->subEdgeListSecond[i][0]), sizeof(int) * (G->subEdgeListSecond[i].size()), cudaMemcpyHostToDevice));
        *globalCount = 0;
        transferTime += wtime() - startTime;
        startTime = wtime();
        hashPartition<<<blocknumber, 1024>>>(D_beginPos, D_edgeList, D_beginPos_second, D_edgeList_second, globalCount, perVertexCount, hashTable, 0, G->uCount + G->vCount, G->length, G->partitionNum);
        HRR(cudaDeviceSynchronize());
        computeTime += wtime() - startTime;
        cout << *globalCount << endl;
        // cout << G->uCount + G->vCount << endl;
    }
    exectionTime = wtime() - startTime;
    cout << transferTime << ' ' << computeTime << endl;
    // cout << *globalCount << ' ' << exectionTime << endl;

    HRR(cudaFree(D_beginPos));
    HRR(cudaFree(D_edgeList));

    return 0;
}
