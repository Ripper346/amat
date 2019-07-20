function enc = computeEncodings(ds, mat, inputlab, scales)
    % Efficient implementation, using convolutions with
    % circles + cumsum instead of convolutions with disks.
    if nargin < 4
        scales = mat.scales;
    end
    numScales = numel(scales);
    cfilt = cell(1, numScales);
    cfilt{1} = Disk.get(scales(1));
    for r = 2:numScales, cfilt{r} = AMAT.circle(scales(r)); end
    enc = zeros(mat.numRows, mat.numCols, mat.numChannels, numScales);
    for c = 1:mat.numChannels
        for r = 1:numScales
            enc(:, :, c, r) = conv2(inputlab(:, :, c), cfilt{r}, 'same');
        end
    end
    enc = cumsum(enc, 4);
    areas = cumsum(cellfun(@nnz, cfilt));
    enc = bsxfun(@rdivide, enc, reshape(areas, 1, 1, 1, []));
end
