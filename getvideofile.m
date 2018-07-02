
% function to read videos and test frame by frame
function vid = getvideofile
%% read videos & initialize variables
%{
vidPath = ['C:\Users\debivortlab\Documents\MATLAB\'...
                'autotracker_data\Gary\06-12-2018-12-48-03__'...
                'Basic_Tracking_multitrack_sample_1-48_'...
                'Day1_VideoData.avi.mp4'];
%}
vidPath = ['C:\Users\debivortlab\Documents\MATLAB\autotracker_data\'...
            'Gary\larval_plate_sample\300Fruc901_0.mj2'];
vid = VideoReader(vidPath);

% load expmt file
%{
load(['C:\Users\debivortlab\Documents\MATLAB\autotracker_data\Gary\'...
        '06-12-2018-12-48-03__Basic_Tracking_multitrack_'...
        'sample_1-48_Day1.mat']);
%}

% get reference image
%ref = expmt.ref.im;
num_frames = vid.NumberOfFrames;
sample_frames = randperm(num_frames,10);
ref_stack =  arrayfun(@(x) read(vid,x), ...
                        sample_frames, 'UniformOutput',false);
ref_stack = cat(3,ref_stack{:});
ref = median(ref_stack,3);

expmt.ROI.n = 1;
expmt.ROI.centers = [vid.Height/2 vid.Width/2];
expmt.ROI.corners = [1 1 vid.Width vid.Height];
expmt.parameters.track_thresh = 20;
expmt.parameters.mm_per_pix = 1;
expmt.parameters.area_min = 8;
expmt.parameters.area_max = 400;

traces_per_roi = 38;
ROI_cen = arrayfun(@(x) repmat(expmt.ROI.centers(x,:),traces_per_roi,1),...
                        1:expmt.ROI.n, 'UniformOutput',false)';

thresh = expmt.parameters.track_thresh;
spd_thresh = 500;

ct = 0;
% initialize graphics handles
ih = imagesc(ref);
colormap('gray');
hold on
init_cen = cat(1,ROI_cen{:});
ph = plot(init_cen(:,1),init_cen(:,2), 'ro');
th = text(init_cen(:,1),init_cen(:,2),...
        cellfun(@num2str,num2cell(1:length(init_cen)),...
        'UniformOutput',false),'Color',[1 0 1], ...
        'HorizontalAlignment','center');
text_shift = -15;
th_fps = text(size(ref,2)*0.1,size(ref,1)*0.1,'0',...
             'Color',[1 0 1],'HorizontalAlignment','center');
hold off

% set time variables
tic
t_elapsed = 0;
t_update = cell(expmt.ROI.n,1);
t_update(:) = {zeros(traces_per_roi,1)};
t_prev = toc;
pause(0.2);

%%
area_bounds = [expmt.parameters.area_min expmt.parameters.area_max];
[area_samples, cen_dist] = ...
    sampleAreaDist(vid,ref,area_bounds,thresh, 50);

%% tracking loop
% read video, get threshold image
while ct <= num_frames

    % update time-keeping
    ct = ct+1;
    t_curr = toc;
    t_elapsed = t_elapsed + t_curr - t_prev;
    t_prev = t_curr;

    frame = read(vid,ct);
    if size(frame,3)>1
        frame = frame(:,:,2);
    end
    diffim = frame-ref;
    thresh_im = diffim > thresh;
    ih.CData = frame;

    [merge_coords, merge_idx, min_dist] = ...
    cellfun(@(x) findmerge(x), ROI_cen, 'UniformOutput',false);
    % plot threshold image
    s = regionprops(thresh_im, 'Centroid','Area');

    % apply area threshold before assigning centroids
    above_min = [s.Area] .* (expmt.parameters.mm_per_pix^2) > ...
        expmt.parameters.area_min;
    below_max = [s.Area] .* (expmt.parameters.mm_per_pix^2) < ...
        expmt.parameters.area_max;
    s(~(above_min & below_max)) = [];

    centroids = cat(1, s.Centroid);

    candidate_ROI_cen = assignROI(centroids, expmt);

    [ROI_cen, t_update] = ...
        cellfun(@(x,y,z) sortROI_multitrack(x, y, z, t_curr, ...
                spd_thresh), ROI_cen, candidate_ROI_cen, t_update,...
                'UniformOutput',false);

    merge_dist = cat(1, min_dist{:});
    merge_dist = min(merge_dist);
    % perform erosion on threshold image
    if 0 < merge_dist && merge_dist <= 20
        erodel = strel('disk',ceil(20./merge_dist),0);
    else
        erodel = strel('disk',ceil(mean(area_samples)./125),0);
    end

    sub_coords = cellfun(@(x) getSubImage(x, thresh_im, 20, erodel), ...
        merge_coords,'UniformOutput',false);

    all_cen = cat(1,ROI_cen{:});

    % update centroid markers
    ph.XData = all_cen(:,1);
    ph.YData = all_cen(:,2);

    % update text markers
    arrayfun(@updateText,all_cen(:,1), all_cen(:,2) + text_shift, th);
    th_fps.String = num2str(1/(toc-t_curr),3);
    drawnow limitrate

end


function [merge_coords, merge_idx, min_dist] = findmerge(trace_cen)
%% detect and flag potential merging centroids
% flag when distance is too close
cen_dist = squareform(pdist(trace_cen));
is_merging = 0 < cen_dist & cen_dist <= 30;
min_dist = min(cen_dist(is_merging));

[c,r] = meshgrid(1:size(is_merging));
is_merging = is_merging & c<r;

if any(is_merging(:))
    [match_1,match_2] = find(is_merging);
    merge_coords = arrayfun(@(i,j) trace_cen([i,j],:), match_1, match_2, ...
                            'UniformOutput',false);
    merge_idx = num2cell([match_1,match_2], 2);
else
    merge_coords = {};
    merge_idx = {};
end

    
function updateText(x,y,text_handle)
%% update text handles   
text_handle.Position([1 2]) = [x y];

