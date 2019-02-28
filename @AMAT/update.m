function update(mat, level, minCost, xc, yc, rc, newPixelsCovered)
    level.covered(newPixelsCovered) = true;
    level.price(newPixelsCovered) = minCost / level.numNewPixelsCovered(yc, xc, rc);
    level.depth(level.areaCovered) = level.depth(level.areaCovered) + 1;
    level.axis(yc, xc, :) = level.encoding(yc, xc, :, rc);
    level.radius(yc, xc) = level.scales(rc);
    updateCosts(mat, level, xc, yc, newPixelsCovered);
end

function updateCosts(mat, level, xc, yc, newPixelsCovered)
    [yy, xx] = find(newPixelsCovered);
    xminCovered = min(xx);
    xmaxCovered = max(xx);
    yminCovered = min(yy);
    ymaxCovered = max(yy);
    newPixelsCovered = double(newPixelsCovered);
    for r = 1:level.numScales
        scale = level.scales(r);
        x1 = max(xminCovered - scale, 1);
        y1 = max(yminCovered - scale, 1);
        x2 = min(xmaxCovered + scale, level.numCols);
        y2 = min(ymaxCovered + scale, level.numRows);
        % Find how many of the newPixelsCovered are covered by other disks.
        numPixelsSubtracted = conv2(newPixelsCovered(y1:y2, x1:x2), level.filters{r}, 'same');
        % and subtract the respective counts from those disks.
        level.numNewPixelsCovered(y1:y2, x1:x2, r) = level.numNewPixelsCovered(y1:y2, x1:x2, r) - numPixelsSubtracted;
        % update diskCost, diskCostPerPixel, and diskCostEfficiency *only* for
        % the locations that have been affected, for efficiency.
        level.diskCost(y1:y2, x1:x2, r) = level.diskCost(y1:y2, x1:x2, r) - ...
            numPixelsSubtracted .* level.diskCostPerPixel(y1:y2, x1:x2, r);
        level.diskCostPerPixel(y1:y2, x1:x2, r) = level.diskCost(y1:y2, x1:x2, r) ./ ...
            max(eps, level.numNewPixelsCovered(y1:y2, x1:x2, r)) + ... % avoid 0/0
            mat.BIG * (level.numNewPixelsCovered(y1:y2, x1:x2, r) == 0); % x/0 = inf
        level.diskCostEffective(y1:y2, x1:x2, r) = ...
            level.diskCostPerPixel(y1:y2, x1:x2, r) + mat.ws / level.scales(r);
    end
    % Make sure disk with the same center is not selected again
    level.diskCost(yc, xc, :) = mat.BIG;
    level.diskCostEffective(yc, xc, :) = mat.BIG;
end
