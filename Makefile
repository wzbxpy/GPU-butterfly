exe=butterfly.bin
N=1
cucc= "$(shell which nvcc)"
cc= "$(shell which g++)"
commflags=-lcudart -L"$(shell dirname $(cucc))"/../lib64  -O3 -W -Wall -Wno-unused-function -Wno-unused-parameter
cuflags= --compiler-options -Wall --gpu-architecture=compute_70 --gpu-code=sm_70 -m64 -c -O3 -I/root/hypergraph/cub-1.8.0   # --resource-usage 

.SILENT: cucc
.SILENT: cc
.SILENT: cuflags
.SILENT: %.o


objs	= $(patsubst %.cu,%.o,$(wildcard *.cu)) \
	$(patsubst %.cpp,%.o,$(wildcard *.cpp))

deps	= $(wildcard ./*.cuh) \
	$(wildcard ./*.hpp) \
	$(wildcard ./*.h) \


%.o:%.cu $(deps)
	$(cucc) -c $(cuflags) $<  -o $@ 

%.o:%.cpp $(deps)
	$(cc) -c  $(commflags) $< -o $@ 

$(exe):$(objs)
	$(cc) $(objs) $(commflags) -o $(exe)
# rm -rf *.o 


clean:
	rm -rf *.o 
