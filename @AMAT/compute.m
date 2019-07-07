function mat = compute(mat)
    profile on;
    if mat.usePyramid
        % generate image pyramid
        scales = calculateLevelScales(mat.scales);
        imgSize = size(mat.input);
        imgs = mat.generatePyramid(mat.input, min(imgSize(1:2)) / 2 ^ (size(scales, 1) - 1));
    else
        scales = {mat.scales};
        imgs = {mat.input};
    end
    setLevelParams(mat, imgs, scales);
    % cover of the levels
    for i = size(mat.levels, 2):-1:1
        if i > 1
            mat.levels{i}.setCover(mat.levels{i - 1});
            mat.levels{i - 1}.convertSmallerCover(mat.levels{i});
        else
            mat.levels{i}.setCover();
        end
        profile off;
        mat.levels{i}.showImg();
        profile resume;
    end
    calculateDepth(mat);
    mat.computeReconstruction();
    profile off;
    profile viewer;
    mat.showImg();
end

function setLevelParams(mat, imgs, scales)
% Set essential class attributes from main mat object to level mats.
    mat.levels = arrayfun(@(x)AMAT(mat), 1:size(imgs, 1), 'UniformOutput', false);
    for i = 1:size(scales, 1)
        mat.levels{i}.setCoverParams(imgs{i}, scales{i});
    end
end

function scales = calculateLevelScales(originScale)
% Calculate scales for each level
    topLevel = floor(log2(max(originScale) / 4)) + 1;
    bottomLevel = floor(log2(min(originScale) / 2)) + 1;
    scales = cell(topLevel, 1);
    for i = 1:topLevel
        if i < bottomLevel
            % level not included in the cover
            scales{i} = 0;
        else
            % bottom pyramid level, we convert the original smallest radius to fit the size of level
            if i == bottomLevel; smallestRadious = floor(min(originScale) / 2 ^ (i - 1)); else; smallestRadious = 3; end
            % top pyramid level, we convert the original biggest radius to fit the size of level
            if i == topLevel;    biggestRadious  = ceil(max(originScale) / 2 ^ (i - 1));  else; biggestRadious  = 4; end
            scales{i} = smallestRadious : biggestRadious;
        end
    end
end

function calculateDepth(mat)
% Calculate depth matrix. Radius matrix has to be populated.
    mat.depth = zeros(mat.numRows, mat.numCols);
    for y = 1:mat.numRows
        for x = 1:mat.numCols
            if mat.radius(y, x) > 0
                areaCovered = mat.getPointsCovered(x, y, mat.radius(y, x));
                mat.depth(areaCovered) = mat.depth(areaCovered) + 1;
            end
        end
    end
end
