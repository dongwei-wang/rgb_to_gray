# Author      : Dongwei Wang
# wdw828@gmail.com
# opencv + cuda makefile

BIN  		:= rgb_to_gray
CXXFLAGS	:= -std=c++11 -O3 -g
NVCCFLAGS 	:= -O3 -gencode arch=compute_50,code=sm_50

CUDA_INSTALL_PATH := /usr/local/cuda
LIBS 	= -L$(CUDA_INSTALL_PATH)/lib64 -lcuda -lcudart
LDFLAGS = `pkg-config --libs opencv`
CFLAGS 	= `pkg-config --cflags opencv`

CXX 	= g++

all: $(BIN)
$(BIN): main.o rgb_to_gray.o
	$(CXX) $(CXXFLAGS) -o $(BIN) main.o rgb_to_gray.o $(LDFLAGS) $(LIBS)

main.o: main.cpp
	$(CXX) $(CXXFLAGS) -c main.cpp $(CFLAGS)

rgb_to_gray.o: rgb_to_gray.cu
	nvcc $(NVCCFLAGS) -c rgb_to_gray.cu $(CFLAGS)

echo_install_path:
	echo $(CUDA_INSTALL_PATH)
clean:
	rm -f $(BIN) *.o tags

cleangrays:
	cd grays_cpu; rm -rf *.jpg; cd ..; cd grays_gpu; rm -rf *; cd ..; cd grays_multi_gpus; rm -rf *; cd ..;
