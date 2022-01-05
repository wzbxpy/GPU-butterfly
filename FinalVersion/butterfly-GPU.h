#ifndef BUTTERFLY_GPU_H
#define BUTTERFLY_GPU_H
#include "graph.h"

int BC_GPU(graph *bipartiteGraph, int numBlocks, bool isEdgeCentric);

#endif