#include <bits/stdc++.h>
#include <cilk/cilk.h>
#include <cilk/cilk_api.h>
#include <cilk/reducer_opadd.h>
#include "BFC-VP++.h"
#include <tbb/concurrent_hash_map.h>
#include <tbb/tbb_allocator.h>
#include "tbb/tick_count.h"
#include "timer.h"
using namespace std;

typedef long long LL;
//const int hashSizePerThread = 50000000;
int blockNum = 32; //128

struct hashNode
{
    int val, t;
    LL s;
};

LL hashInsert(hashNode *hashList, int key, int mod, int t)
{
    if (hashList[key].t != t)
    {
        hashList[key].t = t;
        hashList[key].val = 1;
        return 0;
    }
    else
    {
        hashList[key].val++;
        return hashList[key].val - 1;
    }
}

//typedef tbb::concurrent_hash_map<int,LL> HashTable;

// LL hashInsert(HashTable& hashList, int val){
//     HashTable::accessor a;
//     LL res = 0;
//     hashList.insert(a, val);
//     res = a->second;
//     a->second += 1;
//     // if (hashList.find(a, val)){
//     //     res = a->second;
//     //     a->second += 1;
//     //     a.release();
//     // }else{
//     //     hashList.insert(a, val);
//     //     a->second = 1;
//     //     a.release();
//     // }
//     return res;
// }
res test(char *path, int bound, int threadNum)
{
    tbb::tick_count mainStartTime = tbb::tick_count::now();
    graph g;
    g.loadgraph(path, -1);

    int vertexCount = g.vertexCount;
    int hashSizePerThread = vertexCount;
    LL *beginPos = g.beginPos1; // LL[vertexCount + 1];
    int *edgeList = g.edgeList; // int[g.edgeCount];
    //memcpy(beginPos, g.beginPos1, sizeof(LL) * (g.vertexCount + 1));
    //memcpy(edgeList, g.edgeList, sizeof(int) * (g.edgeCount));
    char threadNumStr[255];
    sprintf(threadNumStr, "%d", threadNum);
    blockNum = threadNum;
    // __cilkrts_set_param("nworkers", threadNumStr);
    hashNode *hashList = new hashNode[1LL * (blockNum + 1) * hashSizePerThread];
    cout << "startt!" << endl;
    cilk::reducer_opadd<LL> ans;
    tbb::tick_count calcStartTime = tbb::tick_count::now();
    //tbb::tick_count mainStartTime = tbb::tick_count::now();
    cilk_for(int i = 0; i < blockNum; i++)
    {
        LL partSum = 0;
        for (int u = i; u < vertexCount; u += blockNum)
        {
            //hashList.clear();
            int l = beginPos[u];
            int r = beginPos[u + 1];

            for (int j = l; j < r; j++)
            {
                int v = edgeList[j];
                int vv = min(u, v);
                int ll = beginPos[v];
                int rr = beginPos[v + 1];
                for (int k = ll; k < rr; k++)
                {
                    int w = edgeList[k];
                    if (w >= vv)
                        break;
                    partSum += hashInsert(hashList + 1LL * i * hashSizePerThread, w, hashSizePerThread, u);
                }
            }
        }
        ans += partSum;
    }
    LL ans1 = ans.get_value();
    double tTotal = (tbb::tick_count::now() - mainStartTime).seconds();
    double tCalc = (tbb::tick_count::now() - calcStartTime).seconds();
    printf("%lld\n", ans1);
    printf("total time:%f\n", tTotal);
    printf("calc time %f\n", tCalc);
    //delete beginPos;
    //delete edgeList;
    delete hashList;
    return res(tTotal, tCalc, ans1);
}