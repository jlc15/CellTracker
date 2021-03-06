function maskN = localMaxPlusWatershed(im2)

global userParam;

mask = im2 + userParam.nucIntensityLoc;
im3 = imreconstruct(im2, mask);
regmx = mask - im3;
% If desired local max separated by saddles at least nucIntensityLoc below
% max then can further prune false max with following.  Can eliminate a
% lot of false + by global threshold and eliminate background regions.
regmx = (regmx >= userParam.nucIntensityLoc - 1);

% strel_nuc = strel('square', floor(1.414*userParam.minNucSep));
% regmx = imclose(regmx, strel_nuc );
%cc_struct = bwconncomp(regmx);
% most of time in following two calls which are about equally slow.
%stats = regionprops(cc_struct, 'PixelIdxList', 'Centroid');

maskN = imdilate(regmx,strel('disk',userParam.cellsize));
maskN(im2 < userParam.minIntensity) = 0;