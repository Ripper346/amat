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
    mat.initializeCoveredMatrix(numRows, numCols);
    mat.calculateDiskCosts(numRows, numCols);
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

        areaCovered = mat.getPointsCovered(x, y, xc, yc, rc);
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
        mat.updateCosts(newPixelsCovered, xc, yc, numRows, numCols, numScales);

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
