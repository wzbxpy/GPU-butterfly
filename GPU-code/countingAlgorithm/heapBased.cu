#include <iostream>
#include <cub/cub.cuh>
#include <cub/util_type.cuh>
using namespace std;

struct heap
{
    int element;
    int* now;
    int* end;
};

__device__ int* binarySearch(int* a, int* b, int x)
{
    while (a<b)
    {
        int* mid=a+((b-a)/2);
        if (*mid<=x) a=mid+1; else b=mid;
    }
    return a;
}

__device__ 
void heapBasedPerVertexCounting(int vertex, long long *beginPos, int *edgeList, int* hashTable, int uCount, int vCount, unsigned long long *count)
{
    struct heap H[11];
    H[0].element=-1;
    int k=1;
    
    // first creat the heap 
    for (int oneHopNeighborID=beginPos[vertex+1]-1; oneHopNeighborID>=beginPos[vertex]; oneHopNeighborID--)
    {
        int oneHopNeighbor=edgeList[oneHopNeighborID];
        if (oneHopNeighbor<=vertex) break;
        // get the first neighbor in each oneHopNeighbor's neighbor list 
        H[k].end=edgeList+beginPos[oneHopNeighbor+1];
        H[k].now=binarySearch(edgeList+beginPos[oneHopNeighbor], H[k].end, vertex);
        if (H[k].now>=H[k].end)  continue;
        H[k].element=*H[k].now;

        // update the heap
        int p=k;
        while (H[p].element<H[p/2].element)
        {
            struct heap t;
            t=H[p];
            H[p]=H[p/2];
            p/=2;
            H[p]=t;
        }
        k++;
    }
    int previousElement=-1,cc=1;
    // second pop the top element in heap and add new element from its corresponding neighbor list
    for(k--;k>=1;)
    {
        // update the count of butterflies
        int nowElement=H[1].element;
        if (nowElement==previousElement) {cc++;}
        else { *count+=cc*(cc-1)/2; cc=1; previousElement=nowElement;}

        // add the next element into heap
        H[1].now++;
        if (H[1].now>=H[1].end) 
        {
            struct heap t;
            t=H[1];
            H[1]=H[k];
            H[k]=t;
            k--;
        }
        else H[1].element=*(H[1].now);

        // update the heap
        int p=1;
        for(;;)
        {
            if (p*2>k) break;
            p*=2;
            if (p+1<=k&&H[p].element>H[p+1].element) p++;
            if (H[p].element<H[p/2].element)
            {
                struct heap t;
                t=H[p];
                H[p]=H[p/2];
                H[p/2]=t;
            }
            else
            break;
        }
        

    }
    *count+=cc*(cc-1)/2; // the last series of element need to be added
}


__global__ 
void heapBasedButterflyCounting(long long *beginPos, int *edgeList, int uCount, int vCount, unsigned long long* globalCount, int* perVertexCount, int* hashTable, int startVertex, int endVertex)
{
    __shared__ unsigned long long sharedCount;
    if (threadIdx.x==0) sharedCount=0;
    unsigned long long count=0;
    for (int vertex=startVertex+blockIdx.x*blockDim.x+threadIdx.x; vertex<endVertex; vertex+=gridDim.x*blockDim.x)
    {
        // count=0;
        heapBasedPerVertexCounting(vertex, beginPos, edgeList, hashTable, uCount, vCount, &count);
        // perVertexCount[vertex]=count;
    }
    atomicAdd(&sharedCount,count);
    __syncthreads();
    if (threadIdx.x==0) atomicAdd(globalCount,sharedCount);
}
