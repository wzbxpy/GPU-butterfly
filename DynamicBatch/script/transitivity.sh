mkdir /data/dataset/dataset/kron14-8/noTransitivity/
cp /data/dataset/dataset/kron14-8/* /data/dataset/dataset/kron14-8/noTransitivity/
mkdir /data/dataset/dataset/kron14-8/oneTransitivity/
/home/wzb/bc/GPU-butterfly/DynamicBatch/expand-by-transitivity/expand.bin /data/dataset/dataset/kron14-8/ /data/dataset/dataset/kron14-8/oneTransitivity/
mkdir /data/dataset/dataset/kron14-8/twoTransitivity/
/home/wzb/bc/GPU-butterfly/DynamicBatch/expand-by-transitivity/expand.bin /data/dataset/dataset/kron14-8/oneTransitivity/ /data/dataset/dataset/kron14-8/twoTransitivity/
