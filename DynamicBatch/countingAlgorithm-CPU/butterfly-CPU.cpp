#include <unordered_map>
#include <iostream>
#include <fstream>
#include <cmath>
#include <atomic>
#include <thread>
#include <memory>
#include <mutex>
#include <cstring>
#include "butterfly-CPU.h"
#include "../wtime.h"
#include "../graph.h"
#include <stdlib.h>
#include <queue>
#include <vector>
using namespace std;
const int chunckSize = 5;

struct tas_lock
{
    std::atomic<bool> lock_ = {false};

    void lock()
    {
        for (;;)
        {
            if (!lock_.exchange(true, std::memory_order_acquire))
            {
                break;
            }
            while (lock_.load(std::memory_order_relaxed))
            {
                __builtin_ia32_pause();
            }
        }
    }
    inline bool trylock()
    {
        if (!lock_.exchange(true, std::memory_order_acquire))
        {
            return true;
        }
        return false;
    }
    void unlock() { lock_.store(false, std::memory_order_release); }
};

int getMaxVertexCount(string path, int partitionNum)
{
    int vertexCount, x;
    fstream propertiesFile(path + "partition" + to_string(partitionNum) + "dst0/properties.txt", ios::in);
    propertiesFile >> x >> vertexCount;
    vertexCount += x;
    propertiesFile.close();
    // vertexCount = ceil(vertexCount / double(partitionNum));
    return vertexCount;
}

inline void loadNextVertex(int &vertex, atomic<int> *nextVertex, int offsets)
{
    vertex = (vertex - offsets + 1) % chunckSize != 0 ? vertex + 1 : nextVertex->fetch_add(chunckSize);
}

void edgeCentric_kernel(int *hashTable, graph *G_src, graph *G_dst, int threadNum, int threadId, long long *partSum, shared_ptr<atomic<int>> nextVertex, int partitionNumSrc, int partitionNumDst, int vertexOffsets, long long maxVertexCount, long long beginPosition[], long long endPosition[], int dstOffsets)
{
    int vertex = dstOffsets / partitionNumDst + threadId * chunckSize;
    long long mySum = 0;
    hashTable += threadId * maxVertexCount;
    for (; vertex < G_src->vertexCount;)
    // for (; vertex < dstOffsets / partitionNumDst;)
    {
        int vertexDegree = G_src->beginPos[vertex + 1] - G_src->beginPos[vertex];
        if (vertexDegree < 2)
            break;
        // creat hashtable and count
        for (auto oneHopNeighborID = G_src->beginPos[vertex]; oneHopNeighborID < G_src->beginPos[vertex + 1]; oneHopNeighborID += 1)
        {
            int oneHopNeighbor = G_src->edgeList[oneHopNeighborID];
            if (oneHopNeighbor < dstOffsets)
                continue;
            int bound = vertex * partitionNumSrc + vertexOffsets < oneHopNeighbor ? vertex * partitionNumSrc + vertexOffsets : oneHopNeighbor;
            for (auto twoHopNeighborID = beginPosition[oneHopNeighbor]; twoHopNeighborID < endPosition[oneHopNeighbor]; twoHopNeighborID += 1)
            {
                int twoHopNeighbor = G_dst->edgeList[twoHopNeighborID];
                if (twoHopNeighbor >= bound)
                    break;
                if (partitionNumDst == 1)
                    mySum += hashTable[twoHopNeighbor - dstOffsets]++;
                else
                    mySum += hashTable[(twoHopNeighbor - dstOffsets) / partitionNumDst]++;
            }
        }
        // clean hashtable
        if (G_dst->edgeCount / G_dst->vertexCount > G_dst->vertexCount / vertexDegree) // choose the lower costs method
        // if (0)
        {
            memset(hashTable, 0, sizeof(int) * maxVertexCount);
        }
        else
        {
            for (auto oneHopNeighborID = G_src->beginPos[vertex]; oneHopNeighborID < G_src->beginPos[vertex + 1]; oneHopNeighborID += 1)
            {
                int oneHopNeighbor = G_src->edgeList[oneHopNeighborID];
                if (oneHopNeighbor < dstOffsets)
                    continue;
                int bound = vertex * partitionNumSrc + vertexOffsets < oneHopNeighbor ? vertex * partitionNumSrc + vertexOffsets : oneHopNeighbor;
                for (auto twoHopNeighborID = beginPosition[oneHopNeighbor]; twoHopNeighborID < endPosition[oneHopNeighbor]; twoHopNeighborID += 1)
                {
                    int twoHopNeighbor = G_dst->edgeList[twoHopNeighborID];
                    if (twoHopNeighbor >= bound)
                        break;
                    if (partitionNumDst == 1)
                        hashTable[twoHopNeighbor - dstOffsets] = 0;
                    else
                        hashTable[(twoHopNeighbor - dstOffsets) / partitionNumDst] = 0;
                }
            }
        }
        // load next vertex
        // vertex = (vertex + 1) % chunckSize != 0 ? vertex + 1 : nextVertex->fetch_add(chunckSize);
        loadNextVertex(vertex, nextVertex.get(), dstOffsets / partitionNumDst);
        // vertex += threadNum;
    }
    *partSum = mySum;
}

