#include <unordered_map>
#include <iostream>
#include <fstream>
#include <cmath>
#include <atomic>
#include <thread>
// #include <cilk/cilk.h>
// #include <cilk/cilk_api.h>
// #include <cilk/reducer_opadd.h>
#include <tbb/tbb_allocator.h>
#include "butterfly-CPU.h"
#include "../wtime.h"
#include "../graph.h"
#define chunckSize 10
using namespace std;

int getMaxVertexCount(string path, int partitionNum)
{
    int vertexCount, x;
    fstream propertiesFile(path + "partition" + to_string(partitionNum) + "dst0/properties.txt", ios::in);
    propertiesFile >> x >> vertexCount;
    vertexCount += x;
    propertiesFile.close();
    vertexCount = ceil(vertexCount / double(partitionNum));
    return vertexCount;
}
inline void loadNextVertex(int &vertex, shared_ptr<atomic<int>> nextVertex)
{
    vertex = (vertex + 1) % chunckSize != 0 ? vertex + 1 : nextVertex->fetch_add(chunckSize);
}

void edgeCentric_kernel(shared_ptr<int[]> hashTable, graph *G_src, graph *G_dst, int threadNum, int threadId, long long *partSum, shared_ptr<atomic<int>> nextVertex, int partitionNumSrc, int partitionNumDst, int vertexOffsets, int maxVertexCount)
{
    // long long partSum = 0;
    int vertex = threadId * chunckSize;
    for (; vertex < G_src->vertexCount;)
    {
        int vertexDegree = G_src->beginPos[vertex + 1] - G_src->beginPos[vertex];
        //creat hashtabel and count
        for (int oneHopNeighborID = G_src->beginPos[vertex]; oneHopNeighborID < G_src->beginPos[vertex + 1]; oneHopNeighborID += 1)
        {
            int oneHopNeighbor = G_src->edgeList[oneHopNeighborID];
            int bound = vertex * partitionNumSrc + vertexOffsets < oneHopNeighbor ? vertex * partitionNumSrc + vertexOffsets : oneHopNeighbor;
            for (int twoHopNeighborID = G_dst->beginPos[oneHopNeighbor]; twoHopNeighborID < G_dst->beginPos[oneHopNeighbor + 1]; twoHopNeighborID += 1)
            {
                int twoHopNeighbor = G_dst->edgeList[twoHopNeighborID];
                if (twoHopNeighbor >= bound)
                    break;
                *partSum += hashTable[threadId * maxVertexCount + (twoHopNeighbor / partitionNumDst)];
                hashTable[threadId * maxVertexCount + (twoHopNeighbor / partitionNumDst)]++;
            }
        }
        //clean hashtable
        if (vertexDegree * vertexDegree / 10 > G_dst->vertexCount) //choose the lower costs method
        {
            for (int i = threadId * maxVertexCount; i < (threadId + 1) * maxVertexCount; i++)
            {
                hashTable[i] = 0;
            }
        }
        else
        {
            for (int oneHopNeighborID = G_src->beginPos[vertex]; oneHopNeighborID < G_src->beginPos[vertex + 1]; oneHopNeighborID += 1)
            {
                int oneHopNeighbor = G_src->edgeList[oneHopNeighborID];
                int bound = vertex * partitionNumSrc + vertexOffsets < oneHopNeighbor ? vertex * partitionNumSrc + vertexOffsets : oneHopNeighbor;
                for (int twoHopNeighborID = G_dst->beginPos[oneHopNeighbor]; twoHopNeighborID < G_dst->beginPos[oneHopNeighbor + 1]; twoHopNeighborID += 1)
                {
                    int twoHopNeighbor = G_dst->edgeList[twoHopNeighborID];
                    if (twoHopNeighbor >= bound)
                        break;
                    hashTable[threadId * maxVertexCount + (twoHopNeighbor / partitionNumDst)] = 0;
                }
            }
        }
        //load next vertex
        vertex = (vertex + 1) % chunckSize != 0 ? vertex + 1 : nextVertex->fetch_add(chunckSize);
    }
}

