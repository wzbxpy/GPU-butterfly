# g++ AliSortByDegree.cpp -O3 -o AliSortByDegree
# ./AliSortByDegree /home/wzb/bc/GPU-butterfly/preprocess/testdata/

# g++ fromCSRtoEdgelist.cpp -O3 -o fromCSRtoEdgelist
# ./fromCSRtoEdgelist ../../dataset/livejournal/

# g++ SortByDegree.cpp -O3 -o sort 
# ./sort ~/bc/dataset/MANN-a81/MANN-a81.mtx 0
# ./sort /home/wzb/bc/Graph500KroneckerGraphGenerator/test/ 1

g++ SortByDegree-webGraph.cpp -O3 -o SortByDegree-webGraph
./SortByDegree-webGraph /data/web-graph/ clueweb12.edgelist 
/home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /data/web-graph/ CPU 100 edge-centric 128073741824 56


g++ SortByDegree-webGraph.cpp -O3 -o SortByDegree-webGraph
./SortByDegree-webGraph /data/web-graph/test/ 1.edgelist
/home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /data/web-graph/test/ CPU 100 edge-centric 128073741824 56

#previous result 1498561924700227898 91.589 1862.31 1393.09