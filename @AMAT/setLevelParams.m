function setLevelParams(mat, imgs)
    mat.levels = arrayfun(@(x)struct, 1:size(imgs, 1), 'UniformOutput', false);
    for i = 1:size(mat.levels, 1)
        mat.levels{i}.img = imgs{i};
        mat.levels{i}.scales = mat.scales;
        mat.levels{i}.numScales = numel(mat.levels{i}.scales);  % TODO compute range for every level
        initializeFilters(mat, mat.levels{i});
        [mat.levels{i}.numRows, mat.levels{i}.numCols, mat.levels{i}.numChannels] = size(mat.levels{i}.img);
        [mat.levels{i}.x, mat.levels{i}.y] = meshgrid(1:mat.levels{i}.numCols, 1:mat.levels{i}.numRows);
        mat.levels{i}.encoding = computeEncodings(mat, i);
        mat.levels{i}.cost = computeCosts(mat, i);
    end
end

function encoding = computeEncodings(mat, idx)
    inputlab = rgb2labNormalized(mat.levels{idx}.img);
    if isa(mat.shape, 'cell')
        encd = mat.shape{1}.computeEncodings(mat.levels{idx}, inputlab);
        encs = mat.shape{2}.computeEncodings(mat.levels{idx}, inputlab);
        encoding = cat(5, encd, encs);
    elseif mat.shape ~= NaN
        encoding = mat.shape.computeEncodings(mat.levels{idx}, inputlab);
    else
        error('Invalid shape');
    end
end

function cost = computeCosts(mat, idx)
    if isa(mat.shape, 'cell')
        dcost = mat.shape{1}.computeCosts(mat, idx);
        scost = mat.shape{2}.computeCosts(mat, idx);
        cost = cat(4, dcost, scost);
    elseif mat.shape ~= NaN
        cost = mat.shape.computeCosts(mat, idx);
    else
        error('Invalid shape');
    end
end

function filters = initializeFilters(mat, level)
    if isa(mat.shape, 'cell')
        filters = cell(numel(mat.shapes));
        for sh = 1:numel(mat.shapes)
            filters{sh} = mat.shapes(sh).getFilters(mat, level.numScales);
        end
    elseif mat.shape ~= NaN
        filters = mat.shape.getFilters(mat, level.numScales);
    else
        error('Invalid filter shape');
    end
    % squares with rotations
    k = size(filters, 1); % dimension corresponding to square
    for d = 1:numel(mat.thetas)
        for i = 1:numScales
            filters{k + d, i} = Square.get(level.scales(i), mat.thetas(d));
        end
    end
end
