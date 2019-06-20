function calculateDiskCosts(mat)
    % Compute how many pixels are covered by each r-disk.
    mat.cost = computeCosts(mat);
    diskAreas = cellfun(@nnz, mat.filters);
    mat.diskCost = mat.cost;
    mat.numNewPixelsCovered = repmat(reshape(diskAreas, 1, 1, []), [mat.numRows, mat.numCols]);

    % Add scale-dependent cost term to favor the selection of larger disks.
    mat.diskCostPerPixel = mat.diskCost ./ mat.numNewPixelsCovered;
    mat.diskCostEffective = bsxfun(@plus, mat.diskCostPerPixel, ...
        reshape(mat.ws ./ mat.scales, 1, 1, []));
end

function cost = computeCosts(mat)
    if isa(mat.shape, 'cell')
        dcost = mat.shape{1}.computeCosts(mat);
        scost = mat.shape{2}.computeCosts(mat);
        cost = cat(4, dcost, scost);
    elseif mat.shape ~= NaN
        cost = mat.shape.computeCosts(mat);
    else
        error('Invalid shape');
    end
end
