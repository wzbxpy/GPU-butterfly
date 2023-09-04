# IOBufs
This is the code for **I/O-Efficient Butterfly Counting at Scale**.


## Organization
The code of IOBufs is at DynamicBatch fold.

## Environment 
CUDA Toolkit 11.6;
g++ 7.5.0;

## Usage
compile the code
    `$ make -j`
run the code 
    `$ ./butterfly.bin /data/dataset/dataset/livejournal/ GPU 100 edge-centric 12000000000 108 -1 adaptiveRecy 32 blockForSmallWorkload`

Input parameter is 
1. input graph folder
2. platform: CPU or GPU
3. partition strategy: radix, random or range
4. variant: edge-centric or wedge-centric
5. memory size 
6. thread num (CPU)/ block num(GPU)
7. batch num (automatically generated when setting -1)
8. Hashtable recycle option for GPU: adaptiveRecy, scanHashtableRecy or scanWedgeRecy
9. subwarp size for block-level parallelism in GPU
10. benchmark warp and block for small workload when setting blockForSmallWorkload

<!-- ## Prerpocess
In Preprocessing step, use 

    $ cd Preprocess
    $ ./compile.sh 

compile the code and we will get three files: fromDirectToUndirece, preprocess and partition.
This corresponds to following three step:

1. **fromDirectToUndirect** transform the directed graph to undirected graph, delete the duplicate edges and self loops and remove orphan vertices. It take file name as input and will generate undirected graph `1.mmio`.
For example:

    `$ ./fromDirectToUndirect cit-Patents.txt`

The format of `cit-Patents.txt` should be edge list.

2. **preprocess** will do the orientation and reordering and generate the CSR format of graph. It will take `1.mmio` as input and generate two file `begin.bin` and `adjacent.bin`

3. **partition** use hash to partition the graph. To see detail of partition usage, you can read the `Dataset/Cit-Patents/partition.sh`

## Dataset
In folder `Dataset/Cit-Patents/` we give a example of download Cit-Patents graph and preprocessing it.
Run it by

    $ cd Dataset/Cit-Patents/
    $ ./get&preprocess.sh

For the large graph and input file only include edge list, we recommend use preprocess code in `Preprocess/speedupIO`.

For partition, run 

    $./partition.sh 2
    
There are one input arguments `n`, it represent the partition number, we will partition graph into `n*n` pieces -->

<!-- ## Compile and Run code
For small graph, we don't partition the graph. 
Compile the code:

    $ cd Without-graph-partition/
    $ make

Run the code:

    $ mpirun -n 1 ./trianglecounting.bin ../Dataset/Cit-Patents/ 1 1024 1024 1

The input arguments is 
1. input graph folder 
2. number of GPUs
3. number of thread per block 
4. number of block 
5. chuncksize

The output arguments is
1. graph folder 
2. vertex count
3. edge count
4. triangle counts
5. times
6. TEPS rate

For the large graph, partition is required.

Compile the code:

    $ cd With-graph-partition/
    $ make

Run the code:

    $ mpirun -n 8 ./trianglecounting.bin ../Dataset/Cit-Patents/ 8 1024 1024 1 2


The input arguments is 
1. input graph folder 
2. number of GPUs should be m
3. number of thread per block 
4. number of block 
5. chuncksize
6. partition number `n`

The output arguments is
1. graph folder 
4. triangle counts
5. min times
6. max times

## reference -->

