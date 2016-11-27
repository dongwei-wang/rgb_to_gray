#include <iostream>
#include <cstdio>
#include <vector>
#include <string>
#include <dirent.h>
#include <iomanip>
#include <opencv2/opencv.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>

#define BLOCK_SIZE 1024
#define MAX_DIR_LEN 1024
#define BYTES_PER_PIXEL 3
#define MAX_PIXEL_CNT 1000000000
#define MAX_BYTES_CNT (BYTES_PER_PIXEL*MAX_PIXEL_CNT)
#define STREAMS_CNT 4
