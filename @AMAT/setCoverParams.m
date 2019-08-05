function setCoverParams(mat, img, scales)
    mat.img = img;
    mat.scales = scales;
    mat.numScales = numel(mat.scales);
    mat.filters = mat.initializeFilters();
    [mat.numRows, mat.numCols, mat.numChannels] = size(mat.img);
    [mat.x, mat.y] = meshgrid(1:mat.numCols, 1:mat.numRows);
    mat.encoding = mat.computeEncodings();
    [mat.numNewPixelsCovered, mat.diskCost, mat.diskCostPerPixel, mat.diskCostEffective] = mat.calculateDiskCosts();
    initializeCoveredMatrix(mat);
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
