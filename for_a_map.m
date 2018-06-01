function for_a_map(input_im, corner_im, imName, superpixel_path)
  
  [row,col] = size(corner_im);
  [y,x] = ind2sub([row,col],find(corner_im == 1));%y��ʾ������x��ʾ����
  dt = DelaunayTri(x,y);
  if(~size(dt,1))
      return;
  end
  [k,av] = convexHull(dt);%�����Ȧ�ĵ����ڵ�λ��
%   plot(x(k),y(k));
  sulabel_im = ReadDAT(size(corner_im),[superpixel_path imName(1:end - 4) '.dat']);
  %%�õ�Ȧ�ڵ������
 BW = roipoly(corner_im,x(k),y(k));
 pixel = regionprops(BW,'all');
% pixel.PixelList��һ�����У��ڶ�������
 ind = pixel.PixelIdxList;%hull�ڵ�����λ��ind λ��Ӧ�ǣ�����-1��*���� +����
 out_ind = setdiff(1:row*col,ind);
 sal_super = priormap(input_im, ind, sulabel_im);
%%  ����1������ͨ���Ķ����Էֱ����ֱ��ͼ���compute iner and outer histogram
mat_im = [reshape(input_im(:,:,1),1,row*col);reshape(input_im(:,:,1),1,row*col);reshape(input_im(:,:,1),1,row*col)];
maxValO = max(mat_im(:,ind),[],2);
minVal0 = min(mat_im(:,ind),[],2);
maxValB = max(mat_im(:,out_ind),[],2);
minValB = min(mat_im(:,out_ind),[],2);
numBin=[60,60,60]; % Number of bins in histogram (if 2D histogram are used, numBin=[numBin1, numBin2];)
smoothFactor=[5,6,6]; % Smoothing factor
smoothingKernel=cell(1,3);

PrH1 = 1;%numel(ind)/(row*col)
PrH0 = 1;
out_PrH1 =1;
out_PrH0 = 1;

