#include <unistd.h>
#include "header.h"

extern "C"
void convert_to_gray_cpu(unsigned char* input,int rows, int cols, int color_step, unsigned char* output, int gray_step);

extern "C"
void convert_to_gray_gpu(const cv::Mat& input, cv::Mat& output);

void process_dir_inorder(std::string cur_dir );
//unsigned int get_pixels_dir(std::string src_dir);

int main(){
	// get current working directory
	char cwd[MAX_DIR_LEN];
	if(getcwd(cwd, sizeof(cwd))!=NULL)
		std::cout<<"Image source directory: "<<cwd<<std::endl<<std::endl;
	else
		std::cout<<"Get image source directory FAILED!!!"<<std::endl;

	std::string cur_dir(cwd);
	process_dir_inorder(cur_dir);
	return 0;
}

void process_dir_inorder(std::string cur_dir){
	// string to store the source directory
	std::string src_dir_str(cur_dir+"/src");
	std::string tar_dir_cpu_str(cur_dir+"/cpu_tar");
	std::string tar_dir_gpu_str(cur_dir+"/gpu_tar");

	// string to store and target the directory of source image entity
	std::string img_src_ent_str, img_tar_cpu_ent_str, img_tar_gpu_ent_str;

	// open the directory of source and enumarate the image files in the directory
	DIR *img_src = opendir(src_dir_str.c_str());
	// open the directory of target of cpu and store the processed image in the directory
	DIR *img_tar_cpu = opendir(tar_dir_cpu_str.c_str());
	// open the directory of target of gpu and store the processed image in the directory
	DIR *img_tar_gpu = opendir(tar_dir_gpu_str.c_str());

	// if source and target folder open failed
	if(img_src == NULL || img_tar_cpu == NULL || img_tar_gpu == NULL){
		std::cout<<"Can not to open the directory!!!"<<std::endl;
		return;
	}

	// each image entity in source directory
	dirent *img_ent;

	std::vector<int> compression_params;
	compression_params.push_back(CV_IMWRITE_PNG_COMPRESSION);
	compression_params.push_back(9);

	// enumerate every image file in current directory and process
	while((img_ent = readdir(img_src))){
		// if detect "." and ".." , we ignore them
		if(strcmp(img_ent->d_name, ".") == 0 || strcmp(img_ent->d_name, "..")==0)
			continue;
		else{
			// for real images
			img_src_ent_str = src_dir_str + "/" + img_ent->d_name;
			img_tar_cpu_ent_str = tar_dir_cpu_str + "/" + img_ent->d_name;
			img_tar_gpu_ent_str = tar_dir_gpu_str + "/" + img_ent->d_name;

			cv::Mat input = cv::imread(img_src_ent_str, CV_LOAD_IMAGE_COLOR);
			std::cout<<"Processing "<<img_ent->d_name<< std::endl;
			std::cout<<"Pixels count: "<<input.total()<<std::endl;
			if(input.empty()){
				std::cout<<"Image Not Found!"<<std::endl;
				return;
			}

			cv::Mat h_output(input.rows, input.cols, CV_8UC1);
			cv::Mat d_output(input.rows, input.cols, CV_8UC1);

			// CPU processing......
			convert_to_gray_cpu(input.ptr(), input.rows, input.cols, input.step, h_output.ptr(), h_output.step);

			// GPU processing......
			convert_to_gray_gpu(input,d_output);

			cv::imwrite(img_tar_cpu_ent_str, h_output, compression_params);
			cv::imwrite(img_tar_gpu_ent_str, d_output, compression_params);
			std::cout<<std::endl;

			// clear the string to refresh a new file in next loop
			img_src_ent_str.clear();
			img_tar_cpu_ent_str.clear();
			img_tar_gpu_ent_str.clear();
		}
	}
	std::cout<<"Images processing completed"<<std::endl;
}
