function sub_im = excBorderPix(area_samples, thresh_ims, shift)

abv_area  = area_samples > median(area_samples).*1.7;
abv_props = regionprops(thresh_ims,'Centroid', 'PixelList');
cen_idx = cat(1,abv_props.Centroid);
coord_idx = arrayfun(@(x) x.PixelList, abv_props,'UniformOutput', false);

im_bounds = zeros(1,4);
im_bounds = cellfun(@(i) [ceil(i - 20)...
                     ceil(i + 20)], num2cell(cen_idx,2), ...
                     'UniformOutput', false);
im = thresh_ims{1};
bounds_limit = [1 1 size(im,2) size(im,1)];
out_of_bounds = cellfun(@(x) [x(:,[1,2])<bounds_limit(1:2)...
                    x(:,[3,4])>bounds_limit(3:4)], ...
                    im_bounds, 'UniformOutput', false);
               
out_of_bounds = cat(1,out_of_bounds{:}); 
bounds_limit = repmat(bounds_limit,numel(im_bounds),1);
im_bounds = cat(1,im_bounds{:});
im_bounds(out_of_bounds) = bounds_limit(out_of_bounds);
sub_im = cellfun(@(x) im(x(2):x(4),x(1):x(3)), ...
    num2cell(im_bounds,2), 'UniformOutput', false);

sub_coords = cellfun(@(a,b) [a(:,1)-b(1) a(:,2)-b(2)], coord_idx, im_bounds, ...
                     'UniformOutput', false);

[row, col] = cellfun(@(x) find(x), sub_im, 'UniformOutput', false);

shift_coords = im_bounds(:,1) - coord_idx(:,1);

coord_idx = sub2ind(size(shift_coords), coord_idx(:,1), coord_idx(:,2));
sub_im(:,:) = 0;
sub_im(coord_idx) = true;