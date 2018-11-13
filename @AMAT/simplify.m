function mat = simplify(mat, method, param)
    % Default input arguments
    if nargin < 3, param = 3; end
    if nargin < 2, method = 'dilation'; end

    % Post-processing function
    switch method
        case 'dilation'
            SE = strel('disk', param);
            process = @(x) imdilate(x, SE);
        case 'iso-dilation'
            process = @(x) bwdist(x) <= param;
        case 'skeleton'
            process = @(x) bwmorph(x, 'skel', inf);
        case 'afmm-skeleton'
            process = @(x) skeleton(x) >= param;
        otherwise
            error(['Method not supported. Supported methods are:\n' ...
                'dilation, iso-dilation, skeleton, afmm-skeleton.'])
    end

    % Create a new object if there is an output
    if nargout > 0
        mat = clone(mat);
    end

    % The group labels are already sorted and first label is zero (background)
    numBranches = max(mat.branches(:));
    [numRows, numCols, numChannels] = size(mat.input);
    matbranches = zeros(numRows, numCols);
    matradius = zeros(numRows, numCols);
    for i = 1:numBranches
        % Old branch points, radii, and respective cover.
        branchOld = mat.branches == i;
        radiusOld = branchOld .* double(mat.radius);
        cover = mat.computeDepth(radiusOld)>0;
        % Apply post-processing and thinning to selected branch.
        % Crop the necessary region for more efficiency.
        % Dilation and iso-dilation are applied on the branch points, whereas
        % skeletonization is applied on the cover mask.
        if strcmp(method, 'dilation') || strcmp(method, 'iso-dilation')
            branchNew = bwmorph(process(branchOld), 'thin', inf);
        else
            branchNew = bwmorph(process(cover), 'thin', inf);
        end

        % Compute new radii as distance transform on reconstructed cover.
        radiusNew = bwdist(bwperim(cover)) .* double(branchNew);
        % Find closest radii in the subset of the acceptable scale values.
        valid = radiusNew > 0;
        [~, idx] = min(abs(bsxfun(@minus, radiusNew(valid), mat.scales)), [], 2);
        radiusNew(valid) = mat.scales(idx);
        % Assign values in global label and radius map.
        matbranches(valid) = i;
        matradius(valid) = radiusNew(valid);
    end
    assert(all(matbranches(matbranches > 0) & matradius(matbranches > 0)))
    assert(all(ismember(matradius(matradius > 0), mat.scales)))

    % Make sure there are no gaps among branch labels
    newLabels = unique(matbranches); newLabels(1) = []; % first group is zero
    for i = 1:numel(newLabels)
        matbranches(matbranches == newLabels(i)) = i;
    end

    % Find which pixels have been removed and which have been added
    oldpts = any(mat.axis, 3);
    newpts = matbranches > 0;
    removed = oldpts & ~newpts;
    added = newpts & ~oldpts;

    % Update depth
    % NOTE: there is a discrepancy between
    % mat2mask(double(newpts).*radius, mat.scales) and
    % mat.depth + depthAdded - depthRemoved. This is probably because when the
    % new radii are changed EVEN FOR THE POINTS THAT ARE NOT REMOVED.
    % depthAdded = mat2mask(radius.*double(added), mat.scales);
    % depthRemoved = mat2mask(mat.radius.*double(removed), mat.scales);
    mat.radius = matradius;
    mat.computeDepth();

    % Update MAT encodings
    [y, x] = find(newpts);
    r = matradius(newpts);
    numScales = numel(mat.scales);
    enc = reshape(permute(mat.encoding, [1 2 4 3]), [], numChannels);
    for i = 1:numel(r)
        r(i) = mat.scaleIdx(r(i)); % map scales to scale indexes
    end
    idx = sub2ind([numRows, numCols, numScales], y(:), x(:), r(:));
    newaxis = reshape(rgb2labNormalized(zeros(numRows, numCols, numChannels)), numRows * numCols, numChannels);
    newaxis(newpts, :) = enc(idx, :); % remember that encodings are in LAB!

    mat.axis = labNormalized2rgb(reshape(newaxis, numRows, numCols, numChannels));
    mat.branches = matbranches;
    mat.computeReconstruction();

end
