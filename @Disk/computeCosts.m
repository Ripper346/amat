function costs = computeCosts(ds, mat, levelIndex)
    % This function computes a heuristic that represents the
    % ability to reconstruct a disk-shaped part of the input image
    % using the mean RGB values computed over the same area.
    % Intuitively, the idea behind this heuristic is the following:
    % In order to accurately reconstruct an image disk of radius r
    % using its mean RGB values, we must also be able to reconstruct
    % *every* fully contained disk of radius r' < r
    % (uniformity criterion).
    %
    % Terminology: an r-disk is a disk of radius = r.
    %
    % The heuristic we use sums all square errors between the
    % encoding of an r-disk centered at a point (i, j) and the
    % encodings of all FULLY CONTAINED disks.
    % Written in a simplified mathematical form, for a given r_k-disk:
    % M_rk = sum_i(I_rk)/D_rk; M_ri = sum_i(I_ri)/R_ri;
    % Cost = sum((M_rk-M_ri)^2) for all enclosed ri-disks.
    % Cost = sum( M_rk^2 + M_ri^2 - 2*M_rk*M_ri ) = ...
    % D_rk*enc2 + conv2(enc2) + 2 .* enc .* conv2(enc)
    % Given an r-disk, filters(r-i+1) is a mask that marks the
    % centers of all contained i-disks.

    % Precompute necessary quantitities. We use circular filters applied on
    % cumulative sums instead of disk filters, for efficiency.
    % Disk costs are always the first channel
    level = mat.levels{levelIndex};
    enc = level.encoding(:, :, :, :, 1);
    enc2 = enc .^ 2;
    enccsum = cumsum(enc, 4);
    enc2csum = cumsum(enc2, 4);
    [numRows, numCols, numChannels, numScales] = size(enc);
    cfilt = cell(1, numScales);
    cfilt{1} = Disk.get(level.scales(1) - 1);
    for r = 2:numScales
        cfilt{r} = AMAT.circle(level.scales(r - 1));
    end
    nnzcd = cumsum(cumsum(cellfun(@nnz, cfilt)));

    costs = zeros(numRows, numCols, numChannels, numScales);
    for c = 1:numChannels
        for r = 1:numScales
            sumMri = zeros(numRows, numCols);
            sumMri2 = zeros(numRows, numCols);
            for i = 1:r
                sumMri = sumMri + conv2(enccsum(:, :, c, i), cfilt{r - i + 1}, 'same');
                sumMri2 = sumMri2 + conv2(enc2csum(:, :, c, i), cfilt{r - i + 1}, 'same');
            end
            costs(:, :, c, r) = enc2(:, :, c, r) * nnzcd(r) + sumMri2 - 2 * enc(:, :, c, r) .* sumMri;
        end
    end

    % Fix boundary conditions. Setting scale(r)-borders to a very big cost
    % helps us avoid selecting disks that cross the image boundaries.
    % We do not use Inf to avoid complications in the greedy set cover
    % algorithm, caused by inf-inf subtractions and inf/inf divisions.
    % Also, keep in mind that max(0, NaN) = 0.
    for r = 1:numScales
        scale = level.scales(r);
        costs([1:scale, end - scale + 1:end], :, :, r) = mat.BIG;
        costs(:, [1:scale, end - scale + 1:end], :, r) = mat.BIG;
    end

    % Sometimes due to numerical errors, cost are slightly negative. Fix this.
    costs = max(0, costs);

    % Combine costs from different channels
    if numChannels > 1
        wc = [0.5, 0.25, 0.25]; % weights for luminance and color channels
        costs = costs(:, :, 1, :) * wc(1) + costs(:, :, 2, :) * wc(2) + costs(:, :, 3, :) * wc(3);
    end
    costs = squeeze(costs);
end
