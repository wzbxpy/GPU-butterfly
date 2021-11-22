exe=partition.bin
N=1
cucc= "$(shell which nvcc)"
cc= "$(shell which g++)"
commflags=-lcudart -L"$(shell dirname $(cucc))"/../lib64  -O3 -W -Wall -Wno-unused-function -Wno-unused-parameter

.SILENT: cucc
.SILENT: cc
.SILENT: cuflags
.SILENT: %.o


objs	= 	$(patsubst %.cpp,%.o,$(wildcard *.cpp)) 
			


deps	= 	$(wildcard ./*.h) \

# foldobjs = 	$(patsubst %.cu,%.o,$(wildcard countingAlgorithm/*.cu)) 



%.o:%.cpp 
	$(cc) -c  $(commflags) $< -o $@ 

$(exe):$(objs)
	$(cc) $(objs) $(commflags) -o $(exe)
# rm -rf *.o 
# ./butterfly.bin ../dataset/bipartite/wiki-it/ 0

clean:
	rm -rf *.o countingAlgorithm/*.o $(exe)

test:
	./partition.bin /home/lyx/datasets/bipartite/twitter/sorted/ 1 10
