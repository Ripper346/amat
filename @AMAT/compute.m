function mat = compute(mat)
    profile on;
    if mat.usePyramid
        mat.imgs = mat.generatePyramid(mat.input, mat.pyramidOpts{:});
    else
        mat.imgs = {mat.input};
    end
    computeEncodings(mat);
    computeCosts(mat);
    for i = 1:size(mat.imgs, 1)
        mat.setCover();
    end
    profile off;
    profile viewer;
end

function computeEncodings(mat)
    for i = 1:size(mat.imgs, 1)
        inputlab = rgb2labNormalized(mat.imgs(i));
        if isa(mat.shape, 'cell')
            encd = mat.shape{1}.computeEncodings(mat, inputlab);
            encs = mat.shape{2}.computeEncodings(mat, inputlab);
            mat.encoding(i) = cat(5, encd, encs);
        elseif mat.shape ~= NaN
            mat.encoding(i) = mat.shape.computeEncodings(mat, inputlab);
        else
            error('Invalid shape');
        end
    end
end

function computeCosts(mat)
    if isa(mat.shape, 'cell')
        dcost = mat.shape{1}.computeCosts(mat);
        scost = mat.shape{2}.computeCosts(mat);
        mat.cost = cat(4, dcost, scost);
    elseif mat.shape ~= NaN
        mat.cost = mat.shape.computeCosts(mat);
    else
        error('Invalid shape');
    end
end
