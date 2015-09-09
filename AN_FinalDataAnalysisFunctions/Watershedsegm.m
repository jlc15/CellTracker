%% code to use watershead marker-based segmentation to separate the nucleus from cytoplasm
function [L,stats] = Watershedsegm(I,se)

% I2 = imread('SingleCellSignalingAN_t0000_f0019_z0003_w0001.tif');% gfp channel (gfp-smad4 cells)
% I = imread('SingleCellSignalingAN_t0000_f0019_z0003_w0000.tif');% nuc chan
nuc = I;
% nuc_o = nuc;
% preprocess
global userParam;
userParam.gaussRadius = 10;
userParam.gaussSigma = 3;
userParam.small_rad = 3;
userParam.presubNucBackground = 1;
userParam.backdiskrad = 300;

nuc = imopen(nuc,strel('disk',userParam.small_rad)); % remove small bright stuff
nuc = smoothImage(nuc,userParam.gaussRadius,userParam.gaussSigma); %smooth
nuc =presubBackground_self(nuc);
%  Normalize image
diskrad = 100;
low_thresh = 500;

nuc(nuc < low_thresh)=0;
norm = imdilate(nuc,strel('disk',diskrad));
normed_img = im2double(nuc)./im2double(norm);
normed_img(isnan(normed_img))=0;



% threshold and find objects
thresh = 0.04; arealo = 1000;

nthresh = normed_img > thresh;

cc =bwconncomp(nthresh);

stats = regionprops(cc,'Area','Centroid','PixelIdxList');

 badinds = [stats.Area] < arealo; 
 stats(badinds) = [];

xy = [stats.Centroid];
xx=xy(1:2:end);
yy=xy(2:2:end);

figure; imshow(nuc,[]); hold on;
plot(xx,yy,'r*');

 %-------AN
% create the image to input into the watershed segmentation process based
% on the segmentation done above

 Inew = zeros(1024,1024);
 for k=1:length(xx)
 Inew(int32(yy(k)),int32(xx(k))) = 1;
 end
 figure,imshow(Inew);
 se = strel('disk',se);
 Inew = imdilate(Inew,se);
 imshow(Inew);
 
 
%------------------
 % this is from the online waterhed marker based segmentation; no prior
 % segmentation is needed here
  
%  f = imerode(I,strel('disk',20));
%  f1 = imreconstruct(f,I);
%  f2 = imdilate(f1,strel('disk',20));
%  f3 = imreconstruct(imcomplement(f2), imcomplement(f1));
%  f3 = imcomplement(f3);
%  
% % imshow(f,[]);
%  
%  fgm = imregionalmax(f3);% f3 marking the foreground objects(fgm)
%   
%  figure,imshow(fgm);
 %later need to create bw1
%------------------------------------------
 fgm = imregionalmax(Inew);%
  figure,imshow(fgm);
  
h = fspecial('sobel');
Ix  = imfilter(double(normed_img),h,'replicate'); % f3 if the other algothithm is used
Iy  = imfilter(double(normed_img),h','replicate');
gradmag = sqrt(Ix.^2 + Iy.^2);% this is the image where the dark regions are objects to be segmented (?) doublecheck
figure, imshow(gradmag);

%now marking the background objects( in the normed_img the dark pixels belong to the background)
%bw = im2bw(normed_img, graythresh(normed_img));

%bw1 = im2bw(f3,graythresh(f3));%f3
%figure,imshow(bw1);
%-----------
D = bwdist(Inew);%bw1

imshow(D);
DL = watershed(D);
bgm =  DL == 0; %watershed ridge lines (background markers, bgm)
%calculate the watershed transform of the segmentation function
figure,imshow(bgm);
gradmag2 = imimposemin(gradmag,bgm|fgm);     % modify the image so that it only has ...
...regional minima at desired locations(here the reg. min need to occur only ...
...at foreground and background locations
L = watershed(gradmag2); % final watershed segmentation
%L == 0; % this is where object boundaries are located
Lrgb = label2rgb(L, 'jet', 'k', 'shuffle');
figure,imshow(I,[]);hold on
h = imshow(Lrgb);
h.AlphaData = 0.3;  % overlap the segmentation with the original image using transparency option of the image object 

% figure,imshow(I,[]);hold on
% I(imdilate(L == 0, ones(3, 3)) | bgm | fgm) = 255;% to se all, fgm, bgm and boundaried of the objects

%-------AN