// Partition the neighbor list into several parts. Thus the hash tabel can be fit into the memory.
// Given the partition id, i.e. boundary of dst id, obtaining the begin and end position of each neighborlist
void initializeBeginPosition_kernel(long long beginPosition[], long long endPosition[], graph *G, int threadNum, int threadId, int boundary, bool isFirst, bool isLast, int startVertex)
{
    int range = (G->vertexCount - startVertex) / threadNum;
    int start = startVertex + threadId * range;
    int end = start + range;
    if (threadId + 1 == threadNum)
        end = G->vertexCount;
    if (isFirst) // The first begin position need to be initialized
    {
        for (int vertex = start; vertex < end; vertex++)
            beginPosition[vertex] = G->beginPos[vertex];
    }
    if (isLast) // The last part of end position can be directly obtained
    {
        for (int vertex = start; vertex < end; vertex++)
            endPosition[vertex] = G->beginPos[vertex + 1];
    }
    else
    {
        for (int vertex = start; vertex < end; vertex++)
        {
            long long pos;
            int bound = boundary < vertex ? boundary : vertex;
            for (pos = beginPosition[vertex]; pos < G->beginPos[vertex + 1]; pos++)
                if (G->edgeList[pos] >= bound)
                    break;
            endPosition[vertex] = pos;
        }
    }
}

