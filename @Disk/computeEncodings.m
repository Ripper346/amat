function enc = computeEncodings(ds, mat, inputlab)
    % Efficient implementation, using convolutions with
    % circles + cumsum instead of convolutions with disks.
    cfilt = cell(1, mat.numScales);
    cfilt{1} = Disk.get(mat.scales(1));
    for r = 2:mat.numScales, cfilt{r} = AMAT.circle(mat.scales(r)); end
    enc = zeros(mat.numRows, mat.numCols, mat.numChannels, mat.numScales);
    for c = 1:mat.numChannels
        for r = 1:mat.numScales
            enc(:, :, c, r) = conv2(inputlab(:, :, c), cfilt{r}, 'same');
        end
    end
    enc = cumsum(enc, 4);
    areas = cumsum(cellfun(@nnz, cfilt));
    enc = bsxfun(@rdivide, enc, reshape(areas, 1, 1, 1, []));
end
