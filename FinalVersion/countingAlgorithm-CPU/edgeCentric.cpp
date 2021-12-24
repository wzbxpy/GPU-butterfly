#include <unordered_map>
#include <iostream>
#include <cilk/cilk.h>
#include <cilk/cilk_api.h>
#include <cilk/reducer_opadd.h>
#include <tbb/concurrent_unordered_map.h>
#include <tbb/tbb_allocator.h>
#include "edgeCentric.h"
#include "../wtime.h"
#include "../graph.h"
using namespace std;

// #define Noconcurrency

void test(graph *G, int threadNum)
{
    int vertexCount = G->vertexCount;
    long long *beginPosFirst = G->beginPos;  // LL[vertexCount + 1];
    int *edgeListFirst = G->edgeList;        // int[G->edgeCount];
    long long *beginPosSecond = G->beginPos; // LL[vertexCount + 1];
    int *edgeListSecond = G->edgeList;       // int[G->edgeCount];
#ifdef Noconcurrency
    unique_ptr<unordered_map<int, int>[]> hashmap(new unordered_map<int, int>[threadNum]);
#else
    tbb::interface5::concurrent_unordered_map<int, int> *hashmap = new tbb::interface5::concurrent_unordered_map<int, int>[threadNum];
#endif
    cout << "startt!" << endl;
    cilk::reducer_opadd<long long> ans;
    double startTime = wtime();
    __cilkrts_set_param("nworkers", to_string(threadNum).c_str());

    cilk_for(int i = 0; i < threadNum; i++)
    {
        long long partSum = 0;
        for (int vertex = i; vertex < vertexCount; vertex += threadNum)
        {
            cilk_for(int oneHopNeighborID = beginPosFirst[vertex]; oneHopNeighborID < beginPosFirst[vertex + 1]; oneHopNeighborID += 1)
            {
                int oneHopNeighbor = edgeListFirst[oneHopNeighborID];
                int bound = vertex < oneHopNeighbor ? vertex : oneHopNeighbor;
                for (int twoHopNeighborID = beginPosSecond[oneHopNeighbor]; twoHopNeighborID < beginPosSecond[oneHopNeighbor + 1]; twoHopNeighborID += 1)
                {
                    int twoHopNeighbor = edgeListSecond[twoHopNeighborID];
                    if (twoHopNeighbor >= bound)
                        break;
#ifdef Noconcurrency
                    partSum += hashmap[i][twoHopNeighbor];
                    hashmap[i][twoHopNeighbor]++;
#else
                    partSum += hashmap[i][twoHopNeighbor];
                    hashmap[i][twoHopNeighbor]++;
#endif
                }
            }
            hashmap[i].clear();
        }
        ans += partSum;
    }
    cout << ans.get_value() << " " << wtime() - startTime << endl;
    //delete beginPos;
    //delete edgeList;
}