void edgeCentric(string path, parameter para)
{
    // initilize
    graph *G_src = new graph;
    graph *G_dst = new graph;
    int threadNum = para.processorNum;
    int partitionNumSrc = para.partitionNum;
    int partitionNumDst = para.partitionNum;
    int vertexCount = getMaxVertexCount(path, partitionNumDst);
    long long maxVertexCountInBatch = ceil(vertexCount / (double)para.batchNum / (double)partitionNumDst);
    shared_ptr<int[]> hashTable(new int[threadNum * maxVertexCountInBatch]);
    shared_ptr<long long[]> Position(new long long[vertexCount * 2]);
    shared_ptr<long long[]> partSum(new long long[threadNum]);
    shared_ptr<atomic<int>> nextVertex(new atomic<int>(threadNum * chunckSize));
    memset(&hashTable[0], 0, sizeof(int) * threadNum * maxVertexCountInBatch);
    memset(&partSum[0], 0, sizeof(long long) * threadNum);

    // launch threads
    thread threads[threadNum];
    double startTime = wtime();
    double transferTime = 0, computeTime = 0, initializeTime = 0;
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
            for (int b = 0; b < para.batchNum; b++)
            {
                startTime = wtime();
                // initilize start position of this batch
                for (int threadId = 0; threadId < threadNum; threadId++)
                    threads[threadId] = thread(initializeBeginPosition_kernel, &Position[(b % 2) * vertexCount], &Position[((b + 1) % 2) * vertexCount], G_dst, threadNum, threadId, maxVertexCountInBatch * partitionNumDst * (b + 1), b == 0, b == para.batchNum - 1, maxVertexCountInBatch * partitionNumDst * b);
                for (auto &t : threads)
                    t.join();
                initializeTime += getDeltaTime(startTime);
                *nextVertex = threadNum * chunckSize + maxVertexCountInBatch * b;
                // count the butterfies in each batch
                for (int threadId = 0; threadId < threadNum; threadId++)
                    threads[threadId] = thread(edgeCentric_kernel, hashTable.get(), G_src, G_dst, threadNum, threadId, &partSum[threadId], nextVertex, partitionNumSrc, partitionNumDst, i, maxVertexCountInBatch, &Position[(b % 2) * vertexCount], &Position[((b + 1) % 2) * vertexCount], maxVertexCountInBatch * partitionNumDst * b);
                for (auto &t : threads)
                    t.join();
                computeTime += getDeltaTime(startTime);

                for (int i = 0; i < threadNum; i++)
                {
                    ans += partSum[i];
                    partSum[i] = 0;
                }
            }
        }
    }
    // cout << ans << " " << (initializeTime + computeTime) << " " << transferTime << endl;
    cout << ans << " " << initializeTime << " " << computeTime << " " << transferTime << endl;
}

// emrc
void EMRC_kernel(shared_ptr<int[]> hashTable, graph *G_first, graph *G_second, int threadNum, int threadId, long long *partSum, shared_ptr<atomic<int>> nextVertex, int partitionNum, int vertexOffsets, int maxVertexCount)
{
    int vertex = threadId * chunckSize;
    long long mySum = 0;
    for (; vertex < G_first->vertexCount;)
    {
        for (auto firstNeighborID = G_first->beginPos[vertex]; firstNeighborID < G_first->beginPos[vertex + 1]; firstNeighborID += 1)
        {
            int firstNeighbor = G_first->edgeList[firstNeighborID];
            int bound = vertex < firstNeighbor ? vertex : firstNeighbor;
            for (auto secondNeighborID = G_second->beginPos[vertex]; secondNeighborID < G_second->beginPos[vertex + 1]; secondNeighborID += 1)
            {
                int secondNeighbor = G_second->edgeList[secondNeighborID];
                if (secondNeighbor >= bound)
                    break;
                mySum += hashTable[(firstNeighbor / partitionNum) * maxVertexCount + (secondNeighbor / partitionNum)]++;
            }
        }
        // load next vertex
        loadNextVertex(vertex, nextVertex.get(), 0);
    }
    *partSum += mySum;
}
void cleanHashTable_kernel(shared_ptr<int[]> hashTable, graph *G_first, graph *G_second, int threadNum, int threadId, long long *partSum, shared_ptr<atomic<int>> nextVertex, int partitionNum, int vertexOffsets, int maxVertexCount)
{
    int vertex = threadId * chunckSize;
    for (; vertex < G_first->vertexCount;)
    {
        for (auto firstNeighborID = G_first->beginPos[vertex]; firstNeighborID < G_first->beginPos[vertex + 1]; firstNeighborID += 1)
        {
            int firstNeighbor = G_first->edgeList[firstNeighborID];
            int bound = vertex < firstNeighbor ? vertex : firstNeighbor;
            for (auto secondNeighborID = G_second->beginPos[vertex]; secondNeighborID < G_second->beginPos[vertex + 1]; secondNeighborID += 1)
            {
                int secondNeighbor = G_second->edgeList[secondNeighborID];
                if (secondNeighbor >= bound)
                    break;
                hashTable[(firstNeighbor / partitionNum) * maxVertexCount + (secondNeighbor / partitionNum)] = 0;
            }
        }
        // load next vertex
        loadNextVertex(vertex, nextVertex.get(), 0);
    }
}
void memset_kernel_withoutAtomic(shared_ptr<int[]> hashTable, long long offset, long long length)
{
    memset(&hashTable[offset], 0, sizeof(int) * length);
}