void edgeCentric(string path, parameter para)
{
    //initilize
    graph *G_src = new graph;
    graph *G_dst = new graph;
    int threadNum = para.processorNum;
    int partitionNumSrc = para.partitionNum;
    int partitionNumDst = para.partitionNum * para.batchNum;
    int maxVertexCount = getMaxVertexCount(path, partitionNumDst);
    shared_ptr<int[]> hashTable(new int[threadNum * maxVertexCount]);
    shared_ptr<long long[]> partSum(new long long[threadNum]);
    shared_ptr<atomic<int>> nextVertex(new atomic<int>(threadNum * chunckSize));
    memset(&hashTable[0], 0, sizeof(int) * threadNum * maxVertexCount);
    memset(&partSum[0], 0, sizeof(long long) * threadNum);
    //launch threads
    thread threads[threadNum];
    cout << threadNum << " startt! " << endl;
    double startTime = wtime();
    double transferTime = 0, computeTime = 0;
    long long ans = 0;
    string subGraphPath;
    for (int i = 0; i < partitionNumSrc; i++)
    {
        subGraphPath = path + "partition" + to_string(partitionNumSrc) + "src" + to_string(i);
        transferTime += G_src->loadGraph(subGraphPath);
        for (int j = 0; j < partitionNumDst; j++)
        {
            subGraphPath = path + "partition" + to_string(partitionNumDst) + "dst" + to_string(j);
            transferTime += G_dst->loadGraph(subGraphPath);
            startTime = wtime();
            *nextVertex = threadNum * chunckSize;
            for (int threadId = 0; threadId < threadNum; threadId++)
            {
                threads[threadId] = thread(edgeCentric_kernel, hashTable, G_src, G_dst, threadNum, threadId, &partSum[threadId], nextVertex, partitionNumSrc, partitionNumDst, i, maxVertexCount);
            }
            for (auto &t : threads)
            {
                t.join();
            }
            for (int i = 0; i < threadNum; i++)
            {
                ans += partSum[i];
                partSum[i] = 0;
            }
            computeTime += wtime() - startTime;
        }
    }
    cout << ans << " " << computeTime << " " << transferTime << endl;
}

void wedgeCentric_kernel(shared_ptr<atomic<int>[]> hashTable, graph *G_first, graph *G_second, int threadNum, int threadId, long long *partSum, shared_ptr<atomic<int>> nextVertex, int partitionNum, int vertexOffsets, int maxVertexCount)
{
    int vertex = threadId * chunckSize;
    for (; vertex < G_first->vertexCount;)
    {
        for (int firstNeighborID = G_first->beginPos[vertex]; firstNeighborID < G_first->beginPos[vertex + 1]; firstNeighborID += 1)
        {
            int firstNeighbor = G_first->edgeList[firstNeighborID];
            int bound = vertex < firstNeighbor ? vertex : firstNeighbor;
            for (int secondNeighborID = G_second->beginPos[vertex]; secondNeighborID < G_second->beginPos[vertex + 1]; secondNeighborID += 1)
            {
                int secondNeighbor = G_second->edgeList[secondNeighborID];
                if (secondNeighbor >= bound)
                    break;
                // *partSum += hashTable[(firstNeighbor / partitionNum) * maxVertexCount + (secondNeighbor / partitionNum)];
                // hashTable[(firstNeighbor / partitionNum) * maxVertexCount + (secondNeighbor / partitionNum)]++;
                *partSum += hashTable[(firstNeighbor / partitionNum) * maxVertexCount + (secondNeighbor / partitionNum)].fetch_add(1, memory_order_relaxed);
            }
        }
        // load next vertex
        vertex = (vertex + 1) % chunckSize != 0 ? vertex + 1 : nextVertex->fetch_add(chunckSize);
        // loadNextVertex(vertex, nextVertex);
    }
}
void cleanHashTable_kernel(shared_ptr<atomic<int>[]> hashTable, graph *G_first, graph *G_second, int threadNum, int threadId, long long *partSum, shared_ptr<atomic<int>> nextVertex, int partitionNum, int vertexOffsets, int maxVertexCount)
{
    int vertex = threadId * chunckSize;
    for (; vertex < G_first->vertexCount;)
    {
        for (int firstNeighborID = G_first->beginPos[vertex]; firstNeighborID < G_first->beginPos[vertex + 1]; firstNeighborID += 1)
        {
            int firstNeighbor = G_first->edgeList[firstNeighborID];
            int bound = vertex < firstNeighbor ? vertex : firstNeighbor;
            for (int secondNeighborID = G_second->beginPos[vertex]; secondNeighborID < G_second->beginPos[vertex + 1]; secondNeighborID += 1)
            {
                int secondNeighbor = G_second->edgeList[secondNeighborID];
                if (secondNeighbor >= bound)
                    break;
                hashTable[(firstNeighbor / partitionNum) * maxVertexCount + (secondNeighbor / partitionNum)] = 0;
            }
        }
        // load next vertex
        vertex = (vertex + 1) % chunckSize != 0 ? vertex + 1 : nextVertex->fetch_add(chunckSize);
        // loadNextVertex(vertex, nextVertex);
    }
}

