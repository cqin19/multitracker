
% function to read videos and test frame by frame
function vid = getvideofile
vid = VideoReader('tracking_sample.mov');

% load expmt file
load('/Users/garyqin/Downloads/expmt.parameters.track_thresh.mat');
ref = expmt.ref.im;
thresh = expmt.parameters.track_thresh;
ct = 0;
ih = imagesc(false(size(ref)));
hold on
ph = plot(0,0, 'ro');
th = text(0,0,'','Color',[1 1 0],'HorizontalAlignment','center');
hold off


% read video, get threshold image
while hasFrame(vid)
    frame = readFrame(vid);
    frame = frame(:,:,2);
    ct = ct+1;
    
    diffim = ref - frame;
    thresh_im = diffim > thresh;
    ih.CData = thresh_im;

% plot threshold image
    
    s = regionprops(thresh_im, 'centroid');
    centroids = cat(1, s.Centroid);
    ph.XData = centroids(:,1);
    ph.YData = centroids(:,2);
    
end
    
        hold on
    labelShifty = -20;
for k = 1:length(s)
    cent = s(k).Centroid;
    text(cent(1), cent(2)+labelShifty, num2str(k),'Color',[1 1 0],...
    'HorizontalAlignment','center');
end
        hold off
    