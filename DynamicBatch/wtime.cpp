#include <sys/time.h>
#include <stdlib.h>
#include "wtime.h"

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