void wedgeCentric(string path, parameter para)
{
    graph *G_first = new graph;
    graph *G_second = new graph;
    int threadNum = para.processorNum;
    int partitionNum = para.partitionNum;
    int maxVertexCount = getMaxVertexCount(path, partitionNum);
    shared_ptr<atomic<int>[]> hashTable(new atomic<int>[(long long)maxVertexCount * maxVertexCount]);
    shared_ptr<long long[]> partSum(new long long[threadNum]);
    cout << "here" << endl;
    shared_ptr<atomic<int>> nextVertex(new atomic<int>(threadNum * chunckSize));
    memset(&hashTable[0], 0, sizeof(int) * maxVertexCount * maxVertexCount);
    memset(&partSum[0], 0, sizeof(long long) * threadNum);
    thread threads[threadNum];
    cout << threadNum << " startt! " << endl;
    double startTime = wtime();

    long long ans = 0;
    for (int i = 0; i < partitionNum; i++)
    {
        G_first->loadGraph(path + "partition" + to_string(partitionNum) + "/dst" + to_string(i));
        for (int j = 0; j < partitionNum; j++)
        {
            G_second->loadGraph(path + "partition" + to_string(partitionNum) + "/dst" + to_string(j));
            *nextVertex = threadNum * chunckSize;
            for (int threadId = 0; threadId < threadNum; threadId++)
            {
                threads[threadId] = thread(wedgeCentric_kernel, hashTable, G_first, G_second, threadNum, threadId, &partSum[threadId], nextVertex, partitionNum, i, maxVertexCount);
            }
            for (auto &t : threads)
            {
                t.join();
            }
            for (int i = 0; i < threadNum; i++)
            {
                ans += partSum[i];
                partSum[i] = 0;
            }
            //clear hash table
            if (G_first->edgeCount / double(G_first->vertexCount) > G_first->vertexCount / partitionNum)
            {
                memset(&hashTable[0], 0, sizeof(int) * maxVertexCount * maxVertexCount);
            }
            else
            {
                *nextVertex = threadNum * chunckSize;
                for (int threadId = 0; threadId < threadNum; threadId++)
                {
                    threads[threadId] = thread(cleanHashTable_kernel, hashTable, G_first, G_second, threadNum, threadId, &partSum[threadId], nextVertex, partitionNum, i, maxVertexCount);
                }
                for (auto &t : threads)
                {
                    t.join();
                }
            }
        }
    }
    cout << ans << " " << wtime() - startTime << endl;
}

