cd /home/wzb/bc/GPU-butterfly/DynamicBatch/
# make clean
make -j
# rm -rf /data/dataset/dataset/twitter/partition*
# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /data/dataset/dataset/twitter/ CPU radix edge-centric 25000000 56

# rm -rf /data/dataset/dataset/twitter/partition*
# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /data/dataset/dataset/twitter/ GPU radix edge-centric 25000000 108

# rm -rf /data/dataset/dataset/twitter/partition*
# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /data/dataset/dataset/twitter/ CPU range edge-centric 25000000 56

# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /data/web-graph/ GPU 100 edge-centric 39073741824 108
# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/bi-uk/ GPU 100 edge-centric 39073741824 108
/home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /data/dataset/dataset/livejournal/ GPU 100 edge-centric 1200000000 108
# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /data/dataset/dataset/livejournal/ GPU 100 edge-centric 1200000000 108
/home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /data/dataset/dataset/livejournal/ CPU 100 edge-centric 12000000000 56

# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/twitter/ sharedHashtable 100 edge-centric 1073741824 56
# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/filcker/ sharedHashtable 100 edge-centric 1073741824 56

# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/GPU-butterfly/preprocess/testdata/ CPU 100 edge-centric 1073741824 1 1
# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/twitter/ CPU 100 edge-centric 1073741824 1 1

# sudo cgexec -g memory:test /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/twitter/ CPU 100 edge-centric 25000000 1 1
# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/twitter/ EMRC 100 wedge-centric 1073741824 1 1
# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/livejournal/ EMRC 100 wedge-centric 1073741824 1 1

# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/twitter/ CPU 100 edge-centric 19173961 1
# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/filcker/ CPU 100 edge-centric 19173961 1
# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/bi-twitter/ CPU 100 edge-centric 507374182400 112

# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/delicious/ CPU 100 edge-centric 4294967296 1 1



# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/orkut/ GPU 100 edge-centric 40737418240 108
# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/orkut/ GPU 100 edge-centric 40737418240 216
# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/orkut/ GPU 100 edge-centric 40737418240 500

# make clean
# ./butterfly.bin /home/wzb/bc/dataset/twitter/ CPU 100 edge-centric 10000000000 1
# ./butterfly.bin /home/wzb/bc/dataset/livejournal/ CPU 100 edge-centric 10000000000 1
# ./butterfly.bin /home/wzb/bc/dataset/orkut/ CPU 100 edge-centric 10000000000 1
# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/bi-uk/ CPU 100 edge-centric 507374182400 56
# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/kron16-32768/ CPU 100 wedge-centric 1073741824 56 30 
# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/kron18-8192/ CPU 100 wedge-centric 1073741824 56 10 
# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/kron20-2048/ CPU 100 wedge-centric 1073741824 56 5 

# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/kron16-32768/ CPU 100 wedge-centric 1073741824 56 30 
# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/kron16-32768/ CPU 100 wedge-centric 1073741824 224 30 


# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/bi-sk/ CPU 100 edge-centric 507374182400 1 
# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/twitter/ GPU 100 edge-centric 507374182400 108 
# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/twitter/ GPU 100 edge-centric 507374182400 216 

# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/bi-uk/ GPU 100 edge-centric 40737418240 64 
# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/bi-uk/ GPU 100 edge-centric 40737418240 108 

# ncu -o profile1 -f /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/orkut/ GPU 100 edge-centric 507374182400 108 
# ncu -o profile2 -f /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/orkut/ GPU 100 edge-centric 507374182400 216 


# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/bi-uk/ CPU 100 edge-centric 507374182400 56
# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/livejournal/ CPU 100 edge-centric 507374182400 112 
# ./butterfly.bin /home/wzb/bc/dataset/livejournal/ CPU 100 edge-centric 10000000000 1 


# ./butterfly.bin /home/wzb/bc/dataset/kron14-2000/ Partition 100 wedge-centric 100000000 108 1
# ./butterfly.bin /home/wzb/bc/dataset/kron14-2000/ Partition 100 edge-centric 100000000 216 1


# ./butterfly.bin /home/wzb/bc/dataset/kron16-10000/ Partition 100 wedge-centric 1000000000 216 10
# ./butterfly.bin /home/wzb/bc/dataset/kron16-10000/ Partition 100 wedge-centric 1000000000 216 1
# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/trackers/ GPU 100 edge-centric 40737418240 216 

# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/orkut/ GPU 100 edge-centric 40737418240 216 
# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/orkut/ GPU 100 edge-centric 40737418240 128 
# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/orkut/ GPU 100 edge-centric 40737418240 108 
# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/orkut/ GPU 100 edge-centric 40737418240 64 

# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/kron16-32768/ GPU 100 edge-centric 1073741824 216 
# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/kron16-32768/ GPU 100 edge-centric 1073741824 128 
# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/kron16-32768/ GPU 100 edge-centric 1073741824 108 
# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/kron16-32768/ GPU 100 edge-centric 1073741824 64 

# /home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /home/wzb/bc/dataset/bi-uk/ GPU 100 edge-centric 40737418240 216 


# ./butterfly.bin /home/wzb/bc/dataset/kron16-32768/ Partition 100 wedge-centric 1073741824 216 30
# ./butterfly.bin /home/wzb/bc/dataset/kron18-8192/ Partition 100 wedge-centric 1073741824 216 10
# ./butterfly.bin /home/wzb/bc/dataset/kron20-2048/ Partition 100 wedge-centric 1073741824 216 5
# ./butterfly.bin /home/wzb/bc/dataset/kron16-32768/ Partition 100 edge-centric 1073741824 216 1
# ./butterfly.bin /home/wzb/bc/dataset/kron18-8192/ Partition 100 edge-centric 1073741824 216 1
# ./butterfly.bin /home/wzb/bc/dataset/kron20-2048/ Partition 100 edge-centric 1073741824 216 1



