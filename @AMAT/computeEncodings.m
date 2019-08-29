function encoding = computeEncodings(mat, scales)
    if nargin < 2
        scales = mat.scales;
    end
    inputlab = rgb2labNormalized(mat.img);
    if isa(mat.shape, 'cell')
        encd = mat.shape{1}.computeEncodings(mat, inputlab, scales);
        encs = mat.shape{2}.computeEncodings(mat, inputlab, scales);
        encoding = cat(5, encd, encs);
    elseif mat.shape ~= NaN
        encoding = mat.shape.computeEncodings(mat, inputlab, scales);
    else
        error('Invalid shape');
    end
end
