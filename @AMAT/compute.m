function mat = compute(mat)
    profile on;
    if mat.usePyramid
        imgs = mat.generatePyramid(mat.input, mat.pyramidOpts{:});
    else
        imgs = {mat.input};
    end
    mat.setLevelParams(imgs);
    for i = 1:size(mat.levels)
        mat.setCover(i);
    end
    profile off;
    profile viewer;
end
