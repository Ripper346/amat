function mat = group(mat, marginFactor, colortol)
    if nargin < 2, marginFactor = 1; end
    if nargin < 3, colortol = 0.05; end

    % Compute individual radius maps and connected components
    numScales = numel(mat.scales);
    for r  = numScales:-1:1
        cc(r) = bwconncomp(mat.radius == mat.scales(r));
    end

    % Initialize mask and maxLabel
    [numRows, numCols, numChannels] = size(mat.input);
    mask = false(numRows, numCols); % proximity mask
    maxLabel = 1; % initialize maxLabel
    % Convert to Lab and reshape axis encodings for convenience
    if colortol
        mataxis = reshape(rgb2labNormalized(mat.axis), numRows * numCols, numChannels);
    end

    % For all scales
    for r = 1:numScales
        cc(r).labels = zeros(1, cc(r).NumObjects); % zero for non-examined ccs
        margin = ceil(marginFactor * r) + 1;
        % For all connected components at the same scale
        for i = 1:cc(r).NumObjects
            % Create proximity mask in rectangle around cc for efficiency
            mask(:) = false;
            mask(cc(r).PixelIdxList{i}) = true;
            idxcc = cc(r).PixelIdxList{i};
            [y, x] = ind2sub([numRows, numCols], idxcc);
            xmin = max(1, min(x) - margin);
            xmax = min(numCols, max(x) + margin);
            ymin = max(1, min(y) - margin);
            ymax = min(numRows, max(y) + margin);
            mask(ymin:ymax, xmin:xmax) = bwdist(mask(ymin:ymax, xmin:xmax)) <= margin;

            % The cc is assigned a new label, unless it has already been merged
            if cc(r).labels(i) == 0
                cc(r).labels(i) = maxLabel;
            end

            % Find groups at smaller scales that can potentially be merged
            mergedLabels = cc(r).labels(i);
            for rr = (r - 1):-1:max(1, r - 4)
                for j = 1:cc(rr).NumObjects
                    if ~any(mergedLabels == cc(rr).labels(j)) && merge(cc(rr).PixelIdxList{j})
                        mergedLabels = [mergedLabels, cc(rr).labels(j)];
                    end
                end
            end

            % Merge labels (use the smallest label as the common label)
            commonLabel = min(mergedLabels);
            for rr = 1:r
                cc(rr).labels(ismember(cc(rr).labels, mergedLabels)) = commonLabel;
            end

            % Merge ccs at the same scale
            for j = (i + 1):cc(r).NumObjects
                if merge(cc(r).PixelIdxList{j})
                    cc(r).labels(j) = cc(r).labels(i);
                end
            end

            % If the component has not been merged, increase maxLabel
            if cc(r).labels(i) == maxLabel
                maxLabel = maxLabel + 1;
            end
        end
    end

    % Construct label map
    matbranches = zeros(numRows, numCols);
    for r = 1:numScales
        for i = 1:cc(r).NumObjects
            matbranches(cc(r).PixelIdxList{i}) = cc(r).labels(i);
        end
    end

    % Adjust labels. We do not need to explicitly remove the zero labels
    % because cc.labels() does not include any zero (0) labels.
    oldLabels = unique(cat(2, cc(:).labels));
    newLabels = 1:numel(oldLabels);
    for i = 1:numel(oldLabels)
        matbranches(matbranches == oldLabels(i)) = newLabels(i);
    end
    mat.branches = matbranches;

    % Nested functions --------------------------------------------
    function res = merge(idx)
        res = isCloseSpace(idx);
        if colortol, res = res && isCloseColor(idx); end
    end

    function res = isCloseSpace(idx)
        res = any(mask(idx));
    end

    function res = isCloseColor(idx)
        res = norm( mean(mataxis(idxcc, :), 1)-...
            mean(mataxis(idx, :), 1) ) < colortol;
    end
end
