#include <iostream>
#include "graph.h"
#include "wtime.h"
#include "util.h"
#include <cub/cub.cuh>
#include <cub/util_type.cuh>

#define blocknumber 1

using namespace std;
// using namespace cub;

// template <int BLOCK_THREADS, int ITEMS_PER_THREAD>
// __global__ void neighborSorting(int* d_in)
// {
//     int vertex=blockIdx.x;
//     typedef cub::BlockLoad<int, BLOCK_THREADS, ITEMS_PER_THREAD, cub::BLOCK_LOAD_TRANSPOSE> BlockLoadT;    
//     typedef cub::BlockStore<int, BLOCK_THREADS, ITEMS_PER_THREAD, cub::BLOCK_STORE_TRANSPOSE> BlockStoreT;
//     typedef cub::BlockRadixSort<int, BLOCK_THREADS, ITEMS_PER_THREAD> BlockRadixSortT;
//     __shared__ union {
//         typename BlockLoadT::TempStorage       load; 
//         typename BlockStoreT::TempStorage      store; 
//         typename BlockRadixSortT::TempStorage  sort;
//     } temp_storage; 

//     int thread_keys[ITEMS_PER_THREAD];
//     // int *p;
//     // p=thread_keys;
//     int block_offset = blockIdx.x * (BLOCK_THREADS * ITEMS_PER_THREAD);      
//     BlockLoadT(temp_storage.load).Load(d_in + block_offset, thread_keys);

//     __syncthreads();    // Barrier for smem reuse
//     // Collectively sort the keys
//     BlockRadixSortT(temp_storage.sort).Sort(thread_keys);
//     __syncthreads();    // Barrier for smem reuse
//     // Store the sorted segment 
//     BlockStoreT(temp_storage.store).Store(d_in + block_offset, thread_keys);

// }




__global__ 
void butterflyCounting(long long *beginPos, int *edgeList, int uCount, int vCount, unsigned long long* globalCount, int* hashTable)
{
    __shared__ unsigned long long sharedCount;
    if (threadIdx.x==0) sharedCount=0;
    unsigned long long count=0;

    for (int i=threadIdx.x+blockIdx.x*(uCount+vCount); i<uCount+vCount+blockIdx.x*(uCount+vCount); i+=blockDim.x)
        hashTable[i]=0;
    __syncthreads();
    for (int vertex=blockIdx.x; vertex<uCount+vCount; vertex+=gridDim.x)
    {
        int oneHopNeighborID=threadIdx.x/32+beginPos[vertex];
        int vertexDegree=beginPos[vertex+1]-beginPos[vertex];

        for (; oneHopNeighborID<beginPos[vertex+1]; oneHopNeighborID+=32)
        {
            int oneHopNeighbor=edgeList[oneHopNeighborID];
            int oneHopNeighborDegree=beginPos[oneHopNeighbor+1]-beginPos[oneHopNeighbor];
            if (oneHopNeighborDegree>vertexDegree || (oneHopNeighborDegree==vertexDegree && oneHopNeighbor<=vertex)) continue;
            int twoHopNeighborID=threadIdx.x%32+beginPos[oneHopNeighbor];
            for (; twoHopNeighborID<beginPos[oneHopNeighbor+1]; twoHopNeighborID+=32)
            {
                int twoHopNeighbor=edgeList[twoHopNeighborID];
                int twoHopNeighborDegree=beginPos[twoHopNeighbor+1]-beginPos[twoHopNeighbor];
                if ((twoHopNeighborDegree>vertexDegree) || (twoHopNeighborDegree==vertexDegree && twoHopNeighbor<=vertex)) continue;
                // if (twoHopNeighbor<=vertex) continue;
                // printf("%d %d\n",twoHopNeighborDegree,vertexDegree);
                atomicAdd(&hashTable[twoHopNeighbor+blockIdx.x*(uCount+vCount)],1);
                // count++;
            }
        }
        __syncthreads();
        int start=0,end=uCount;
        if (vertex>=uCount)
        {
            start=uCount,end=uCount+vCount;
        }
        start+=blockIdx.x*(uCount+vCount),end+=blockIdx.x*(uCount+vCount);
        // int start=0,end=uCount+vCount;
        // if (threadIdx.x==0) printf("%d\n",ccc);
        for (int i=start+threadIdx.x; i<end; i+=blockDim.x)
        {
            count+=hashTable[i]*(hashTable[i]-1)/2;
            hashTable[i]=0;
        }
        __syncthreads();
    }



    atomicAdd(&sharedCount,count);
    __syncthreads();
    if (threadIdx.x==0) atomicAdd(globalCount,sharedCount);
}

int BC(graph bipartiteGraph)
{
    
    double startTime,exectionTime;

    long long* D_beginPos;
    int* D_edgeList;
    HRR(cudaMalloc((void **) &D_beginPos,sizeof(long long)*(bipartiteGraph.uCount+bipartiteGraph.vCount+1)));
    HRR(cudaMalloc((void **) &D_edgeList,sizeof(int)*(bipartiteGraph.edgeCount)));
    HRR(cudaMemcpy(D_beginPos,bipartiteGraph.beginPos,sizeof(long long)*(bipartiteGraph.uCount+bipartiteGraph.vCount+1), cudaMemcpyHostToDevice));
    HRR(cudaMemcpy(D_edgeList,bipartiteGraph.edgeList,sizeof(int)*(bipartiteGraph.edgeCount), cudaMemcpyHostToDevice));


    unsigned long long *globalCount;
    unsigned long long count=0;
    HRR(cudaMallocManaged(&globalCount, sizeof(unsigned long long)));
    
    int *hashTable;
    HRR(cudaMallocManaged(&hashTable, sizeof(int)*(bipartiteGraph.uCount+bipartiteGraph.vCount)*blocknumber));
    HRR(cudaMemcpy(globalCount,&count,sizeof(unsigned long long), cudaMemcpyHostToDevice));


    startTime=wtime();
    butterflyCounting<<<blocknumber,1024>>>(D_beginPos,D_edgeList,bipartiteGraph.uCount,bipartiteGraph.vCount,globalCount,hashTable);
    HRR(cudaDeviceSynchronize());
    exectionTime=wtime()-startTime;
    cout<<*globalCount<<' '<<exectionTime<<endl;

    // int *d_in,*in;
    // int num_blocks=10240;
    // int N=1024*16*num_blocks;
    // cout<<N<<endl;
    // in=new int[N];
    // for (int i=0;i<N;i++)
    // {
    //     in[i]=N-i;
    // }
    // HRR(cudaMalloc((void **)&d_in, N*sizeof(int)));
    // HRR(cudaMemcpy(d_in,in,sizeof(int)*N, cudaMemcpyHostToDevice));

    // neighborSorting<1024, 16><<<num_blocks, 1024>>>(d_in); 

    // HRR(cudaDeviceSynchronize());
    // exectionTime=wtime()-startTime;
    
    // HRR(cudaMemcpy(in,d_in,sizeof(int)*N, cudaMemcpyDeviceToHost));
    // cout<<in[100]<<' '<<exectionTime<<endl;
    




    HRR(cudaFree(D_beginPos));
    HRR(cudaFree(D_edgeList));
    return 0;
}
