# brief introduction
I do images pixels conversion from RGB to gray scales
All images are stored at src/ directory which I specifiec at program
It can process any size of images only if you have enough big hard drives
Just store the images into src/, this frame work will process them

I implemented a frame with CUDA programming model with one GPU device
I process the images one by one, it take few memory, so I do not check memory status

# run the program
To make sure the program could run, we should create three folders in project directory:

src/ : store the colored images

cpu_tar/ : store the grayscale images which are processed by CPU

gpu_tar/ : store the grayscale images which are processed by GPU

put the images into src/ directory

	make

	sh run

program will work


