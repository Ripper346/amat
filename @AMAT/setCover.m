function setCover(mat, idx)
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
    current = mat.levels{idx};
    zeroLabNormalized = rgb2labNormalized(zeros(current.numRows, current.numCols, current.numChannels));
    current.result = reshape(current.img, current.numRows * current.numCols, current.numChannels);
    current.reconstruction = reshape(zeroLabNormalized, current.numRows * current.numCols, current.numChannels);
    current.axis = zeroLabNormalized;
    current.radius = zeros(current.numRows, current.numCols);
    current.depth = zeros(current.numRows, current.numCols); % #disks points(x, y) is covered by
    current.price = zeros(current.numRows, current.numCols); % error contributed by each point
    current.covered = initializeCoveredMatrix(mat, current);
    calculateDiskCosts(mat, current);
    % Print remaining pixels to be covered in these points
    printBreakPoints = floor((4:-1:1) .* (current.numRows * current.numCols / 5));

    % GREEDY ALGORITHM STARTS HERE --------------------------------
    fprintf('Pixels remaining: ');
    while ~all(current.covered(:))
        % Get disk with min cost
        [minCost, idxMinCost] = min(current.diskCostEffective(:));
        [yc, xc, rc] = ind2sub(size(current.diskCostEffective), idxMinCost);

        if isinf(minCost)
            warning('Stopping: selected disk has infinite cost.');
            break;
        end

        areaCovered = getPointsCovered(mat, current, xc, yc, rc);
        newPixelsCovered = areaCovered & ~current.covered;
        if ~any(newPixelsCovered(:))
            keyboard;
            warning('Stopping: selected disk covers zero (0) new pixels.');
            break;
        end

        if mat.logProgress
            mat.logNeighborhood(current, xc, yc);
        end
        mat.update(current, minCost, xc, yc, rc, newPixelsCovered);
        if mat.logProgress
            mat.logNeighborhood(current, xc, yc);
        end

        % Visualize progress
        if mat.vistop
            mat.showImg(current, xc, yc, rc);
        end
        if ~isempty(printBreakPoints) && nnz(~current.covered) < printBreakPoints(1)
            fprintf('%d...', printBreakPoints(1));
            printBreakPoints(1) = [];
        end
    end
    fprintf('\n');
    current.result = reshape(current.result, current.numRows, current.numCols, current.numChannels);
    current.axis = labNormalized2rgb(current.axis);
    mat.computeReconstruction(current);
end

function covered = initializeCoveredMatrix(mat, level)
    covered = false(level.numRows, level.numCols);
    % Flag border pixels that cannot be accessed by filters
    if isa(mat.shape, 'Disk')
        r = level.scales(1);
        covered([1:r, end - r + 1:end], [1, end]) = true;
        covered([1, end], [1:r, end - r + 1:end]) = true;
    end
end

function calculateDiskCosts(mat, level)
    % Compute how many pixels are covered by each r-disk.
    diskAreas = cellfun(@nnz, level.filters);
    level.diskCost = level.cost;
    level.numNewPixelsCovered = repmat(reshape(diskAreas, 1, 1, []), [level.numRows, level.numCols]);

    % Add scale-dependent cost term to favor the selection of larger disks.
    level.diskCostPerPixel = level.diskCost ./ level.numNewPixelsCovered;
    level.diskCostEffective = bsxfun(@plus, level.diskCostPerPixel, ...
        reshape(mat.ws ./ level.scales, 1, 1, []));
end

function area = getPointsCovered(mat, level, xc, yc, rc)
    if isa(mat.shape, 'cell')
        error('Mix of shapes not supported yet');
    elseif mat.shape ~= NaN
        area = mat.shape.getArea(level.x, level.y, xc, yc, level.scales(rc));
    else
        error('Shape is not supported');
    end
end
