function enc = computeEncodings(ds, level, inputlab)
    % Efficient implementation, using convolutions with
    % circles + cumsum instead of convolutions with disks.
    cfilt = cell(1, level.numScales);
    cfilt{1} = Disk.get(level.scales(1));
    for r = 2:level.numScales, cfilt{r} = AMAT.circle(level.scales(r)); end
    enc = zeros(level.numRows, level.numCols, level.numChannels, level.numScales);
    for c = 1:level.numChannels
        for r = 1:level.numScales
            enc(:, :, c, r) = conv2(inputlab(:, :, c), cfilt{r}, 'same');
        end
    end
    enc = cumsum(enc, 4);
    areas = cumsum(cellfun(@nnz, cfilt));
    enc = bsxfun(@rdivide, enc, reshape(areas, 1, 1, 1, []));
end
