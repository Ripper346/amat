function enc = computeEncodings(ds, mat, inputlab)
    % Efficient implementation, using convolutions with
    % circles + cumsum instead of convolutions with disks.
    [numRows, numCols, numChannels] = size(mat.input);
    numScales = numel(mat.scales);
    cfilt = cell(1, numScales);
    cfilt{1} = Disk.get(mat.scales(1));
    for r = 2:numScales, cfilt{r} = AMAT.circle(mat.scales(r)); end
    enc = zeros(numRows, numCols, numChannels, numScales);
    for c = 1:numChannels
        for r = 1:numScales
            enc(:, :, c, r) = conv2(inputlab(:, :, c), cfilt{r}, 'same');
        end
    end
    enc = cumsum(enc, 4);
    areas = cumsum(cellfun(@nnz, cfilt));
    enc = bsxfun(@rdivide, enc, reshape(areas, 1, 1, 1, []));
    mat.encoding = enc;
end
