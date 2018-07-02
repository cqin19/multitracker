
function [trace_out, t_update_out] = sortROI_multitrack(trace_cen, blob_cen,...
                                    t_update, t_curr, spd_thresh)
%% sort ROIs in multitracking mode
% inputs
%   -> prev_cen:  all trace coords for previous frame of a single ROI
%   -> can_cen:   all blob coords assigned to ROI for current frame

trace_out = trace_cen;
t_update_out = t_update;

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

% exit early if there is nothing to sort
if isempty(tar_cen)
    return;
end

targets_assigned = false(size(tar_cen,1),1);
candidates_assigned = false(size(can_cen,1),1);

while any(~targets_assigned)
    % pairwise distance for each target to the candidates
    pw_dist = cellfun(@(c) sqrt((c(1)-can_cen(:,1)).^2 +...
                                (c(2)-can_cen(:,2)).^2),...
                                num2cell(tar_cen,2),'UniformOutput',false);

    % get the min distance for each target to closest candidate and return
    % the index of the closest candidate
    [min_dist,match_idx] = cellfun(@min,pw_dist);

    % find candidate indices that are assigned to more than one target
    has_dup = find(histc(match_idx,1:size(can_cen,1))>1);


    no_dup = ~ismember(match_idx,has_dup);
    can_idx = find(~candidates_assigned);
    tar_idx = find(~targets_assigned);

    switch sort_mode
        case 'blob_sort'
            trace_out(can_idx(match_idx(no_dup)),:) = tar_cen(no_dup,:);
            t_update_out(can_idx(match_idx(no_dup))) = t_curr;
        case 'trace_sort'
            trace_out(tar_idx(no_dup),:) = can_cen(match_idx(no_dup),:);
            t_update_out(tar_idx(no_dup)) = t_curr;
    end

    candidates_assigned(can_idx(match_idx(no_dup))) = true;

    remove_can = match_idx(no_dup);
    idx_shift = arrayfun(@(x) sum(remove_can<x), match_idx);
    match_idx = match_idx - idx_shift;
    can_cen(remove_can,:)=[];
    min_dist(no_dup)=[];
    match_idx(no_dup) = [];           
    tar_cen(no_dup,:) = [];
    targets_assigned(tar_idx(no_dup)) = true;

    % resolve duplicate assignments by finding nearest neighbor
    if ~isempty(has_dup)
        sub_idx = arrayfun(@(idx) find(match_idx==idx),...
                                unique(match_idx),'UniformOutput',false);
        [~,sub_match] = arrayfun(@(idx) min(min_dist(match_idx==idx)),...
                                unique(match_idx));
        best_match = cellfun(@(x,y) x(y), sub_idx, num2cell(sub_match));
        %tmp_match = match_idx+idx_shift(~no_dup);
        can_idx = find(~candidates_assigned);
        tar_idx = find(~targets_assigned);

        switch sort_mode
            case 'blob_sort'
                trace_out(can_idx(best_match),:) = tar_cen(best_match,:);
                t_update_out(can_idx(best_match)) = t_curr;
            case 'trace_sort'
                trace_out(tar_idx(best_match),:) = can_cen ...
                                                    (unique(match_idx),:);
                t_update_out(tar_idx(best_match)) = t_curr;
        end

        candidates_assigned(can_idx(best_match)) = true;

        %tar_cen(out_map(best_match),:) = trace_out(unique(match_idx),:);
        targets_assigned(tar_idx(best_match)) = true;
        can_cen(unique(match_idx),:) = [];
        tar_cen(best_match,:) = [];
    end

end

%% apply speed threshold to centroid tracking
% calculate distance and convert from pix to mm
d = sqrt((trace_out(:,1)-trace_cen(:,1)).^2 + ...
         (trace_out(:,2)-trace_cen(:,2)).^2);
d = d .* 1;

% time elapsed since each centroid was last updated
dt = t_curr - t_update;

% calculate speed and remove centroids over threshold
spd = d./dt;
above_spd = spd > spd_thresh;
trace_out(above_spd,:) = trace_cen(above_spd,:);
t_update_out(above_spd,:) = t_update(above_spd,:);


%{

% do while any targets are unassigned
while any(~is_assigned)
    
    % pairwise distance for each target to the candidates
    pw_dist = cellfun(@(c) sqrt((c(1)-can_cen(:,1)).^2 +...
                                (c(2)-can_cen(:,2)).^2),...
                                num2cell(tar_cen,2),'UniformOutput',false);
                            
    % get the min distance for each target to closest candidate and return
    % the index of the closest candidate
    [min_dist,match_idx] = cellfun(@min,pw_dist);

    % find candidate indices that are assigned to more than one target
    has_dup = find(histc(match_idx,1:size(can_cen,1))>1);

    switch sort_mode
        case 'trace_sort'
            
            % get elements non-duplicate members of match_idx
            no_dup = ~ismember(match_idx,has_dup);
            out_map = find(~is_assigned);
            
            % assign appropriate blobs to updated traces (different for
            % blob sort)
            trace_out(out_map(no_dup),:) = can_cen(match_idx(no_dup),:);
            
            % update remaining lists and indices
            remove_can = match_idx(no_dup);
            idx_shift = arrayfun(@(x) sum(remove_can<x), match_idx);
            match_idx = match_idx - idx_shift;
            can_cen(remove_can,:)=[];
            min_dist(no_dup)=[];
            match_idx(no_dup) = [];           
            tar_cen(no_dup,:) = [];
            is_assigned(out_map(no_dup)) = true;

        case 'blob_sort'
            
            

    end

    % resolve duplicate assignments by finding nearest neighbor
    if ~isempty(has_dup)
        sub_idx = arrayfun(@(idx) find(match_idx==idx),...
                                unique(match_idx),'UniformOutput',false);
        [~,sub_match] = arrayfun(@(idx) min(min_dist(match_idx==idx)),...
                                unique(match_idx));
        best_match = cellfun(@(x,y) x(y), sub_idx, num2cell(sub_match));
        out_map = find(~is_assigned);
        trace_out(out_map(best_match),:) = can_cen(unique(match_idx),:);
        is_assigned(out_map(best_match)) = true;
        can_cen(unique(match_idx),:) = [];
        tar_cen(best_match,:) = [];
    end
    
end    

%% apply speed threshold to centroid tracking
% calculate distance and convert from pix to mm
d = sqrt((trace_out(:,1)-trace_cen(:,1)).^2 + ...
        (trace_out(:,2)-trace_cen(:,2)).^2);
d = d .* 1;

% time elapsed since each centroid was last updated
dt = t_curr - t_update;

% calculate speed and remove centroids over threshold
spd = d./dt;
above_spd = spd > spd_thresh;
trace_out(above_spd,:) = trace_cen(above_spd,:);
%}


