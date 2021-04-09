#include <iostream>
#include <cub/cub.cuh>
#include <cub/util_type.cuh>
#define infinit 99999999

using namespace std;

__device__ 
void sortBasedPerVertexCounting(int vertex, long long *beginPos, int *edgeList, int* hashTable, int uCount, int vCount, unsigned long long *count)
{
    
    // int vertexDegree=beginPos[vertex+1]-beginPos[vertex];
    int ele[1],k=0;
    for (int i=0;i<1;i++)
        ele[i]=infinit;
    for (int oneHopNeighborID=beginPos[vertex+1]+threadIdx.x/32-32; oneHopNeighborID>=beginPos[vertex]; oneHopNeighborID-=32)
    {
        int oneHopNeighbor=edgeList[oneHopNeighborID];
        if (oneHopNeighbor<=vertex) break;
        for (int twoHopNeighborID=beginPos[oneHopNeighbor+1]+threadIdx.x%32-32; twoHopNeighborID>=beginPos[oneHopNeighbor]; twoHopNeighborID-=32)
        {
            int twoHopNeighbor=edgeList[twoHopNeighborID];
            if (twoHopNeighbor<=vertex) break;
            ele[k]=twoHopNeighbor;
            // if (threadIdx.x==1023&&vertex==1241027) 
            // {
            //     printf("vertexdegree=%d,onehopdegree=%d\ntwoHopNeighborID=%d,oneHopNeighborID=%d\n",beginPos[vertex+1]-beginPos[vertex],beginPos[oneHopNeighbor+1]-beginPos[oneHopNeighbor],twoHopNeighborID-beginPos[oneHopNeighbor],oneHopNeighborID-beginPos[vertex],oneHopNeighbor);
            //     // printf("\n");
            // }
            k++;
        }
    }
    // if(k>1) printf("%d\n",threadIdx.x);
    __syncthreads();
    typedef cub::BlockLoad<int, 1024, 1, cub::BLOCK_LOAD_TRANSPOSE> BlockLoadT;    
    typedef cub::BlockStore<int, 1024, 1, cub::BLOCK_STORE_TRANSPOSE> BlockStoreT;
    typedef cub::BlockRadixSort<int, 1024, 1> BlockRadixSortT;
    __shared__ union {
        typename BlockLoadT::TempStorage       load; 
        typename BlockStoreT::TempStorage      store; 
        typename BlockRadixSortT::TempStorage  sort;
    } temp_storage; 

    BlockRadixSortT(temp_storage.sort).Sort(ele);
    __syncthreads();    // Barrier for smem reuse
    __shared__ int twoHopNeighborList[1027];
    BlockStoreT(temp_storage.store).Store(twoHopNeighborList+1, ele);    
    __syncthreads();
    twoHopNeighborList[1025]=-1;
    twoHopNeighborList[0]=0;
    // if (threadIdx.x==0&&vertex==1241027) 
    // {
    //     for (int i=0;i<1024;i++)
    //         printf("%d ",twoHopNeighborList[i]);
    //     printf("\n");
    // }
    __syncthreads();
    for (int i=threadIdx.x+1;i<1025;i+=blockDim.x)
        if ((twoHopNeighborList[i]!=infinit)&&(twoHopNeighborList[i]==twoHopNeighborList[i+1])) twoHopNeighborList[i]=i+1;
        else twoHopNeighborList[i]=i;
    __syncthreads();
    for (int k=1;k<=6;k++)
        for (int i=threadIdx.x+1;i<1025;i+=blockDim.x)
            twoHopNeighborList[i]=twoHopNeighborList[twoHopNeighborList[i]];
    __syncthreads();
    for (int i=threadIdx.x+1;i<1025;i+=blockDim.x)
        twoHopNeighborList[i]=twoHopNeighborList[i]-i;
    __syncthreads();

    for (int i=threadIdx.x+1;i<1025;i+=blockDim.x)
        if (twoHopNeighborList[i]>twoHopNeighborList[i-1]) 
            *count+=twoHopNeighborList[i]*(twoHopNeighborList[i]+1)/2;
    __syncthreads();
}

__global__ 
void sortBasedButterflyCounting(long long *beginPos, int *edgeList, int uCount, int vCount, unsigned long long* globalCount, int* perVertexCount, int* hashTable, int startVertex, int endVertex)
{
    __shared__ unsigned long long sharedCount;
    if (threadIdx.x==0) sharedCount=0;
    unsigned long long count=0;

    __syncthreads();
    for (int vertex=startVertex+blockIdx.x; vertex<endVertex; vertex+=gridDim.x)
    {
        // count=0;
        // perVertexCount[vertex]=0;
        // int vertexDegree=beginPos[vertex+1]-beginPos[vertex];
        sortBasedPerVertexCounting(vertex, beginPos, edgeList, hashTable, uCount, vCount, &count);
        // atomicAdd(&perVertexCount[vertex],count);
        // __syncthreads();
    }

    atomicAdd(&sharedCount,count);
    __syncthreads();
    if (threadIdx.x==0) atomicAdd(globalCount,sharedCount);
}