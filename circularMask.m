function imHandle = circularMask(radius, imSize)
imHandle = false(imSize);
imshow(imHandle)
center = [randi(600,1) randi(600,1)];
imHandle = viscircles(gca, center, radius, 'color', 'w');