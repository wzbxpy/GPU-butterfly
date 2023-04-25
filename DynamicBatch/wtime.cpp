#include <sys/time.h>
#include <stdlib.h>
#include "wtime.h"
#include <unistd.h>
#include <iostream>
#include <string>
#include <cstdio>
#include <cstring>
using namespace std;

double wtime()
{
    double time[2];
    struct timeval time1;
    gettimeofday(&time1, NULL);

    time[0] = time1.tv_sec;
    time[1] = time1.tv_usec;

    return time[0] + time[1] * 1.0e-6;
}

double getDeltaTime(double &startTime)
{
    double deltaTime = wtime() - startTime;
    startTime = wtime();
    return deltaTime;
}

int parseLine(char *line)
{
    // This assumes that a digit will be found and the line ends in " Kb".
    int i = strlen(line);
    const char *p = line;
    while (*p < '0' || *p > '9')
        p++;
    line[i - 3] = '\0';
    i = atoi(p);
    return i;
}

typedef struct
{
    uint64_t virtualMem;
    uint64_t physicalMem;
    uint64_t swapMem;
} processMem_t;

void getProcessMemory()
{
    FILE *file = fopen("/proc/self/status", "r");
    char line[128];
    processMem_t processMem;

    while (fgets(line, 128, file) != NULL)
    {
        if (strncmp(line, "VmSize:", 7) == 0)
        {
            processMem.virtualMem = parseLine(line);
        }

        if (strncmp(line, "VmRSS:", 6) == 0)
        {
            processMem.physicalMem = parseLine(line);
        }
        if (strncmp(line, "VmSwap:", 7) == 0)
        {
            processMem.swapMem = parseLine(line);
        }
    }
    fclose(file);
    // cout << "mem: "
    //      << "phyiscal: " << processMem.physicalMem << " virtual: " << processMem.virtualMem << " swap: " << processMem.swapMem << endl;
}