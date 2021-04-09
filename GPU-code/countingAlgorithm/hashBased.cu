#include <iostream>
#include <cub/cub.cuh>
#include <cub/util_type.cuh>
using namespace std;

__device__ 
void hashBasedPerVertexCounting(int vertex, long long *beginPos, int *edgeList, int* hashTable, int uCount, int vCount, unsigned long long *count)
{
    int vertexDegree=beginPos[vertex+1]-beginPos[vertex];

    // put the two hop neighbor of vertex into hash map
    for (int oneHopNeighborID=beginPos[vertex+1]+threadIdx.x/32-32; oneHopNeighborID>=beginPos[vertex]; oneHopNeighborID-=32)
    {
        int oneHopNeighbor=edgeList[oneHopNeighborID];
        if (oneHopNeighbor<=vertex) break;
        for (int twoHopNeighborID=beginPos[oneHopNeighbor+1]+threadIdx.x%32-32; twoHopNeighborID>=beginPos[oneHopNeighbor]; twoHopNeighborID-=32)
        {
            int twoHopNeighbor=edgeList[twoHopNeighborID];
            if (twoHopNeighbor<=vertex) break;
            // if (vertex==1241027)
            //     printf("%d ",twoHopNeighbor);
            *count+=atomicAdd(&hashTable[twoHopNeighbor+blockIdx.x*(uCount+vCount)],1);
            // hashTable[twoHopNeighbor+blockIdx.x*(uCount+vCount)]++;
        }
    }
    __syncthreads();

    // reset the hash map
    if (vertexDegree*vertexDegree>uCount+vCount) //choose the lower costs method 
    {    
        int start=0,end=uCount+vCount;
        start+=blockIdx.x*(uCount+vCount),end+=blockIdx.x*(uCount+vCount);
        for (int i=start+threadIdx.x; i<end; i+=blockDim.x)
        {
            hashTable[i]=0;
        }
    } 
    else
    {
        for (int oneHopNeighborID=beginPos[vertex+1]+threadIdx.x/32-32; oneHopNeighborID>=beginPos[vertex]; oneHopNeighborID-=32)
        {
            int oneHopNeighbor=edgeList[oneHopNeighborID];
            if (oneHopNeighbor<=vertex) break;        
            for (int twoHopNeighborID=beginPos[oneHopNeighbor+1]+threadIdx.x%32-32; twoHopNeighborID>=beginPos[oneHopNeighbor]; twoHopNeighborID-=32)
            {
                int twoHopNeighbor=edgeList[twoHopNeighborID];
                if (twoHopNeighbor<=vertex) break;
                hashTable[twoHopNeighbor+blockIdx.x*(uCount+vCount)]=0;
            }
        }
    }
    __syncthreads();
}

__global__ 
void hashBasedButterflyCounting(long long *beginPos, int *edgeList, int uCount, int vCount, unsigned long long* globalCount, int* perVertexCount, int* hashTable, int startVertex, int endVertex)
{
    __shared__ unsigned long long sharedCount;
    if (threadIdx.x==0) sharedCount=0;
    unsigned long long count=0;
    for (int i=threadIdx.x+blockIdx.x*(uCount+vCount); i<(1+blockIdx.x)*(uCount+vCount); i+=blockDim.x)
    {
        hashTable[i]=0;
    }
    __syncthreads();
    for (int vertex=startVertex+blockIdx.x; vertex<endVertex; vertex+=gridDim.x)
    {
        // count=0;
        // perVertexCount[vertex]=0;
        hashBasedPerVertexCounting(vertex, beginPos, edgeList, hashTable, uCount, vCount, &count);
        // atomicAdd(&perVertexCount[vertex],count);
        // __syncthreads();
    }

    atomicAdd(&sharedCount,count);
    __syncthreads();
    if (threadIdx.x==0) atomicAdd(globalCount,sharedCount);
}