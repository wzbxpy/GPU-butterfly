#include<bits/stdc++.h>
#include <cilk/cilk.h>
#include <cilk/cilk_api.h>
#include <cilk/reducer_opadd.h>
#include"BFC-VP++.h"
#include <tbb/concurrent_hash_map.h>
#include <tbb/tbb_allocator.h>
#include "timer.h"
using namespace std;

typedef long long LL;
const int hashSizePerThread = 50000000;
const int blockNum = 32;//128

struct hashNode {
    int val, t;
    LL s;
    hashNode() {
        t = -1;
    }
};

LL hashInsert(hashNode* hashList, int key, int mod, int t){
    if (hashList[key].t != t){
        hashList[key].t = t;
        hashList[key].val = 1;
        return 0;
    }else{
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
res test(graph& g, int bound, int threadNum) {
    int vertexCount = g.vertexCount;
    LL* beginPos = new LL[vertexCount + 1];
    int* edgeList = new int[g.edgeCount];
    memcpy(beginPos, g.beginPos1, sizeof(LL) * (g.vertexCount + 1));
    memcpy(edgeList, g.edgeList, sizeof(int) * (g.edgeCount));
    //char threadNumStr[255];
   // sprintf(threadNumStr, "%d", 32);
   // __cilkrts_set_param("nworkers", threadNumStr);
    hashNode* hashList = new hashNode[1LL * (blockNum + 1) * hashSizePerThread];
    memset(hashList, 0, sizeof(hashList));
    cout << "startt!" << endl;
    cilk::reducer_opadd<LL> ans;
    timer c;
    c.start();
    
    //tbb::tick_count mainStartTime = tbb::tick_count::now();
    cilk_for(int i = 0; i < blockNum; i++) {
        LL partSum = 0;
        for (int u = i; u < vertexCount; u += blockNum) {
            //hashList.clear(); 
            int l = beginPos[u];
            int r = beginPos[u + 1];

            
            for(int j = l; j < r; j++) {
                int v = edgeList[j];
                int vv = min(u, v);
                int ll = beginPos[v];
                int rr = beginPos[v + 1];
                for (int k = ll; k < rr; k++) {
                    int w = edgeList[k];
                    if (w >= vv) break;
                    partSum += hashInsert(hashList + i * hashSizePerThread, w, hashSizePerThread, u);
                }
            }
        }
        ans += partSum;
    }
    c.fin();
    printf("%f\n",c.getTime());
    printf("%lld\n", ans.get_value());
}