function setCoverParams(mat, img, scales)
    mat.img = img;
    mat.scales = scales;
    mat.numScales = numel(mat.scales);
    mat.filters = initializeFilters(mat);
    [mat.numRows, mat.numCols, mat.numChannels] = size(mat.img);
    [mat.x, mat.y] = meshgrid(1:mat.numCols, 1:mat.numRows);
    mat.encoding = computeEncodings(mat);
    [mat.numNewPixelsCovered, mat.diskCost, mat.diskCostPerPixel, mat.diskCostEffective] = mat.calculateDiskCosts();
    initializeCoveredMatrix(mat);
end

function encoding = computeEncodings(mat)
    inputlab = rgb2labNormalized(mat.img);
    if isa(mat.shape, 'cell')
        encd = mat.shape{1}.computeEncodings(mat, inputlab);
        encs = mat.shape{2}.computeEncodings(mat, inputlab);
        encoding = cat(5, encd, encs);
    elseif mat.shape ~= NaN
        encoding = mat.shape.computeEncodings(mat, inputlab);
    else
        error('Invalid shape');
    end
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
