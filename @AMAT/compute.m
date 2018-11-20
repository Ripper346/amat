function mat = compute(mat)
    computeEncodings(mat);
    computeCosts(mat);
    profile on;
    mat.setCover();
    profile off;
    profile viewer;
end

function computeEncodings(mat)
    inputlab = rgb2labNormalized(mat.input);
    if isa(mat.shape, 'cell')
        encd = mat.shape{1}.computeEncodings(mat, inputlab);
        encs = mat.shape{2}.computeEncodings(mat, inputlab);
        mat.encoding = cat(5, encd, encs);
    elseif mat.shape ~= NaN
        mat.encoding = mat.shape.computeEncodings(mat, inputlab);
    else
        error('Invalid shape');
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
