exe=butterfly.bin
N=1
cc= "$(shell which g++)"
commflags= -pthread -O3 -W -Wall -Wno-unused-function -Wno-unused-parameter 
cuflags= --compiler-options -Wall --gpu-architecture=compute_80 --gpu-code=sm_80 -m64 -c  -O3  # --resource-usage 

.SILENT: cucc
.SILENT: cc
.SILENT: cuflags
.SILENT: %.o




objs	=   $(patsubst %.cpp,%.o, $(wildcard countingAlgorithm-CPU/*.cpp) $(wildcard *.cpp)) 


deps	= 	$(wildcard ./*.cuh) \
			$(wildcard ./*.hpp) \
			$(wildcard ./*.h) \
			$(wildcard countingAlgorithm-CPU/*.cuh) \
			$(wildcard countingAlgorithm-CPU/*.hpp) \
			$(wildcard countingAlgorithm-CPU/*.h) \
			# $(wildcard countingAlgorithm-GPU/*.cuh) \
			# $(wildcard countingAlgorithm-GPU/*.hpp) \
			# $(wildcard countingAlgorithm-GPU/*.h) 	

# foldobjs = 	$(patsubst %.cu,%.o,$(wildcard countingAlgorithm-GPU/*.cu)) 



# %.o:%.cu 
# 	$(cucc) -c $(cuflags) $<  -o $@ 

%.o:%.cpp 
	$(cc) -c  $(commflags) $< -o $@ 

$(exe):$(objs)
	$(cc) $(objs) $(commflags) -o $(exe)
# rm -rf *.o 
# ./butterfly.bin ../dataset/bipartite/wiki-it/ 0

clean:
	rm -rf *.o countingAlgorithm-GPU/*.o countingAlgorithm-CPU/*.o $(exe)

test:
	# ./butterfly.bin /home/wzb/bc/Graph500KroneckerGraphGenerator/test/ default
	# ./butterfly.bin /home/shbing/datasetsNew/datasets/bipartite/livejournal/sorted/ default
	# ./butterfly.bin /home/shbing/datasetsNew/datasets/bipartite/orkut/sorted/ default
	./butterfly.bin /home/wzb/bc/dataset/twitter/ Partition 100 edge-centric 1073741824 1 10
 