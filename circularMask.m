function imHandle = circularMask(radius, imSize)
bw = false(imSize);
bw_cen = randi(imSize.*imSize,1);
bw(bw_cen) = 1;
bw(bwdist(bw)<=radius) = true;
imHandle = bw;
imshow(imHandle)


