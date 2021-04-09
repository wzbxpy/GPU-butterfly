#include <iostream>
#include "graph.h"
#include "wtime.h"
#include "util.h"
#include <cub/cub.cuh>
#include <cub/util_type.cuh>
#include "countingAlgorithm/sortBased.cuh"
#include "countingAlgorithm/hashBased.cuh"
#include "countingAlgorithm/heapBased.cuh"
#include "countingAlgorithm/D_heapBased.cuh"

#define blocknumber 128

using namespace std;
// using namespace cub;

template <int BLOCK_THREADS, int ITEMS_PER_THREAD>
__global__ void neighborSorting(int* d_in)
{
    // int vertex=blockIdx.x;
    typedef cub::BlockLoad<int, BLOCK_THREADS, ITEMS_PER_THREAD, cub::BLOCK_LOAD_TRANSPOSE> BlockLoadT;    
    typedef cub::BlockStore<int, BLOCK_THREADS, ITEMS_PER_THREAD, cub::BLOCK_STORE_TRANSPOSE> BlockStoreT;
    typedef cub::BlockRadixSort<int, BLOCK_THREADS, ITEMS_PER_THREAD> BlockRadixSortT;
    __shared__ union {
        typename BlockLoadT::TempStorage       load; 
        typename BlockStoreT::TempStorage      store; 
        typename BlockRadixSortT::TempStorage  sort;
    } temp_storage; 

    int thread_keys[ITEMS_PER_THREAD];
    // int *p;
    // p=thread_keys;
    int block_offset = blockIdx.x * (BLOCK_THREADS * ITEMS_PER_THREAD);      
    BlockLoadT(temp_storage.load).Load(d_in + block_offset, thread_keys);

    // for (int i=threadIdx.x;i<ITEMS_PER_THREAD*BLOCK_THREADS;i+=BLOCK_THREADS)
    //     thread_keys[i/BLOCK_THREADS]=d_in[i];
    __syncthreads();    // Barrier for smem reuse
    // if (threadIdx.x==0)
    // {
    //     for (int i=0;i<ITEMS_PER_THREAD;i++)
    //     printf("%d ",thread_keys[i]);
    // }
    // Collectively sort the keys
    BlockRadixSortT(temp_storage.sort).Sort(thread_keys);
    // if (threadIdx.x==0)
    // {
    //     for (int i=0;i<ITEMS_PER_THREAD;i++)
    //     printf("%d ",thread_keys[i]);
    // }
    __syncthreads();    // Barrier for smem reuse
    // Store the sorted segment 
    BlockStoreT(temp_storage.store).Store(d_in + block_offset, thread_keys);

}

void sort_test()
{
    
    double startTime,exectionTime;
    int *d_in,*in;
    int num_blocks=1;
    const int num_per_thread=8;
    const int num_thread=1024;
    int N=num_thread*num_per_thread*num_blocks;
    cout<<N<<endl;
    in=new int[N];
    for (int i=0;i<N;i++)
    {
        in[i]=N-i;
    }
    HRR(cudaMalloc((void **)&d_in, N*sizeof(int)));
    HRR(cudaMemcpy(d_in,in,sizeof(int)*N, cudaMemcpyHostToDevice));

    neighborSorting<num_thread, num_per_thread><<<num_blocks, num_thread>>>(d_in); 
    startTime=wtime();
    HRR(cudaDeviceSynchronize());
    exectionTime=wtime()-startTime;
    
    HRR(cudaMemcpy(in,d_in,sizeof(int)*N, cudaMemcpyDeviceToHost));
    cout<<in[100]<<' '<<exectionTime<<endl;
}


