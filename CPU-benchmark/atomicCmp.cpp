#include <atomic>
#include <thread>
#include <iostream>
using namespace std;

void directlyinc(int n, int threadId, shared_ptr<int[]> a)
{
    // int x = 0;
    // for (auto j = 1; j < 100; j++)
    for (auto i = threadId * n; i < (threadId + 1) * (n); i++)
        // for (auto i = 0; i < (n); i++)
        a[i]++;
}
void directlyWrite(int n, int threadNum)
{
    shared_ptr<int[]> a(new int[n * threadNum]);
    thread threads[threadNum];
    double start = clock();

    for (int threadId = 0; threadId < threadNum; threadId++)
    {
        threads[threadId] = thread(directlyinc, n, threadId, a);
    }
    for (auto &t : threads)
    {
        t.join();
    }
    cout << (clock() - start) / CLOCKS_PER_SEC << endl;
    // for (int i = 0; i <= 100; i++)
    //     cout << a[i] << endl;
}

void atomicinc(int n, int threadId, shared_ptr<atomic<int>[]> a)
{
    // int x = 0;
    // for (auto j = 1; j < 100; j++)
    for (auto i = threadId * n; i < (threadId + 1) * (n); i++)
    // for (auto i = 0; i < (n); i++)
    {
        a[i].fetch_add(1);
    }
}
void atomicWrite(int n, int threadNum)
{
    shared_ptr<atomic<int>[]> a(new atomic<int>[n * threadNum]);
    thread threads[threadNum];
    double start = clock();
    for (int threadId = 0; threadId < threadNum; threadId++)
    {
        threads[threadId] = thread(atomicinc, n, threadId, a);
    }
    for (auto &t : threads)
    {
        t.join();
    }
    cout << (clock() - start) / CLOCKS_PER_SEC << endl;
    // for (int i = 0; i <= 100; i++)
    //     cout << a[i] << endl;
}

int main()
{
    int num = 10000000;
    int threadNum = 16;
    // double start;
    // start = clock();
    atomicWrite(num, threadNum);
    // cout << (clock() - start) / CLOCKS_PER_SEC << endl;
    // start = clock();
    directlyWrite(num, threadNum);
    // cout << (clock() - start) / CLOCKS_PER_SEC << endl;
}