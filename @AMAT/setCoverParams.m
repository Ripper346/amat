function setCoverParams(mat, img, scales)
    mat.img = img;
    mat.scales = scales;
    mat.numScales = numel(mat.scales);  % TODO compute range for every level
    mat.filters = initializeFilters(mat);
    [mat.numRows, mat.numCols, mat.numChannels] = size(mat.img);
    [mat.x, mat.y] = meshgrid(1:mat.numCols, 1:mat.numRows);
    mat.encoding = computeEncodings(mat);
    mat.cost = computeCosts(mat);
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