void EMRC(string path, parameter para)
{
    cout << "EMRC" << endl;
    graph *G_first = new graph;
    graph *G_second = new graph;
    int threadNum = para.processorNum;
    int partitionNum = para.partitionNum;
    long long maxVertexCount = ceil(getMaxVertexCount(path, partitionNum) / (double)partitionNum);
    shared_ptr<int[]> hashTable(new int[(long long)maxVertexCount * maxVertexCount]);
    shared_ptr<long long[]> partSum(new long long[threadNum]);
    shared_ptr<atomic<int>> nextVertex(new atomic<int>(threadNum * chunckSize));
    memset(&hashTable[0], 0, sizeof(int) * maxVertexCount * maxVertexCount);
    memset(&partSum[0], 0, sizeof(long long) * threadNum);
    thread threads[threadNum];
    double startTime = wtime();
    double transferTime = 0, computeTime = 0, clearTime = 0;

    long long ans = 0;
    for (int i = 0; i < partitionNum; i++)
    {
        transferTime += G_first->loadGraph(path + "partition" + to_string(partitionNum) + "dst" + to_string(i));
        for (int j = 0; j < partitionNum; j++)
        {
            transferTime += G_second->loadGraph(path + "partition" + to_string(partitionNum) + "dst" + to_string(j));
            startTime = wtime();
            *nextVertex = threadNum * chunckSize;
            for (int threadId = 0; threadId < threadNum; threadId++)
            {
                threads[threadId] = thread(EMRC_kernel, hashTable, G_first, G_second, threadNum, threadId, &partSum[threadId], nextVertex, partitionNum, i, maxVertexCount);
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
            computeTime += getDeltaTime(startTime);
            // clear hash table
            if (G_first->edgeCount / double(G_first->vertexCount) > G_first->vertexCount / partitionNum)
            {
                long long length = maxVertexCount * maxVertexCount / threadNum;
                for (int threadId = 0; threadId < threadNum; threadId++)
                {
                    threads[threadId] = thread(memset_kernel_withoutAtomic, hashTable, length * threadId, length);
                }
                memset(&hashTable[length * threadNum], 0, maxVertexCount * maxVertexCount - length * threadNum);
                for (auto &t : threads)
                {
                    t.join();
                }
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
            clearTime += getDeltaTime(startTime);
        }
    }
    cout << ans << " " << clearTime << " " << computeTime << " " << transferTime << endl;
}

static int computeEndPosition(long long beginPos1[], long long beginPos2[], int previousVertex, int lastVertex, long long batchsize, int &breakPoint)
{
    int l = previousVertex, r = lastVertex;
    int previouscount = beginPos1[previousVertex] + beginPos2[previousVertex];
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

void wedgeCentric_kernel_withoutAtomic(shared_ptr<int[]> hashTable, long long beginPosFirst[], int edgeListFirst[], long long beginPosSecond[], int edgeListSecond[], int threadNum, int threadId, long long *partSum, shared_ptr<atomic<int>> nextVertex, int partitionNum, int vertexOffsets, long long maxVertexCount, int lastVertex, int previousVertex, tas_lock *lock)
{
    int vertex = previousVertex + threadId * chunckSize;
    long long mySum = 0;
    long long beginPosFirstOffset = beginPosFirst[previousVertex];
    long long beginPosSecondOffset = beginPosSecond[previousVertex];
    int flag = edgeListFirst[0] % partitionNum > edgeListSecond[0] % partitionNum;
    queue<int> Q;
    vector<int> P;
    for (; vertex < lastVertex;)
    {
        for (auto firstNeighborID = beginPosFirst[vertex]; firstNeighborID < beginPosFirst[vertex + 1]; firstNeighborID += 1)
            Q.push(edgeListFirst[firstNeighborID - beginPosFirstOffset] / partitionNum);
        for (auto secondNeighborID = beginPosSecond[vertex]; secondNeighborID < beginPosSecond[vertex + 1]; secondNeighborID += 1)
        {
            int secondNeighbor = edgeListSecond[secondNeighborID - beginPosSecondOffset];
            if (secondNeighbor >= vertex)
                break;
            P.push_back(secondNeighbor / partitionNum);
        }
        while (!Q.empty())
        {
            int firstNeighbor = Q.front();
            Q.pop();
            if (lock[firstNeighbor].trylock())
            {
                long long offset = firstNeighbor * maxVertexCount;
                int bound = firstNeighbor + flag;
                for (auto secondNeighbor : P)
                {
                    if (secondNeighbor >= bound)
                        break;
                    mySum += hashTable[offset + secondNeighbor]++;
                }
                lock[firstNeighbor].unlock();
            }
            else
            {
                Q.push(firstNeighbor);
            }
        }
        P.clear();
        // load next vertex
        loadNextVertex(vertex, nextVertex.get(), previousVertex);
        // vertex += threadNum;
    }
    *partSum += mySum;
}

void wedgeCentric(string path, parameter para)
{
    graph *G_first = new graph;
    graph *G_second = new graph;
    int threadNum = para.processorNum;
    int partitionNum = para.partitionNum;
    long long maxVertexCount = ceil(getMaxVertexCount(path, partitionNum) / (double)partitionNum);
    shared_ptr<int[]> hashTable(new int[(long long)maxVertexCount * maxVertexCount]);
    shared_ptr<long long[]> partSum(new long long[threadNum]);
    shared_ptr<atomic<int>> nextVertex(new atomic<int>(threadNum * chunckSize));
    shared_ptr<tas_lock[]> lock(new tas_lock[maxVertexCount]);
    memset(&hashTable[0], 0, sizeof(int) * maxVertexCount * maxVertexCount);
    memset(&partSum[0], 0, sizeof(long long) * threadNum);
    thread threads[threadNum];
    long long batchSize = 0;
    long long ans = 0;
    int *edgeList;
    double startTime = wtime();
    double transferTime = 0, computeTime = 0, clearTime = 0;
    for (int i = 0; i < partitionNum; i++)
    {
        for (int j = 0; j < partitionNum; j++)
        {
            // load begpos and initilize
            startTime = wtime();

            G_first->loadBeginPos(path + "partition" + to_string(partitionNum) + "dst" + to_string(i));
            G_second->loadBeginPos(path + "partition" + to_string(partitionNum) + "dst" + to_string(j));
            transferTime += getDeltaTime(startTime);
            if (batchSize == 0)
            {
                batchSize = (G_first->edgeCount + G_second->edgeCount) / para.batchNum + 100;
                edgeList = new int[batchSize];
            }
            int previousEnd = 0;
            int thisEnd = 0;
            int breakPoint = 0;
            fstream firstEdgeListFile(path + "partition" + to_string(partitionNum) + "dst" + to_string(i) + "/adj.bin", ios::in | ios::binary);
            fstream secondEdgeListFile(path + "partition" + to_string(partitionNum) + "dst" + to_string(j) + "/adj.bin", ios::in | ios::binary);
            computeTime += getDeltaTime(startTime);
            // load each batch of data
            for (;;)
            {
                startTime = wtime();
                *nextVertex = previousEnd + threadNum * chunckSize;
                thisEnd = computeEndPosition(G_first->beginPos, G_second->beginPos, previousEnd, G_first->vertexCount, batchSize, breakPoint);
                if (thisEnd == previousEnd)
                    break;
                computeTime += getDeltaTime(startTime);
                firstEdgeListFile.read((char *)edgeList, sizeof(int) * (G_first->beginPos[thisEnd] - G_first->beginPos[previousEnd]));
                secondEdgeListFile.read((char *)(&edgeList[breakPoint]), sizeof(int) * (G_second->beginPos[thisEnd] - G_second->beginPos[previousEnd]));
                transferTime += getDeltaTime(startTime);

                for (int threadId = 0; threadId < threadNum; threadId++)
                {
                    threads[threadId] = thread(wedgeCentric_kernel_withoutAtomic, hashTable, G_first->beginPos, edgeList, G_second->beginPos, edgeList + breakPoint, threadNum, threadId, &partSum[threadId], nextVertex, partitionNum, i, maxVertexCount, thisEnd, previousEnd, lock.get());
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
                previousEnd = thisEnd;
                computeTime += getDeltaTime(startTime);
            }
            firstEdgeListFile.close();
            secondEdgeListFile.close();
            // cout << hashTable[2049] << endl;
            // clear hash table
            startTime = wtime();
            long long length = maxVertexCount * maxVertexCount / threadNum;
            for (int threadId = 0; threadId < threadNum; threadId++)
            {
                threads[threadId] = thread(memset_kernel_withoutAtomic, hashTable, length * threadId, length);
            }
            memset(&hashTable[length * threadNum], 0, (maxVertexCount * maxVertexCount - length * threadNum) * sizeof(int));
            for (auto &t : threads)
            {
                t.join();
            }
            clearTime += getDeltaTime(startTime);
        }
    }
    delete (edgeList);
    cout << ans << " " << clearTime << " " << computeTime << " " << transferTime << endl;
}

void sharedHashTable_kernel(shared_ptr<atomic<int>[]> hashTable, graph *G, int threadNum, int threadId, long long *partSum, int vertex)
{
    // long long partSum = 0;
    int vertexCount = G->vertexCount;
    long long *beginPos = G->beginPos; // LL[vertexCount + 1];
    int *edgeList = G->edgeList;       // int[G->edgeCount];
    long long mySum = 0;

    for (auto oneHopNeighborID = beginPos[vertex] + threadId; oneHopNeighborID < beginPos[vertex + 1]; oneHopNeighborID += threadNum)
    {
        int oneHopNeighbor = edgeList[oneHopNeighborID];
        int bound = vertex < oneHopNeighbor ? vertex : oneHopNeighbor;
        for (auto twoHopNeighborID = beginPos[oneHopNeighbor]; twoHopNeighborID < beginPos[oneHopNeighbor + 1]; twoHopNeighborID += 1)
        {
            int twoHopNeighbor = edgeList[twoHopNeighborID];
            if (twoHopNeighbor >= bound)
                break;
            mySum += hashTable[twoHopNeighbor].fetch_add(1);
        }
    }
    *partSum += mySum;
}

void cleanSharedHashTable_kernel(shared_ptr<atomic<int>[]> hashTable, graph *G, int threadNum, int threadId, long long *partSum, int vertex)
{
    // long long partSum = 0;
    int vertexCount = G->vertexCount;
    long long *beginPos = G->beginPos; // LL[vertexCount + 1];
    int *edgeList = G->edgeList;       // int[G->edgeCount];
    long long mySum = 0;

    for (auto oneHopNeighborID = beginPos[vertex] + threadId; oneHopNeighborID < beginPos[vertex + 1]; oneHopNeighborID += threadNum)
    {
        int oneHopNeighbor = edgeList[oneHopNeighborID];
        int bound = vertex < oneHopNeighbor ? vertex : oneHopNeighbor;
        for (auto twoHopNeighborID = beginPos[oneHopNeighbor]; twoHopNeighborID < beginPos[oneHopNeighbor + 1]; twoHopNeighborID += 1)
        {
            int twoHopNeighbor = edgeList[twoHopNeighborID];
            if (twoHopNeighbor >= bound)
                break;
            hashTable[twoHopNeighbor] = 0;
        }
    }
}

void sharedHashTable_kernel_withoutScheduling(shared_ptr<atomic<int>[]> hashTable, graph *G, int threadNum, int threadId, long long *partSum)
{
    // long long partSum = 0;
    int vertexCount = G->vertexCount;
    long long *beginPos = G->beginPos; // LL[vertexCount + 1];
    int *edgeList = G->edgeList;       // int[G->edgeCount];
    long long mySum = 0;

    for (int vertex = 0; vertex < G->vertexCount; vertex++)
    {
        if (G->beginPos[vertex + 1] - G->beginPos[vertex] < 2)
            break;
        for (auto oneHopNeighborID = beginPos[vertex] + threadId; oneHopNeighborID < beginPos[vertex + 1]; oneHopNeighborID += threadNum)
        {
            int oneHopNeighbor = edgeList[oneHopNeighborID];
            int bound = vertex < oneHopNeighbor ? vertex : oneHopNeighbor;
            for (auto twoHopNeighborID = beginPos[oneHopNeighbor]; twoHopNeighborID < beginPos[oneHopNeighbor + 1]; twoHopNeighborID += 1)
            {
                int twoHopNeighbor = edgeList[twoHopNeighborID];
                if (twoHopNeighbor >= bound)
                    break;
                mySum += hashTable[twoHopNeighbor].fetch_add(1);
            }
        }
    }
    *partSum += mySum;
}
void sharedHashTable(graph *G, int threadNum)
{
    int vertexCount = G->vertexCount;
    shared_ptr<atomic<int>[]> hashTable(new atomic<int>[threadNum * vertexCount]);
    shared_ptr<long long[]> partSum(new long long[threadNum]);
    memset(&hashTable[0], 0, sizeof(int) * threadNum * vertexCount);
    memset(&partSum[0], 0, sizeof(long long) * threadNum);
    thread threads[threadNum];
    double startTime = wtime();
    long long ans = 0;
    cout << threadNum << endl;
    for (int vertex = 0; vertex < G->vertexCount; vertex++)
    {
        if (G->beginPos[vertex + 1] - G->beginPos[vertex] < 2)
            break;
        for (int threadId = 0; threadId < threadNum; threadId++)
        {
            threads[threadId] = thread(sharedHashTable_kernel, hashTable, G, threadNum, threadId, &partSum[threadId], vertex);
        }
        for (auto &t : threads)
        {
            t.join();
        }
        for (int threadId = 0; threadId < threadNum; threadId++)
        {
            threads[threadId] = thread(cleanSharedHashTable_kernel, hashTable, G, threadNum, threadId, &partSum[threadId], vertex);
        }
        for (auto &t : threads)
        {
            t.join();
        }
    }
    // for (int threadId = 0; threadId < threadNum; threadId++)
    // {
    //     threads[threadId] = thread(sharedHashTable_kernel_withoutScheduling, hashTable, G, threadNum, threadId, &partSum[threadId]);
    // }
    // for (auto &t : threads)
    // {
    //     t.join();
    // }
    // for (int i = 0; i < threadNum; i++)
    // {
    //     ans += partSum[i];
    // }
    cout << ans << " " << wtime() - startTime << endl;
}

void BC_CPU(string path, graph *G, parameter para, bool concurrentBench, bool testEMRC)
{
    if (concurrentBench)
    {
        sharedHashTable(G, para.processorNum);
        return;
    }
    if (testEMRC)
    {
        EMRC(path, para);
        return;
    }
    if (para.varient == edgecentric)
    {
        edgeCentric(path, para);
    }
    else
    {
        wedgeCentric(path, para);
    }
}