int BC(graph* G)
{
    
    double startTime,exectionTime;

    long long* D_beginPos;
    int* D_edgeList;
    HRR(cudaMalloc((void **) &D_beginPos,sizeof(long long)*(G->uCount+G->vCount+1)));
    HRR(cudaMalloc((void **) &D_edgeList,sizeof(int)*(G->edgeCount)));
    HRR(cudaMemcpy(D_beginPos,G->beginPos,sizeof(long long)*(G->uCount+G->vCount+1), cudaMemcpyHostToDevice));
    HRR(cudaMemcpy(D_edgeList,G->edgeList,sizeof(int)*(G->edgeCount), cudaMemcpyHostToDevice));
    int num_frT=6,num_srT=2;
    int* Sorted_List;
    int* host_list;
    HRR(cudaMallocManaged((void **) &Sorted_List,sizeof(int)*(G->edgeCount*2)));
    int total_size=sizeof(int)*(G->edgeCount*2);
    int * perVertexCount;
    // int * perVertexCount=new int[G->uCount+G->vCount+1];
    HRR(cudaMallocManaged((void **) &perVertexCount,sizeof(int)*(G->uCount+G->vCount+1)));
    int * perVertexCount2;
    // int * perVertexCount=new int[G->uCount+G->vCount+1];
    HRR(cudaMallocManaged((void **) &perVertexCount2,sizeof(int)*(G->uCount+G->vCount+1)));

    unsigned long long *globalCount;
    HRR(cudaMallocManaged(&globalCount, sizeof(unsigned long long)));
    *globalCount=0;
    int *hashTable;
    HRR(cudaMalloc(&hashTable, sizeof(int)*(G->uCount+G->vCount)*blocknumber));

        
    if (1)
    {
        //for test
        if (1) //hash>10
        {
        cout<<"run all vertex with hash"<<endl;
            startTime=wtime();
            hashBasedButterflyCounting<<<blocknumber,1024>>>(D_beginPos,D_edgeList,G->uCount,G->vCount,globalCount,perVertexCount,hashTable,0,G->uCount+G->vCount);
            HRR(cudaDeviceSynchronize());
            exectionTime=wtime()-startTime;
            cout<<*globalCount<<' '<<exectionTime<<endl;
            *globalCount=0;
        }
        
        if (1) //hash<10
        {
        cout<<"run degree<10 with hash"<<endl;
            startTime=wtime();
            hashBasedButterflyCounting<<<blocknumber,1024>>>(D_beginPos,D_edgeList,G->uCount,G->vCount,globalCount,perVertexCount,hashTable,G->breakVertex10,G->uCount+G->vCount);
            HRR(cudaDeviceSynchronize());
            exectionTime=wtime()-startTime;
            cout<<*globalCount<<' '<<exectionTime<<endl;
            *globalCount=0;
        }
        if (1) //heap<10
        {
        cout<<"run degree<10 with heap： vertex num: "<<G->uCount+G->vCount-G->breakVertex10<<endl;
            startTime=wtime();
            heapBasedButterflyCounting<<<blocknumber,128>>>(D_beginPos,D_edgeList,G->uCount,G->vCount,globalCount,perVertexCount,hashTable,G->breakVertex10,G->uCount+G->vCount);
            HRR(cudaDeviceSynchronize());
            exectionTime=wtime()-startTime;
            cout<<*globalCount<<' '<<exectionTime<<endl;
            *globalCount=0;
        }
        if (1) //heap<10
        {
        cout<<"run degree<10 with D_heap"<<endl;
            startTime=wtime();
            D_heapBasedButterflyCounting<<<blocknumber,128>>>(D_beginPos,D_edgeList,Sorted_List,total_size,num_frT,num_srT,G->uCount,G->vCount,globalCount,perVertexCount,hashTable,G->breakVertex10,G->uCount+G->vCount);
            HRR(cudaDeviceSynchronize());
            exectionTime=wtime()-startTime;
            cout<<*globalCount<<' '<<exectionTime<<endl;
            *globalCount=0;
        }
        if (1) //heap<100
        {
        cout<<"run all vertex with D_heap"<<endl;
            startTime=wtime();
            D_heapBasedButterflyCounting<<<blocknumber,128>>>(D_beginPos,D_edgeList,Sorted_List,total_size,num_frT,num_srT,G->uCount,G->vCount,globalCount,perVertexCount,hashTable,0,G->uCount+G->vCount);
            HRR(cudaDeviceSynchronize());
            exectionTime=wtime()-startTime;
            cout<<*globalCount<<' '<<exectionTime<<endl;
            *globalCount=0;
        }
        if (0) //hash>32
        {
            startTime=wtime();
            hashBasedButterflyCounting<<<blocknumber,1024>>>(D_beginPos,D_edgeList,G->uCount,G->vCount,globalCount,perVertexCount,hashTable,0,G->breakVertex32);
            HRR(cudaDeviceSynchronize());
            exectionTime=wtime()-startTime;
            cout<<' '<<exectionTime;
        }
        if (0) //hash<32
        {
            startTime=wtime();
            hashBasedButterflyCounting<<<blocknumber,1024>>>(D_beginPos,D_edgeList,G->uCount,G->vCount,globalCount,perVertexCount,hashTable,G->breakVertex32,G->uCount+G->vCount);
            HRR(cudaDeviceSynchronize());
            exectionTime=wtime()-startTime;
            cout<<' '<<exectionTime;
        }
        if (0) //sort<32
        {
            startTime=wtime();
            sortBasedButterflyCounting<<<blocknumber,1024>>>(D_beginPos,D_edgeList,G->uCount,G->vCount,globalCount,perVertexCount,hashTable,G->breakVertex32,G->uCount+G->vCount);
            HRR(cudaDeviceSynchronize());
            exectionTime=wtime()-startTime;
            cout<<' '<<exectionTime;
        }
        if (0) //10<hash<32
        {
            startTime=wtime();
            hashBasedButterflyCounting<<<blocknumber,1024>>>(D_beginPos,D_edgeList,G->uCount,G->vCount,globalCount,perVertexCount,hashTable,G->breakVertex32,G->breakVertex10);
            HRR(cudaDeviceSynchronize());
            exectionTime=wtime()-startTime;
            cout<<' '<<exectionTime;
        }
    }

/*
    startTime=wtime();
    hashBasedButterflyCounting<<<blocknumber,1024>>>(D_beginPos,D_edgeList,G->uCount,G->vCount,globalCount,perVertexCount,hashTable,0,G->breakVertex32);
    HRR(cudaDeviceSynchronize());
    exectionTime=wtime()-startTime;
    cout<<*globalCount<<' '<<exectionTime<<endl;

    
    // *globalCount=0;
    startTime=wtime();
    sortBasedButterflyCounting<<<blocknumber,1024>>>(D_beginPos,D_edgeList,G->uCount,G->vCount,globalCount,perVertexCount2,hashTable,G->breakVertex32,G->vertexCount);
    HRR(cudaDeviceSynchronize());
    exectionTime=wtime()-startTime;
    cout<<*globalCount<<' '<<exectionTime;
    // for (int i=G->breakVertex32;i<G->breakVertex10;i++)
    //     if (perVertexCount[i]!=perVertexCount2[i])
    //         cout<<i<<endl;
    cout<<endl;
    */
   // HRR(cudaMemcpy((void **)&host_list,(void **)&Sorted_List,sizeof(int)*(G->edgeCount), cudaMemcpyDeviceToHost));
    
    HRR(cudaFree(D_beginPos));
    HRR(cudaFree(D_edgeList));
    HRR(cudaFree(Sorted_List));
    
    // delete(perVertexCount);
    return 0;
}

