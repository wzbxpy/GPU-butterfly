#include <bits/stdc++.h>
#include "graph.h"
#include "BFC-VP++/BFC-VP++.h"
using namespace std;

#define For(i, l, r) for (int i = l; i <= r; i++)

void check(graph &g, int nodeBegin, int nodeEnd)
{
    //upBound = 2;
    printf("----------check------------\n");
    if (nodeEnd == -1)
        nodeEnd = g.vertexCount - 1;
    long long ds = 0;
    For(node, 0, nodeEnd)
    {
        vector<int> lst;
        For(i, g.beginPos[node], g.beginPos[node + 1] - 1)
        {
            int v = g.edgeList[i];
            int vv = min(node, v);
            For(j, g.beginPos[v], g.beginPos[v + 1] - 1)
            {
                if (g.edgeList[j] < vv)
                    lst.push_back(g.edgeList[j]);
                else
                    break;
            }
        }
        sort(lst.begin(), lst.end());
        int tmp = -1;
        int n = lst.size();
        long long s = 0;
        For(i, 0, n - 1)
        {
            if (lst[i] != tmp)
            {
                //if (tmp != -1) printf("%d %d\n", tmp, s);
                tmp = lst[i];
                ds += s * (s - 1) / 2;
                s = 1;
            }
            else
            {
                s++;
            }
        }
        if (node == 23141)
        {
            printf("%d\n", s * (s - 1) / 2);
        }
        ds += s * (s - 1) / 2;
    }
    printf("total butterfly is %lld\n", ds);
    printf("-----------------------\n");
}

int main(int argc, char *argv[])
{
    if (strcmp("run", argv[2]) == 0)
    {
        printf("%s %s\n", argv[5], argv[6]);
        res re = test(argv[1], atoi(argv[3]), atoi(argv[5]));
        fstream fp = fstream("ans.out", ios::app);
        fp << argv[4] << "," << re.ans << "," << re.totalTime << "," << re.calcTime << endl;
        fp.close();
    }
    return 0;
}