for i = 1:3
    cur_im = input_im(:,:,i);
    dataMat = cur_im(ind);
    [innerHist,innerBin] = ComputeHistogram_(dataMat,numBin(i),minVal0(i),maxValO(i));
    smoothingKernel{i}=getSmoothKernel_(smoothFactor(i));
    innerHist=filterDistribution_(smoothingKernel{i},innerHist',numBin(i));
    
    dataMat = cur_im(out_ind);
    [outerHist,outerBin] = ComputeHistogram_(dataMat,numBin(i),minValB(i),maxValB(i));
    smoothingKernel{i}=getSmoothKernel_(smoothFactor(i));
    outerHist=filterDistribution_(smoothingKernel{i},outerHist',numBin(i));
    
    PrO_H1 = innerHist(innerBin);% inner ����ÿ��Ԫ���ڿ���ֱ��ͼռ�ı���
    PrO_H0 = outerHist(innerBin);% inner ����ÿ��Ԫ���ڿ���ֱ��ͼռ�ı���
    PrH1=PrH1.*PrO_H1;%������ͨ���Ĵ����������
    PrH0=PrH0.*PrO_H0;%����������������һ��ͨ�� ��F(x) 
    
    
    PrB_H1 = innerHist(outerBin);% inner ����ÿ��Ԫ���ڿ���ֱ��ͼռ�ı���
    PrB_H0 = outerHist(outerBin);% inner ����ÿ��Ԫ���ڿ���ֱ��ͼռ�ı���
    out_PrH1=out_PrH1.*PrB_H1;%������ͨ���Ĵ����������
    out_PrH0=out_PrH0.*PrB_H0;%����������������һ��ͨ�� ��F(x)    
end

sal_o_super = sal_super(ind);
sal_b_super = sal_super(out_ind');
Pr_0=(PrH1.*sal_o_super)./(PrH1.*sal_o_super+PrH0.*(1 - sal_o_super));%so called saliency ���ڵ�saliency
Pr_B=(out_PrH1.*sal_b_super)./(out_PrH1.*sal_b_super+out_PrH0.*(1-sal_b_super));%so called saliency �����saliency
sal_hull = zeros(row,col);
sal_hull(ind) = Pr_0;
sal_hull(out_ind) = Pr_B;
sal_hull = (sal_hull - min(sal_hull(:)))/(max(sal_hull(:)) - min(sal_hull(:)));
imshow(sal_hull);title('saliency map');

% imwrite(sal_hull,['C:\Users\linda\Desktop\final\' imName]);


function [intHist,binInd] = ComputerColorHist(dataMat,color_bin)
%dataMat: innerIm: inner ind image
%         outerIm: outer ind image
%intHist: the output histgram for the input im 
%binInd : bin of each number of the input im
% size = size(dataMat,2);
numBin = color_bin^3;
dataMat_max = max(dataMat(:));
dataMat_min = min(dataMat(:));
dataMat = (dataMat - dataMat_min)/(dataMat_max - dataMat_min);% ��һ��
binInd = floor(dataMat(1,:) * color_bin * color_bin + dataMat(2,:) * color_bin + dataMat(3,:)) + 1;% ind1-4096
intHist=zeros(numBin,1);% 
for i = 1:length(dataMat)
    intHist(binInd(i))=intHist(binInd(i))+1;
end










function [intHist,binInd]=ComputeHistogram_(dataMat,numBin,minVal,maxVal)
% currently only 1 histograms
% dataMat:L orA orB with inner or outer index

%output:
%  intHist: 
%  binInd :��60�����bin

%binInd=ones(length(dataMat));% ����һ��ͼ���С��ȫ1����
binInd=max( min(ceil(numBin*(double(dataMat-minVal)/(maxVal-minVal))),numBin),1);% ������ֵ ת����[1 - 60]֮�䣬��С��ԭͼ��ͬ
intHist=zeros(numBin,1);
for i = 1:length(dataMat)
    intHist(binInd(i))=intHist(binInd(i))+1;
end
%% Get smoothing filter
function [smKer]=getSmoothKernel_(sigma)

if sigma==0
    smKer=1;
    return;
end

dim=length(sigma); % row, column, third dimension
sz=max(ceil(sigma*2),1);
sigma=2*sigma.^2;

if dim==1
    d1=-sz(1):sz(1);
    
    smKer=exp(-((d1.^2)/sigma));
    
elseif dim==2
    [d2,d1]=meshgrid(-sz(2):sz(2),-sz(1):sz(1));
    
    smKer=exp(-((d1.^2)/sigma(1)+(d2.^2)/sigma(2)));
    
elseif dim==3
    [d2,d1,d3]=meshgrid(-sz(2):sz(2),-sz(1):sz(1),-sz(3):sz(3));
    
    smKer=exp(-((d1.^2)/sigma(1)+(d2.^2)/sigma(2)+(d3.^2)/sigma(3)));
    
else
    error('Not implemented');
end

smKer=smKer/sum(smKer(:));





%% Smooth distribution
function dist=filterDistribution_(filterKernel,dist,numBin)

if numel(filterKernel)==1
    dist=dist(:)/sum(dist(:));
    return;
end

numDim=length(numBin);

if numDim==1
    %smoothDist=conv(dist,filterKernel,'same');
    
    lenDist=length(dist);
    hlenKernel=(length(filterKernel)-1)/2;

    dist=[dist(1)*ones(1,hlenKernel),dist,dist(end)*ones(1,hlenKernel)];
    dist=conv(dist,filterKernel);
    lenSmoothDist=length(dist);
    offset=(lenSmoothDist-lenDist)/2;
    dist=dist((offset+1):(lenSmoothDist-offset));
    
elseif numDim==2
    dist=reshape(dist,numBin);
    
    dist=conv2(filterKernel,filterKernel,dist,'same');
    
else
    dist=reshape(dist,numBin);
    
    for i=1:numDim
        fker=ones(1,numDim);
        fker(i)=length(filterKernel);
        fker=zeros(fker);
        fker(:)=filterKernel(:);
        
        dist=convn(dist,fker,'same');
        
    end
    
end

dist=dist(:)/sum(dist(:));
    





 