void sharedHashTable_kernel(shared_ptr<atomic<int>[]> hashTable, graph *G, int threadNum, int threadId, long long *partSum, shared_ptr<atomic<int>> nextVertex)
{
    // long long partSum = 0;
    int vertexCount = G->vertexCount;
    long long *beginPosFirst = G->beginPos;  // LL[vertexCount + 1];
    int *edgeListFirst = G->edgeList;        // int[G->edgeCount];
    long long *beginPosSecond = G->beginPos; // LL[vertexCount + 1];
    int *edgeListSecond = G->edgeList;       // int[G->edgeCount];
    int vertex = threadId * chunckSize;
    int count = 0;
    for (; vertex < vertexCount;)
    {
        int vertexDegree = beginPosFirst[vertex + 1] - beginPosFirst[vertex];
        for (int oneHopNeighborID = beginPosFirst[vertex]; oneHopNeighborID < beginPosFirst[vertex + 1]; oneHopNeighborID += 1)
        {
            int oneHopNeighbor = edgeListFirst[oneHopNeighborID];
            int bound = vertex < oneHopNeighbor ? vertex : oneHopNeighbor;
            for (int twoHopNeighborID = beginPosSecond[oneHopNeighbor]; twoHopNeighborID < beginPosSecond[oneHopNeighbor + 1]; twoHopNeighborID += 1)
            {
                int twoHopNeighbor = edgeListSecond[twoHopNeighborID];
                if (twoHopNeighbor >= bound)
                    break;
                *partSum += hashTable[threadId * vertexCount + twoHopNeighbor].fetch_add(1);
                // hashTable[threadId * vertexCount + twoHopNeighbor]++;
            }
        }
        if (vertexDegree * vertexDegree > vertexCount) //choose the lower costs method
        {
            for (int i = threadId * vertexCount; i < (threadId + 1) * vertexCount; i++)
            {
                hashTable[i] = 0;
            }
        }
        else
        {
            for (int oneHopNeighborID = beginPosFirst[vertex]; oneHopNeighborID < beginPosFirst[vertex + 1]; oneHopNeighborID += 1)
            {
                int oneHopNeighbor = edgeListFirst[oneHopNeighborID];
                int bound = vertex < oneHopNeighbor ? vertex : oneHopNeighbor;
                for (int twoHopNeighborID = beginPosSecond[oneHopNeighbor]; twoHopNeighborID < beginPosSecond[oneHopNeighbor + 1]; twoHopNeighborID += 1)
                {
                    int twoHopNeighbor = edgeListSecond[twoHopNeighborID];
                    if (twoHopNeighbor >= bound)
                        break;
                    hashTable[threadId * vertexCount + twoHopNeighbor] = 0;
                }
            }
        }
        // cout << vertex << endl;
        // vertex += threadNum;
        if ((vertex + 1) % chunckSize != 0)
        {
            vertex++;
        }
        else
        {
            vertex = nextVertex->fetch_add(chunckSize);
        }
        // count++;
    }
}

void sharedHashTable(graph *G, int threadNum)
{
    int vertexCount = G->vertexCount;
    shared_ptr<atomic<int>[]> hashTable(new atomic<int>[threadNum * vertexCount]);
    shared_ptr<long long[]> partSum(new long long[threadNum]);
    shared_ptr<atomic<int>> nextVertex(new atomic<int>(threadNum * chunckSize));
    memset(&hashTable[0], 0, sizeof(int) * threadNum * vertexCount);
    memset(&partSum[0], 0, sizeof(long long) * threadNum);
    thread threads[threadNum];
    cout << threadNum << " startt! ";
    double startTime = wtime();

    for (int threadId = 0; threadId < threadNum; threadId++)
    {
        threads[threadId] = thread(sharedHashTable_kernel, hashTable, G, threadNum, threadId, &partSum[threadId], nextVertex);
    }
    for (auto &t : threads)
    {
        t.join();
    }
    long long ans = 0;
    for (int i = 0; i < threadNum; i++)
    {
        ans += partSum[i];
    }
    cout << ans << " " << wtime() - startTime << endl;
}

void BC_CPU(string path, graph *G, parameter para, bool concurrentBench)
{
    if (concurrentBench)
    {
        sharedHashTable(G, para.processorNum);
    }
    else
    {
        if (para.varient == edgecentric)
        {
            edgeCentric(path, para);
        }
        else
        {
            wedgeCentric(path, para);
        }
    }
}
