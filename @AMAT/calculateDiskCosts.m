function [numNewPixelsCovered, diskCost, diskCostPerPixel, diskCostEffective] = calculateDiskCosts(mat, scales, filters, encoding)
    % Compute how many pixels are covered by each r-disk.
    if nargin < 4
        encoding = mat.encoding;
        if nargin < 3
            filters = mat.filters;
            if nargin < 2
                scales = mat.scales;
            end
        end
    end
    diskCost = computeCosts(mat, scales, encoding);
    diskAreas = cellfun(@nnz, filters);
    numNewPixelsCovered = repmat(reshape(diskAreas, 1, 1, []), [mat.numRows, mat.numCols]);
    if mat.useGpu
        diskCost = gpuArray(diskCost);
        numNewPixelsCovered = gpuArray(numNewPixelsCovered);
    end
    % Add scale-dependent cost term to favor the selection of larger disks.
    diskCostPerPixel = diskCost ./ numNewPixelsCovered;
    diskCostEffective = bsxfun(@plus, diskCostPerPixel, reshape(mat.ws ./ scales, 1, 1, []));
end

function cost = computeCosts(mat, scales, encoding)
    if isa(mat.shape, 'cell')
        dcost = mat.shape{1}.computeCosts(mat, scales, encoding);
        scost = mat.shape{2}.computeCosts(mat, scales, encoding);
        cost = cat(4, dcost, scost);
    elseif mat.shape ~= NaN
        cost = mat.shape.computeCosts(mat, scales, encoding);
    else
        error('Invalid shape');
    end
end
