function setCoverParams(mat, img, scales)
    mat.img = img;
    mat.scales = scales;
    mat.numScales = numel(mat.scales);  % TODO compute range for every level
    mat.filters = initializeFilters(mat);
    [mat.numRows, mat.numCols, mat.numChannels] = size(mat.img);
    [mat.x, mat.y] = meshgrid(1:mat.numCols, 1:mat.numRows);
    mat.encoding = computeEncodings(mat);
    mat.calculateDiskCosts();
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

function filters = initializeFilters(mat)
    if isa(mat.shape, 'cell')
        filters = cell(numel(mat.shape));
        for sh = 1:numel(mat.shape)
            filters{sh} = mat.shape(sh).getFilters(mat, mat.numScales);
        end
    elseif mat.shape ~= NaN
        filters = mat.shape.getFilters(mat, mat.numScales);
    else
        error('Invalid filter shape');
    end
    % squares with rotations
    k = size(filters, 1); % dimension corresponding to square
    for d = 1:numel(mat.thetas)
        for i = 1:numScales
            filters{k + d, i} = Square.get(mat.scales(i), mat.thetas(d));
        end
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
