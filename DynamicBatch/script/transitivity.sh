# mkdir /data/dataset/dataset/kron14-8/noTransitivity/
# cp /data/dataset/dataset/kron14-8/* /data/dataset/dataset/kron14-8/noTransitivity/
# mkdir /data/dataset/dataset/kron14-8/oneTransitivity/
# /home/wzb/bc/GPU-butterfly/DynamicBatch/expand-by-transitivity/expand.bin /data/dataset/dataset/kron14-8/ /data/dataset/dataset/kron14-8/oneTransitivity/
# mkdir /data/dataset/dataset/kron14-8/twoTransitivity/
# /home/wzb/bc/GPU-butterfly/DynamicBatch/expand-by-transitivity/expand.bin /data/dataset/dataset/kron14-8/oneTransitivity/ /data/dataset/dataset/kron14-8/twoTransitivity/

/home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /data/dataset/dataset/kron14-8/noTransitivity/ CPU 100 wedge-centric 132000 56 
/home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /data/dataset/dataset/kron14-8/noTransitivity/ CPU 100 edge-centric 132000 56

/home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /data/dataset/dataset/kron14-8/oneTransitivity/ CPU 100 wedge-centric 6078464 56 
/home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /data/dataset/dataset/kron14-8/oneTransitivity/ CPU 100 edge-centric 6078464 56

/home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /data/dataset/dataset/kron14-8/twoTransitivity/ CPU 100 wedge-centric 18302472 56 
/home/wzb/bc/GPU-butterfly/DynamicBatch/butterfly.bin /data/dataset/dataset/kron14-8/twoTransitivity/ CPU 100 edge-centric 18302472 56