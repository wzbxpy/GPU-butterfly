# make clean
cd /home/wzb/bc/GPU-butterfly/DynamicBatch
make -j

./butterfly.bin /home/wzb/bc/dataset/twitter/ Partition 100 edge-centric 1073741824 1 1 CPU
./butterfly.bin /home/wzb/bc/dataset/filcker/ Partition 100 edge-centric 1073741824 1 1 CPU
./butterfly.bin /home/wzb/bc/dataset/livejournal/ Partition 100 edge-centric 1073741824 1 1 CPU



./butterfly.bin /home/wzb/bc/dataset/twitter/ Partition 100 wedge-centric 1073741824 1 1 EMRC
./butterfly.bin /home/wzb/bc/dataset/filcker/ Partition 100 wedge-centric 1073741824 1 1 EMRC
./butterfly.bin /home/wzb/bc/dataset/livejournal/ Partition 100 wedge-centric 1073741824 1 1 EMRC
