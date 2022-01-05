# g++ -std=c++14 -pthread  atomicCmp.cpp  -o atomiccmp
g++ -std=c++14 -fcilkplus  atomicCmp.cpp  -O3 -o atomiccmp
./atomiccmp
