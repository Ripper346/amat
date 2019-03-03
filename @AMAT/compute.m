function mat = compute(mat)
    profile on;
    if mat.usePyramid
        imgs = mat.generatePyramid(mat.input, mat.pyramidOpts{:});
    else
        imgs = {mat.input};
    end
    mat.setLevelParams(imgs);
    for i = 1:size(mat.levels, 2)
        mat.levels{i}.setCover();
        profile off;
        mat.levels{i}.showImg();
        profile on;
    end
    profile off;
    profile viewer;
    mat.showImg();
end
