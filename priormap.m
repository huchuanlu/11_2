function sal = priormap(input_im, ind, superlabel)
%% input_im  : l a b color image
% ind       : positions of pixels inside the hull
% superlabel: superpixel label
%%
lamda = 1; % the coefficient banlance the color and distance
theta = 1;
 R = input_im(:,:,1);
 G = input_im(:,:,2);
 B = input_im(:,:,3); % 3 color channels
 [row,col] = size(R);
 out_ind = setdiff(1:row*col,ind);
 out_mean = [mean(R(out_ind)),mean(G(out_ind)),mean(B(out_ind))];

%% check whether the super pixel is completely inside convext
%% 聚成两类，分别求其于背景的聚离从而在圈内得到前景点背景点
STATS = regionprops(superlabel, 'all');
sup_num = numel(STATS);
innersuper = [];
insup_mean = [];
for r = 1:sup_num %% check the superpixel not along the image sides
    indxy = STATS(r).PixelIdxList;
    if (numel(intersect(indxy,ind)) > 0.4 * numel(indxy))
        innersuper = [innersuper,r];
        insup_mean = [insup_mean;mean(R(indxy)),mean(G(indxy)), mean(B(indxy))];
    end   
end
[cluster,Centroid] = cvKmeans(insup_mean',2);
cluster = cluster';
Centroid = Centroid';
dis = sum((Centroid - repmat(out_mean,2,1)).*(Centroid - repmat(out_mean,2,1)),2);
if(dis(1) > dis(2))
    one_object = 1; %1类是前景
else
    one_object = 2; %否则2类是前景
end
objinnersup_ind = find(cluster == one_object);% 内部点中属于前景概率比较大的superpixel
inner_bksuper = innersuper(cluster ~= one_object);% 内部点中属于前景概率较小的superpixel,将在下面赋相对外面的大一些的theta作为权重
innersuper = innersuper(objinnersup_ind);
innersup_num  = numel(innersuper);
pos_mat(sup_num,2) = 0;
color_mat(sup_num,3) = 0;
for m = 1:sup_num
%     pos_mat(m,:) = STATS(m).Centroid;
    pixelind = STATS(m).PixelIdxList;
    indxy = STATS(m).PixelList;% indxy有两列 第一列是列数，第二列是行数
    pos_mat(m,:) = [mean(indxy(:,1)),mean(indxy(:,2))];
    color_mat(m,:) = [mean(R(pixelind)),mean(G(pixelind)),mean(B(pixelind))];
end   
%% compute color distance and spacial distance for sal归一化处理用最笨的循环写
 pos_mat = (pos_mat - min(pos_mat(:)))/(max(pos_mat(:)) - min(pos_mat(:)));
 color_mat = (color_mat - min(color_mat(:)))/(max(color_mat(:)) - min(color_mat(:)));
mat_temp(sup_num,innersup_num) = 0;% 108*18
vector_temp(sup_num) = 0;
for n = 1:innersup_num
    harris_sp_label = innersuper(n);
    harris_sp_color = color_mat(harris_sp_label,:);
    harris_sp_pos = pos_mat(harris_sp_label,:);    
    for q = 1:sup_num
        theta = 1;
        cur_sp_color = color_mat(q,:);
        cur_sp_pos = pos_mat(q,:);
        if(harris_sp_label == q)
            sal_temp = 0;
        else
            if (ismember(q,inner_bksuper))
                theta = 1;%加大凸包内认为是背景的部分，正面的负面的
            end
            d_color = sqrt(sum((harris_sp_color - cur_sp_color).^2 ));
            d_space = sqrt(sum((harris_sp_pos - cur_sp_pos).^2));
            %sal_temp = exp(-(d_color +lamda * d_space ));
             sal_temp = theta/(d_color + lamda * d_space);
        end
        vector_temp(q) = sal_temp;
    end
    mat_temp(:,n) = vector_temp;
end
for n = 1:innersup_num
    harris_sp_label = innersuper(n);
    mat_temp(harris_sp_label,harris_sp_label) = mean(mat_temp(harris_sp_label,:));
end
%% 对应到图像中的superpixel中
sal_vector = mean(mat_temp,2);
sal(row,col) = 0;
for m = 1:sup_num
    pixelind = STATS(m).PixelIdxList;
    sal(pixelind) = sal_vector(m);   
end 
sal = (sal - min(sal(:)))/(max(sal(:)) - min(sal(:)));