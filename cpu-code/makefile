exe=butterfly.bin
N=1
cc= "$(shell which g++)"
#commflags=-lcudart -L"$(shell dirname $(cucc))"/../lib64  -O3 -W -Wall -Wno-unused-function -Wno-unused-parameter

.SILENT: cc
.SILENT: %.o


objs	= $(patsubst %.cpp,%.o,$(wildcard *.cpp) $(wildcard ./BFC-VP++/*.cpp)) 
			


deps	= 	$(wildcard ./*.hpp) \
			$(wildcard ./*.h) 

# foldobjs = 	$(patsubst %.cu,%.o,$(wildcard countingAlgorithm/*.cu)) 


$(exe):$(objs)
	$(cc) -fcilkplus $(objs) -o $(exe) -ltbb -lrt 

%.o:%.cpp 
	$(cc) -c -fcilkplus -O3 $< -o $@  -lrt -ltbb


# rm -rf *.o 
# ./butterfly.bin ../dataset/bipartite/wiki-it/ 0

clean:
	rm -rf *.o countingAlgorithm/*.o $(exe)

test:
	./butterfly.bin /home/shbing/datasetsNew/datasets/bipartite/bi-uk-2006-05/sorted run -1 trackers 32

check:
	./butterfly.bin  ~/datasetsNew/datasets/bipartite/github/sorted check 0 -1