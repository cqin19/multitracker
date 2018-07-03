function imHandle = circularMask(radius, imSize)
imHandle = false(imsize);
imshow(imHandle)
center = [randi(600,1) randi(600,1)];
viscircles(gca, center, radius, 'color', 'w')