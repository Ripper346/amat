function enc = computeSquareEncodings(mat, inputlab)
    [numRows, numCols, numChannels] = size(mat.input);
    numScales = numel(mat.scales);

    % Since square filters are separable, using filter2 + full
    % filters is more efficient than using integral images.
    squareIndex = min(2, size(mat.filters, 1));
    enc = zeros(numRows, numCols, numChannels, numScales);
    for c = 1:numChannels
        for r = 1:numScales
            sep = mat.filters{squareIndex, r}(1, :);
            enc(:, :, c, r) = conv2(sep, sep', inputlab(:, :, c), 'same');
        end
    end
    areas = (2 * mat.scales + 1) .^ 2;
    enc = bsxfun(@rdivide, enc, reshape(areas, 1, 1, 1, []));

    % Optionally compute encodings for rotated squares
    if ~isempty(mat.thetas)
        encrot = computeRotatedSquareEncodings(mat, cumsum(inputlab, 1));
        enc = cat(5, enc, encrot);
    end
end

function enc = computeRotatedSquareEncodings(mat, integralColumns)
    % Pad integralColumns image with max size of rotated filter.
    pad = ceil(sqrt(2) * mat.scales(end)); % square radius
    integralColumns = padarray(integralColumns, [pad, pad], 0, 'pre');
    integralColumns = padarray(integralColumns, [pad, pad], 'replicate', 'post');
    [numRows, numCols, numChannels] = size(integralColumns);
    numScales = numel(mat.scales);
    O = numel(mat.thetas);
    % Rotated square filters and integral filters
    squareIndex = min(2, size(mat.filters, 1));
    rotfilt = cell(O, numScales);
    pfilt = cell(O, numScales);
    for r = 1:numScales
        for o = 1:O
            rotfilt{o, r} = mat.filters{squareIndex, r};
            % Make sure that the border has a zero-border
            pfilt{o, r} = padarray(rotfilt{o, r}, [1 1], 0);
            pfilt{o, r} = [-diff(pfilt{o, r}); zeros(1, size(pfilt{o, r}, 2))];
            % Make sure filter is odd-sized
            pad = ~isodd(size(pfilt{o, r}));
            pfilt{o, r} = padarray(pfilt{o, r}, pad, 0, 'post');
        end
    end
    % Areas of rotated square filters
    areas = cellfun(@nnz, rotfilt);

    % Compute heuristic encodings for rotated square filters
    enc = zeros(numRows, numCols, numChannels, numScales, O);
    for o = 1:O
        for r = 1:numScales
            for c = 1:numChannels
                enc(:, :, c, r, o) = filter2(pfilt{o, r}, integralColumns) / areas(o, r);
            end
        end
    end
    enc = enc(pad + 1:end - pad, pad + 1:end - pad, :, :, :);
end
