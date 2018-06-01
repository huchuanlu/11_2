%  SLICSuperpixelSegmentation 
% <filename> <spatial_proximity_weight> <number_of_superpixels> <path_to_save_results>
%

clc;
clear;
image_name = '14037.bmp';
I = imread(image_name);
save_path = 'E:\MATLAB\R2009a\work\USEFUL_TOOL\Superpixel\SLIC\SLIC_Windows_commandline\';
weight = 20;
num_superpixel = 200;
my_cmd = ['SLICSuperpixelSegmentation.exe '...
     image_name ' ' num2str(weight) ' '  num2str(num_superpixel) ' ' save_path ];
dos(my_cmd);
label_sp = ReadDAT([size(I,1),size(I,2)],[image_name(1:end-4),'.dat']);
figure;imshow(segImage(I,label_sp));

