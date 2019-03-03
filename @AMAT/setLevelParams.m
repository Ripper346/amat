function setLevelParams(mat, imgs)
    mat.levels = arrayfun(@(x)AMAT(mat), 1:size(imgs, 1), 'UniformOutput', false);
    for i = 1:size(mat.levels, 2)
        mat.levels{i}.setCoverParams(imgs{i}, mat.scales);
    end
end
