function setCover(mat)
    % -------------------------------------------------------------
    % Greedy approximation of the weighted set cover problem.
    % -------------------------------------------------------------
    % - Disk cost: cost incurred by selecting ena r-disk, centered at (i, j).
    % - numNewPixelsCovered: number of NEW pixels covered by a selected disk.
    % - Cost per pixel: diskCost / numNewPixelsCovered.
    % - Disk cost effective: adjusted normalized cost: diskCostPerPixel + scaleTerm
    % where scaleTerm is a term that favors selecting disks of larger
    % radii. Such a term is necessary, to resolve selection of disks in
    % the case where diskCost is zero for more than on radii.
    % NOTE: Even when using other types of shapes too (e.g.
    % squares), we still refer to them as "disks".
    %
    % TODO: is there a way to first sort scores and then pick the next one in
    % queue, to avoid min(diskCostEffective(:)) in each iteration?

    % Initializations
    [numRows, numCols, numChannels, numScales] = size(mat.encoding);
    zeroLabNormalized = rgb2labNormalized(zeros(numRows, numCols, numChannels));
    mat.input = reshape(mat.input, numRows * numCols, numChannels);
    mat.reconstruction = reshape(zeroLabNormalized, numRows * numCols, numChannels);
    mat.axis = zeroLabNormalized;
    mat.radius = zeros(numRows, numCols);
    mat.depth = zeros(numRows, numCols); % #disks points(x, y) is covered by
    mat.price = zeros(numRows, numCols); % error contributed by each point
    initializeCoveredMatrix(mat, numRows, numCols);
    calculateDiskCosts(mat, numRows, numCols);
    % Print remaining pixels to be covered in these points
    printBreakPoints = floor((4:-1:1) .* (numRows * numCols / 5));

    % GREEDY ALGORITHM STARTS HERE --------------------------------
    fprintf('Pixels remaining: ');
    [x, y] = meshgrid(1:numCols, 1:numRows);
    while ~all(mat.covered(:))
        % Get disk with min cost
        [minCost, idxMinCost] = min(mat.diskCostEffective(:));
        [yc, xc, rc] = ind2sub(size(mat.diskCostEffective), idxMinCost);

        if isinf(minCost)
            warning('Stopping: selected disk has infinite cost.');
            break;
        end

        areaCovered = getPointsCovered(mat, x, y, xc, yc, rc);
        newPixelsCovered = areaCovered & ~mat.covered;
        if ~any(newPixelsCovered(:))
            keyboard;
            warning('Stopping: selected disk covers zero (0) new pixels.');
            break;
        end

        % Update MAT
        mat.covered(newPixelsCovered) = true;
        mat.price(newPixelsCovered) = minCost / mat.numNewPixelsCovered(yc, xc, rc);
        mat.depth(areaCovered) = mat.depth(areaCovered) + 1;
        mat.axis(yc, xc, :) = mat.encoding(yc, xc, :, rc);
        mat.radius(yc, xc) = mat.scales(rc);
        updateCosts(mat, newPixelsCovered, xc, yc, numRows, numCols, numScales);

        % Visualize progress
        if mat.vistop
            mat.showImg(xc, yc, rc, numRows, numCols, numScales);
        end
        if ~isempty(printBreakPoints) && nnz(~mat.covered) < printBreakPoints(1)
            fprintf('%d...', printBreakPoints(1));
            printBreakPoints(1) = [];
        end
    end
    fprintf('\n');
    mat.input = reshape(mat.input, numRows, numCols, numChannels);
    mat.axis = labNormalized2rgb(mat.axis);
    mat.computeReconstruction();
end

function initializeCoveredMatrix(mat, numRows, numCols)
    mat.covered = false(numRows, numCols);
    % Flag border pixels that cannot be accessed by filters
    if strcmp(mat.shape, 'disk')
        r = mat.scales(1);
        mat.covered([1:r, end - r + 1:end], [1, end]) = true;
        mat.covered([1, end], [1:r, end - r + 1:end]) = true;
    end
end

function calculateDiskCosts(mat, numRows, numCols)
    % Compute how many pixels are covered by each r-disk.
    diskAreas = cellfun(@nnz, mat.filters);
    mat.diskCost = mat.cost;
    mat.numNewPixelsCovered = repmat(reshape(diskAreas, 1, 1, []), [numRows, numCols]);

    % Add scale-dependent cost term to favor the selection of larger disks.
    mat.diskCostPerPixel = mat.diskCost ./ mat.numNewPixelsCovered;
    mat.diskCostEffective = bsxfun(@plus, mat.diskCostPerPixel, ...
        reshape(mat.ws ./ mat.scales, 1, 1, []));
end

function area = getPointsCovered(mat, x, y, xc, yc, rc)
    switch mat.shape
        case 'disk'
            area = (x - xc) .^ 2 + (y - yc) .^ 2 <= mat.scales(rc) ^ 2;
        case 'square'
            area = abs(x - xc) <= mat.scales(rc) & abs(y - yc) <= mat.scales(rc);
        case 'mixed'
            error('Mix of disks and squares not supported yet');
        otherwise
            error('Shape is not supported');
    end
end

function updateCosts(mat, newPixelsCovered, xc, yc, numRows, numCols, numScales)
    % Update costs
    [yy, xx] = find(newPixelsCovered);
    xminCovered = min(xx);
    xmaxCovered = max(xx);
    yminCovered = min(yy);
    ymaxCovered = max(yy);
    newPixelsCovered = double(newPixelsCovered);
    for r = 1:numScales
        scale = mat.scales(r);
        x1 = max(xminCovered - scale, 1);
        y1 = max(yminCovered - scale, 1);
        x2 = min(xmaxCovered + scale, numCols);
        y2 = min(ymaxCovered + scale, numRows);
        % Find how many of the newPixelsCovered are covered by other disks.
        numPixelsSubtracted = ...
            conv2(newPixelsCovered(y1:y2, x1:x2), mat.filters{r}, 'same');
        % and subtract the respective counts from those disks.
        mat.numNewPixelsCovered(y1:y2, x1:x2, r) = ...
            mat.numNewPixelsCovered(y1:y2, x1:x2, r) - numPixelsSubtracted;
        % update diskCost, diskCostPerPixel, and diskCostEfficiency *only* for
        % the locations that have been affected, for efficiency.
        mat.diskCost(y1:y2, x1:x2, r) = mat.diskCost(y1:y2, x1:x2, r) - ...
            numPixelsSubtracted .* mat.diskCostPerPixel(y1:y2, x1:x2, r);
        mat.diskCostPerPixel(y1:y2, x1:x2, r) = mat.diskCost(y1:y2, x1:x2, r) ./ ...
            max(eps, mat.numNewPixelsCovered(y1:y2, x1:x2, r)) + ... % avoid 0/0
            mat.BIG * (mat.numNewPixelsCovered(y1:y2, x1:x2, r) == 0); % x/0 = inf
        mat.diskCostEffective(y1:y2, x1:x2, r) = ...
            mat.diskCostPerPixel(y1:y2, x1:x2, r) + mat.ws / mat.scales(r);
    end
    % Make sure disk with the same center is not selected again
    mat.diskCost(yc, xc, :) = mat.BIG;
    mat.diskCostEffective(yc, xc, :) = mat.BIG;
end
