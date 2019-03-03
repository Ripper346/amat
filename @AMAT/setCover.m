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
    mat.initializeFigure();
    zeroLabNormalized = rgb2labNormalized(zeros(mat.numRows, mat.numCols, mat.numChannels));
    mat.input = reshape(mat.img, mat.numRows * mat.numCols, mat.numChannels);
    mat.reconstruction = reshape(zeroLabNormalized, mat.numRows * mat.numCols, mat.numChannels);
    mat.axis = zeroLabNormalized;
    mat.radius = zeros(mat.numRows, mat.numCols);
    mat.depth = zeros(mat.numRows, mat.numCols); % #disks points(x, y) is covered by
    mat.price = zeros(mat.numRows, mat.numCols); % error contributed by each point
    initializeCoveredMatrix(mat);
    calculateDiskCosts(mat);
    % Print remaining pixels to be covered in these points
    printBreakPoints = floor((4:-1:1) .* (mat.numRows * mat.numCols / 5));

    % GREEDY ALGORITHM STARTS HERE --------------------------------
    fprintf('Pixels remaining: ');
    while ~all(mat.covered(:))
        % Get disk with min cost
        [minCost, idxMinCost] = min(mat.diskCostEffective(:));
        [yc, xc, rc] = ind2sub(size(mat.diskCostEffective), idxMinCost);

        if isinf(minCost)
            warning('Stopping: selected disk has infinite cost.');
            break;
        end

        areaCovered = getPointsCovered(mat, xc, yc, rc);
        newPixelsCovered = areaCovered & ~mat.covered;
        if ~any(newPixelsCovered(:))
            keyboard;
            warning('Stopping: selected disk covers zero (0) new pixels.');
            break;
        end

        if mat.logProgress
            mat.logNeighborhood(xc, yc);
        end
        mat.update(minCost, areaCovered, xc, yc, rc, newPixelsCovered);
        if mat.logProgress
            mat.logNeighborhood(xc, yc);
        end

        % Visualize progress
        if mat.vistop
            mat.showImg(xc, yc, rc);
        end
        if ~isempty(printBreakPoints) && nnz(~mat.covered) < printBreakPoints(1)
            fprintf('%d...', printBreakPoints(1));
            printBreakPoints(1) = [];
        end
    end
    fprintf('\n');
    mat.input = reshape(mat.input, mat.numRows, mat.numCols, mat.numChannels);
    mat.axis = labNormalized2rgb(mat.axis);
    mat.computeReconstruction();
end

function initializeCoveredMatrix(mat)
    mat.covered = false(mat.numRows, mat.numCols);
    % Flag border pixels that cannot be accessed by filters
    if isa(mat.shape, 'Disk')
        r = mat.scales(1);
        mat.covered([1:r, end - r + 1:end], [1, end]) = true;
        mat.covered([1, end], [1:r, end - r + 1:end]) = true;
    end
end

function calculateDiskCosts(mat)
    % Compute how many pixels are covered by each r-disk.
    diskAreas = cellfun(@nnz, mat.filters);
    mat.diskCost = mat.cost;
    mat.numNewPixelsCovered = repmat(reshape(diskAreas, 1, 1, []), [mat.numRows, mat.numCols]);

    % Add scale-dependent cost term to favor the selection of larger disks.
    mat.diskCostPerPixel = mat.diskCost ./ mat.numNewPixelsCovered;
    mat.diskCostEffective = bsxfun(@plus, mat.diskCostPerPixel, ...
        reshape(mat.ws ./ mat.scales, 1, 1, []));
end

function area = getPointsCovered(mat, xc, yc, rc)
    if isa(mat.shape, 'cell')
        error('Mix of shapes not supported yet');
    elseif mat.shape ~= NaN
        area = mat.shape.getArea(mat.x, mat.y, xc, yc, mat.scales(rc));
    else
        error('Shape is not supported');
    end
end
