% sort 2 traces (minimum distance)
function trace_out = sortROI_multitrack(trace_cen, blob_cen)
%
% inputs:
%   -> prev_cen:        all trace coords for previous frame of a single ROI
%   -> can_cen:   all blob coords assigned to ROI for current frame

trace_out = trace_cen;
is_assigned = false(size(trace_cen,1),1);

% define sorting mode
if size(trace_cen,1) <= size(blob_cen,1)
    sort_mode = 'trace_sort';
else
    sort_mode = 'blob_sort';
end

switch sort_mode
    case 'trace_sort'
        tar_cen = trace_cen;
        can_cen = blob_cen;
        
    case 'blob_sort'
        tar_cen = blob_cen;
        can_cen = trace_cen;
        
end

pw_dist = cellfun(@(c) sqrt((c(1)-can_cen(:,1)).^2 +...
                              (c(2)-can_cen(:,2)).^2),...
                  num2cell(tar_cen,2),'UniformOutput',false);
[min_dist,match_idx] = cellfun(@min,pw_dist);

% if index for two traces is equal
if numel(unique(match_idx)) < numel(pw_dist)
    
    has_dup = find(histc(match_idx,1:size(can_cen,1))>1);
    switch sort_mode
        case 'trace_sort'
            no_dup = ~ismember(match_idx,has_dup);
            trace_out(no_dup,:) = can_cen(match_idx(no_dup),:);
            remove_can = match_idx(no_dup);
            idx_shift = arrayfun(@(x) sum(remove_can<x), match_idx);
            can_cen(remove_can,:)=[];
            min_dist(no_dup)=[];
            tar_cen(no_dup,:) = [];
            match_idx(no_dup) = [];
            is_assigned = is_assigned | no_dup;
            
        case 'blob_sort'
            
            
    end
    
    
    [~,new_match] = arrayfun(@(idx) min(min_dist(match_idx==idx)),...
                            unique(match_idx));
    
end