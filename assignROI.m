
function ROI_cen = assignROI(raw_cen, expmt)

% get user data from gui
udat = gui_handles.gui_fig.UserData;

% Define placeholder data variables equal to number ROIs
tempCenDat=NaN(size(trackDat.Centroid,1),2);

% Initialize temporary centroid variables
tempCenDat(1:size(raw_cen,1),:)=raw_cen;

% Find nearest Last Known Centroid for each current centroid
% Replicate temp centroid data into dimensions compatible with dot product
% with the last known centroid of each fly
tD=repmat(tempCenDat,1,1,size(trackDat.Centroid,1));
c=repmat(trackDat.Centroid,1,1,size(tempCenDat,1));
c=permute(c,[3 2 1]);

% Use dot product to calculate pairwise distance between all coordinates
g=sqrt(dot((c-tD),(tD-c),2));
g=abs(g);

% Returns minimum distance to each previous centroid and the indces (j)
% Of the temp centroid with that distance
[~,j]=min(g);

% Initialize empty placeholders for permutation and inclusion vectors
sorting_permutation=[];
update_centroid = false(size(trackDat.Centroid,1),1);

ROI_cen = cell(expmt.ROI.n, 1);
ROI_num = cellfun(@(x) subAssignROI(x,expmt.ROI.corners),...
     num2cell(raw_cen,2),'UniformOutput',false);

% assign ROIs to centroids
function ROI_num = subAssignROI(cen,b)

    % get the bounds for each ROI at
    % current x and y position
    xL = cen(1) > b(:,1);
    xR = cen(1) < b(:,3);
    yT = cen(2) > b(:,2);
    yB = cen(2) < b(:,4);
    % identify matching ROI, if any    

    in_bounds = xL & xR & yT & yB;
    ROI_num = find(in_bounds);   
    