# make test
#/root/GPU-butterfly/GPU-code/butterfly.bin ../../dataset/bipartite/twitter/ 0 
# ./butterfly.bin ../dataset/bipartite/wiki-it/ 0
# ./butterfly.bin ../../dataset/bipartite/bi-uk-2006-05/ 0
# ./butterfly.bin ../../dataset/bipartite/wiki-en/ 0
# ./butterfly.bin ../../dataset/bipartite/delicious/ 0

# /home/ubuntu/hypergraph/GPU-butterfly/GPU-code/butterfly.bin /home/ubuntu/hypergraph/dataset/bipartite/wiki-fr 0
# /home/ubuntu/hypergraph/GPU-butterfly/GPU-code/butterfly.bin /home/ubuntu/hypergraph/dataset/bipartite/bi-uk-2006-05 0
# /home/ubuntu/hypergraph/GPU-butterfly/GPU-code/butterfly.bin /home/ubuntu/hypergraph/dataset/bipartite/trackers 0
# /home/ubuntu/hypergraph/GPU-butterfly/GPU-code/butterfly.bin /home/ubuntu/hypergraph/dataset/bipartite/test 0
# /home/ubuntu/hypergraph/GPU-butterfly/GPU-code/butterfly.bin /home/ubuntu/hypergraph/dataset/bipartite/delicious-ut 0
# /home/ubuntu/hypergraph/GPU-butterfly/GPU-code/butterfly.bin /home/ubuntu/hypergraph/dataset/bipartite/bi-twitter 0
# /home/ubuntu/hypergraph/GPU-butterfly/GPU-code/butterfly.bin /home/ubuntu/hypergraph/dataset/bipartite/trec 0
# /home/ubuntu/hypergraph/GPU-butterfly/GPU-code/butterfly.bin /home/ubuntu/hypergraph/dataset/bipartite/reuters 0
# /home/ubuntu/hypergraph/GPU-butterfly/GPU-code/butterfly.bin /home/ubuntu/hypergraph/dataset/bipartite/marvel 0
# /home/ubuntu/hypergraph/GPU-butterfly/GPU-code/butterfly.bin /home/ubuntu/hypergraph/dataset/bipartite/condmat 0
# /home/ubuntu/hypergraph/GPU-butterfly/GPU-code/butterfly.bin /home/ubuntu/hypergraph/dataset/bipartite/delicious 0
# /home/ubuntu/hypergraph/GPU-butterfly/GPU-code/butterfly.bin /home/ubuntu/hypergraph/dataset/bipartite/edit-fr 0
# /home/ubuntu/hypergraph/GPU-butterfly/GPU-code/butterfly.bin /home/ubuntu/hypergraph/dataset/bipartite/d-label 0
# /home/ubuntu/hypergraph/GPU-butterfly/GPU-code/butterfly.bin /home/ubuntu/hypergraph/dataset/bipartite/d-style 0
# /home/ubuntu/hypergraph/GPU-butterfly/GPU-code/butterfly.bin /home/ubuntu/hypergraph/dataset/bipartite/bi-sk-2005 0
# /home/ubuntu/hypergraph/GPU-butterfly/GPU-code/butterfly.bin /home/ubuntu/hypergraph/dataset/bipartite/flicker 0
# /home/ubuntu/hypergraph/GPU-butterfly/GPU-code/butterfly.bin /home/ubuntu/hypergraph/dataset/bipartite/orkut 0
# /home/ubuntu/hypergraph/GPU-butterfly/GPU-code/butterfly.bin /home/ubuntu/hypergraph/dataset/bipartite/amazon 0
# /home/ubuntu/hypergraph/GPU-butterfly/GPU-code/butterfly.bin /home/ubuntu/hypergraph/dataset/bipartite/bi-web-baidu 0
# /home/ubuntu/hypergraph/GPU-butterfly/GPU-code/butterfly.bin /home/ubuntu/hypergraph/dataset/bipartite/wiki-it 0
# /home/ubuntu/hypergraph/GPU-butterfly/GPU-code/butterfly.bin /home/ubuntu/hypergraph/dataset/bipartite/livejournal/sorted 1
# /home/ubuntu/hypergraph/GPU-butterfly/GPU-code/butterfly.bin /home/ubuntu/hypergraph/dataset/bipartite/livejournal/ 0

# /home/ubuntu/hypergraph/GPU-butterfly/GPU-code/butterfly.bin /home/ubuntu/hypergraph/dataset/bipartite/wiki-en-cat 0
# /home/ubuntu/hypergraph/GPU-butterfly/GPU-code/butterfly.bin /home/ubuntu/hypergraph/dataset/bipartite/dblp 0
# /home/ubuntu/hypergraph/GPU-butterfly/GPU-code/butterfly.bin /home/ubuntu/hypergraph/dataset/bipartite/ml 0
# /home/ubuntu/hypergraph/GPU-butterfly/GPU-code/butterfly.bin /home/ubuntu/hypergraph/dataset/bipartite/dbpedia 0
# /home/ubuntu/hypergraph/GPU-butterfly/GPU-code/butterfly.bin /home/ubuntu/hypergraph/dataset/bipartite/twitter 0
# /home/ubuntu/hypergraph/GPU-butterfly/GPU-code/butterfly.bin /home/ubuntu/hypergraph/dataset/bipartite/wiki-en 0
# /home/ubuntu/hypergraph/GPU-butterfly/GPU-code/butterfly.bin /home/ubuntu/hypergraph/dataset/bipartite/github 0
