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
    mat.input = reshape(mat.img, mat.numRows * mat.numCols, mat.numChannels);
    if isempty(mat.axis)
        mat.axis = rgb2labNormalized(zeros(mat.numRows, mat.numCols, mat.numChannels));
    end
    if isempty(mat.radius)
        mat.radius = zeros(mat.numRows, mat.numCols);
    end
    mat.price = zeros(mat.numRows, mat.numCols); % error contributed by each point
    % Print remaining pixels to be covered in these points
    mat.printBreakPoints = floor((4:-1:1) .* (mat.numRows * mat.numCols / 5));
    mat.nextMinCost = 1e-60;

    % GREEDY ALGORITHM STARTS HERE --------------------------------
    fprintf('Pixels remaining: ');
    while ~all(mat.covered(:))
        [minCost, idxMinCost] = min(mat.diskCostEffective(:));
        [yc, xc, rc] = ind2sub(size(mat.diskCostEffective), idxMinCost);

        if isinf(minCost)
            warning('Stopping: selected disk has infinite cost.');
            break;
        end

        areaCovered = mat.getPointsCovered(xc, yc, mat.scales(rc));
        newPixelsCovered = areaCovered & ~mat.covered;
        if ~any(newPixelsCovered(:))
            warning('Stopping: selected disk covers zero (0) new pixels.');
            break;
        end

        if mat.logProgress
            mat.logNeighborhood(xc, yc);
        end
        mat.update(minCost, xc, yc, rc, newPixelsCovered);

        % Visualize progress
        if mat.vistop
            mat.showImg(xc, yc, rc);
        end
        if ~isempty(mat.printBreakPoints) && nnz(~mat.covered) < mat.printBreakPoints(1)
            fprintf('%d...', mat.printBreakPoints(1));
            mat.printBreakPoints(1) = [];
        end
        if mat.followNeighbors > 0
            mat.coverNeighbors(xc, yc, rc);
        end
    end
    fprintf('\n');
    mat.input = reshape(mat.input, mat.numRows, mat.numCols, mat.numChannels);
end
