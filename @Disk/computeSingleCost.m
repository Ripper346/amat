function cost = computeSingleCost(ds, mat, r)
    inputlab = rgb2labNormalized(mat.img);
    cfilt = { AMAT.circle(r * 2), AMAT.circle(r * 2 - 1) };
    enc = zeros(mat.numRows, mat.numCols, mat.numChannels, 2);
    for c = 1:mat.numChannels
        for r = 1:2
            enc(:, :, c, r) = conv2(inputlab(:, :, c), cfilt{r}, 'same');
        end
    end
    enc = cumsum(enc, 4);
    areas = cumsum(cellfun(@nnz, cfilt));
    enc = bsxfun(@rdivide, enc, reshape(areas, 1, 1, 1, []));
end
