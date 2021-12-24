#ifndef UTIL_H
#define UTIL_H

#include <stdio.h>
static void HandleError(cudaError_t err,
                        const char *file,
                        int line)
{
  if (err != cudaSuccess)
  {
    printf("%s in %s at line %d\n",
           cudaGetErrorString(err),
           file, line);
    exit(EXIT_FAILURE);
  }
}
#define HRR(err) \
  (HandleError(err, __FILE__, __LINE__))

// #define SML_MID 32
// #define MID_LRG 1024

#endif
