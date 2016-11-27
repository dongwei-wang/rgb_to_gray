#include "header.h"

static inline void _safe_cuda_call(cudaError err, const char* msg, const char* file_name, const int line_number){
	if(err!=cudaSuccess){
		fprintf(stderr,"%s\n\nFile: %s\n\nLine Number: %d\n\nReason: %s\n",msg,file_name,line_number,cudaGetErrorString(err));
		std::cin.get();
		exit(EXIT_FAILURE);
	}
}

#define SAFE_CALL(call,msg) _safe_cuda_call((call),(msg),__FILE__,__LINE__)

extern "C"
void convert_to_gray_cpu(unsigned char* input,int rows, int cols, int color_step, unsigned char* output, int gray_step);

extern "C"
void convert_to_gray_gpu(const cv::Mat& input, cv::Mat& output);

__global__ void rgb_to_gray_kernel(unsigned char* input, unsigned char* output, unsigned int pixel_cnt){
	int tid = blockDim.x * blockIdx.x + threadIdx.x;
	if( tid < pixel_cnt ){
		int color_idx = tid*BYTES_PER_PIXEL;
		int gray_idx = tid;
		unsigned char blue	= input[color_idx];
		unsigned char green	= input[color_idx + 1];
		unsigned char red	= input[color_idx + 2];
		float gray = red * 0.3f + green * 0.59f + blue * 0.11f;
		output[gray_idx] = static_cast<unsigned char>(gray);
	}
}

void convert_to_gray_cpu(unsigned char* input,int rows, int cols, int color_step, unsigned char* output, int gray_step){

	float milliseconds = 0;
	cudaEvent_t start, stop;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);
	cudaEventRecord(start);

	unsigned char blue;
	unsigned char green;
	unsigned char red;
	float gray;

	int color_idx = 0;
	int gray_idx = 0;
	for( int i=0; i<rows; i++ ){
		for(int j=0; j<cols; j++){
			color_idx = i*color_step + (3*j);
			gray_idx = i*gray_step + j;
			blue	= input[color_idx];
			green	= input[color_idx + 1];
			red		= input[color_idx + 2];
			gray = red * 0.3f + green * 0.59f + blue * 0.11f;
			output[gray_idx] = static_cast<unsigned char>(gray);
		}
	}
	cudaEventRecord(stop);
	cudaEventSynchronize(stop);
	cudaEventElapsedTime(&milliseconds, start, stop);
	std::cout<<"CPU time: "<<milliseconds<<" ms"<<std::endl;
}

void convert_to_gray_gpu(const cv::Mat& input, cv::Mat& output){
	const int colorBytes = input.step * input.rows;
	const int grayBytes = output.step * output.rows;
	unsigned char *d_input, *d_output;

	float milliseconds = 0;
	cudaEvent_t start, stop;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);
	// GPU processing......
	cudaEventRecord(start);

	//Allocate device memory
	SAFE_CALL(cudaMalloc(&d_input,colorBytes),"CUDA Malloc Failed");
	SAFE_CALL(cudaMalloc(&d_output,grayBytes),"CUDA Malloc Failed");

	//Copy data from OpenCV input image to device memory
	SAFE_CALL(cudaMemcpy(d_input,input.ptr(),colorBytes,cudaMemcpyHostToDevice),"CUDA Memcpy Host To Device Failed");

	//Specify a reasonable block size
	dim3 block(BLOCK_SIZE);

	//Calculate grid size to cover the whole image
	dim3 grid((input.cols * input.rows + BLOCK_SIZE -1 )/BLOCK_SIZE);

	rgb_to_gray_kernel<<<grid, block>>>(d_input, d_output, input.cols*input.rows);

	//Synchronize to check for any kernel launch errors
	SAFE_CALL(cudaDeviceSynchronize(),"Kernel Launch Failed");
	//Copy back data from destination device meory to OpenCV output image
	SAFE_CALL(cudaMemcpy(output.ptr(),d_output,grayBytes,cudaMemcpyDeviceToHost),"CUDA Memcpy Device To Host Failed");

	//Free the device memory
	SAFE_CALL(cudaFree(d_input),"CUDA Free Failed");
	SAFE_CALL(cudaFree(d_output),"CUDA Free Failed");

	cudaEventRecord(stop);
	cudaEventSynchronize(stop);
	cudaEventElapsedTime(&milliseconds, start, stop);
	std::cout<<"GPU time: "<<milliseconds<<" ms"<<std::endl;
}
