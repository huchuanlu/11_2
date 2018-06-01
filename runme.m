
clear all
clc
addpath('k_means');
sigma_g=1.5; % parameters for computing harris points
sigma_a=5;  % parameters for computing harris points
nPoints=30; % number of salient points 
thresh = 26; % for elimate the side point
%inpath = 'E:\My Documents\学习资料\研究\saliency\师姐代码\ICIP代码\image\*.jpg';
inpath = 'F:\zhangying\xieyulin\ICIP_xieyulin\image\*.jpg';
%outpath ='F:\zhangying\xieyulin\ICIP_xieyulin\image\*.jpg';
% inpath =   'E:\temp\*.jpg';
%superpixel_path = 'E:\My Documents\学习资料\研究\saliency\师姐代码\ICIP代码\dat\'; % for '.dat'文件
superpixel_path = 'F:\zhangying\xieyulin\ICIP_xieyulin\dat\'; % for '.dat'文件
dir_im = dir(inpath);
% for i =947:length(dir_im)
for i =1:length(dir_im)
imName = dir_im(i).name;%color harris在RGB空间做即可
% imName = '4_128_128805.jpg';
input_im=im2double(imread([inpath(1:end - 5) imName])); 
% input_im = RGB2Lab(input_im1);
Mboost = BoostMatrix(input_im);
boost_im= BoostImage(input_im,Mboost);
[EnIm]= ColorHarris(boost_im,sigma_g,sigma_a,0.04);
[x_max,y_max,corner_im2,num_max]=getmaxpoints(EnIm,nPoints);
corner_im2 = elimatepoint(corner_im2,thresh); % elimate the points closing to the boundary of images
output_im2=visualize_corners(input_im,corner_im2);
input_im = RGB2Lab(imread([inpath(1:end - 5) imName]));%ICIP都在LAB空间做
for_a_map(input_im, corner_im2, imName, superpixel_path);
%  convex_hull(input_im, corner_im2, imName);
% display(num2str(i));
% saveas(gcf,['F:\zhangying\xieyulin\ICIP_xieyulin\image\',num2str(i),'_sal','.jpg']);
end