exe=butterfly.bin
N=1
cucc= "$(shell which nvcc)"
cc= "$(shell which g++)"
commflags=-lcudart -L"$(shell dirname $(cucc))"/../lib64  -O3 -W -Wall -Wno-unused-function -Wno-unused-parameter
cuflags= --compiler-options -Wall --gpu-architecture=compute_70 --gpu-code=sm_70 -m64 -c -O3   # --resource-usage 

.SILENT: cucc
.SILENT: cc
.SILENT: cuflags
.SILENT: %.o


objs	= 	$(patsubst %.cu,%.o,$(wildcard countingAlgorithm/*.cu) $(wildcard *.cu)) \
			$(patsubst %.cpp,%.o,$(wildcard *.cpp)) 
			


deps	= 	$(wildcard ./*.cuh) \
			$(wildcard ./*.hpp) \
			$(wildcard ./*.h) \
			$(wildcard countingAlgorithm/*.cuh) \
			$(wildcard countingAlgorithm/*.hpp) \
			$(wildcard countingAlgorithm/*.h) 

# foldobjs = 	$(patsubst %.cu,%.o,$(wildcard countingAlgorithm/*.cu)) 



%.o:%.cu 
	$(cucc) -c $(cuflags) $<  -o $@ 

%.o:%.cpp 
	$(cc) -c  $(commflags) $< -o $@ 

$(exe):$(objs)
	$(cc) $(objs) $(commflags) -o $(exe)
# rm -rf *.o 
# ./butterfly.bin ../dataset/bipartite/wiki-it/ 0

clean:
	rm -rf *.o countingAlgorithm/*.o $(exe)

test:
	./butterfly.bin ../../dataset/bipartite/test1/ 1
