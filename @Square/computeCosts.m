function costs = computeSquareCosts(sq, mat)
    % Similar to computeDiskCosts() but for square filters.
    % If we only use square filters, then enc is the first channel,
    % otherwise it's the second channel
    squareIndex = min(2, size(mat.encoding, 5));
    enc = mat.encoding(:, :, :, :, squareIndex);
    enc2 = enc .^ 2;
    sfilt = cell(1, mat.numScales); sfilt{1} = Square.get(mat.scales(1) - 1);
    for r = 2:mat.numScales, sfilt{r} = Square.get(mat.scales(r - 1)); end
    nnzcs= cumsum(cellfun(@nnz, sfilt)); % cumsum of square areas

    % Compute costs for axis-aligned squares
    costs = zeros(mat.numRows, mat.numCols, mat.numChannels, mat.numScales);
    for c = 1:mat.numChannels
        for r = 1:mat.numScales
            sumMri = zeros(mat.numRows, mat.numCols);
            sumMri2 = zeros(mat.numRows, mat.numCols);
            for i = 1:r
                % Squares are separable so we can speed-up conv
                fones = sfilt{r - i + 1}(1, :);
                sumMri = sumMri + conv2(fones, fones', enc(:, :, c, i), 'same');
                sumMri2 = sumMri2 + conv2(fones, fones', enc2(:, :, c, i), 'same');
            end
            costs(:, :, c, r) = enc2(:, :, c, r) * nnzcs(r) + sumMri2 - 2 * enc(:, :, c, r) .* sumMri;
        end
    end

    % Same postprocesssing as computeDiskCosts
    for r = 1:mat.numScales
        scale = mat.scales(r);
        costs([1:scale, end - scale + 1:end], :, :, r, :) = mat.BIG;
        costs(:, [1:scale, end - scale + 1:end], :, r, :) = mat.BIG;
    end

    % Compute costs for rotated squares
    if ~isempty(mat.thetas)
        O = numel(mat.thetas);
        encrot = enc(:, :, :, :, end - O + 1:end);
        enc2rot = enc2(:, :, :, :, end - O + 1:end);
        squareRotCost = computeRotatedSquareCosts(mat, encrot, enc2rot);
        for r = 1:mat.numScales
            scalerot = ceil(sqrt(2) * mat.scales(r)); % square "radius"
            squareRotCost([1:scalerot, end - scalerot + 1:end], :, :, r, :) = mat.BIG;
            squareRotCost(:, [1:scalerot, end - scalerot + 1:end], :, r, :) = mat.BIG;
        end
        costs = cat(5, costs, squareRotCost);
    end

    % Sometimes due to numerical errors, costs are slightly negative.
    costs = max(0, costs);

    % Combine costs from different channels
    if mat.numChannels > 1
        wc = [0.5, 0.25, 0.25]; % weights for luminance and color channels
        costs = costs(:, :, 1, :, :) * wc(1) + ...
                        costs(:, :, 2, :, :) * wc(2) + ...
                        costs(:, :, 3, :, :) * wc(3);
    end
    costs = squeeze(costs);
end

function squareRotCost = computeRotatedSquareCosts(mat, enc, enc2)
    % Integral columns used to efficiently compute sums inside
    % areas of rotated squares
    encic = cumsum(enc, 1);
    enc2ic = cumsum(enc2, 1);
    pad = ceil(sqrt(2) * mat.scales(end));
    encic = padarray(encic, [pad pad], 0, 'pre');
    encic = padarray(encic, [pad pad], 'replicate', 'post');
    enc2ic = padarray(enc2ic, [pad pad], 0, 'pre');
    enc2ic = padarray(enc2ic, [pad pad], 'replicate', 'post');
    O = numel(mat.thetas);

    % Rotated square filters and integral filters
    sfilt = cell(1, mat.numScales);
    rotfilt = cell(O, mat.numScales);
    pfilt = cell(O, mat.numScales);
    sfilt{1} = Square.get(mat.scales(1) - 1);
    for r = 2:mat.numScales
        sfilt{r} = Square.get(mat.scales(r - 1));
    end
    for r = 1:mat.numScales
        for o = 1:O
            rotfilt{o, r} = imrotate(sfilt, mat.thetas(o));
            % Make sure that the border has a zero-border
            pfilt{o, r} = padarray(rotfilt{o, r}, [1 1], 0);
            pfilt{o, r} = [-diff(pfilt{o, r}); zeros(1, size(pfilt{o, r}, 2))];
            % Make sure filter is odd-sized
            pad = ~isodd(size(pfilt{o, r}));
            pfilt{o, r} = padarray(pfilt{o, r}, pad, 0, 'post');
        end
    end
    % Areas of rotated square filters
    nnzcs = cumsum(cellfun(@nnz, rotfilt), 2);

    % Compute heuristic costs for rotated square filters
    squareRotCost = zeros(mat.numRows, mat.numCols, mat.numChannels, mat.numScales, O);
    for o = 1:O
        for c = 1:mat.numChannels
            for r = 1:mat.numScales
                sumMri = zeros(mat.numRows, mat.numCols);
                sumMri2 = zeros(mat.numRows, mat.numCols);
                for i = 1:r
                    sumMri = sumMri + filter2(pfilt{o, r - i + 1}, encic(:, :, c, i));
                    sumMri2 = sumMri2 + filter2(pfilt{o, r - i + 1}, enc2ic(:, :, c, i));
                end
                squareRotCost(:, :, c, r, o) = enc2(:, :, c, r, o)*nnzcs(o, r) + ...
                    sumMri2 - 2 * enc(:, :, c, r, o) .* sumMri;
            end
        end
    end
    squareRotCost = squareRotCost(pad + 1:end - pad, pad + 1:end - pad, :, :, :);
end
