function update(mat, minCost, areaCovered, xc, yc, rc, newPixelsCovered, numRows, numCols, numScales)
    mat.covered(newPixelsCovered) = true;
    mat.price(newPixelsCovered) = minCost / mat.numNewPixelsCovered(yc, xc, rc);
    mat.depth(areaCovered) = mat.depth(areaCovered) + 1;
    mat.axis(yc, xc, :) = mat.encoding(yc, xc, :, rc);
    mat.radius(yc, xc) = mat.scales(rc);
    updateCosts(mat, xc, yc, newPixelsCovered, numRows, numCols, numScales);
end

function updateCosts(mat, xc, yc, newPixelsCovered, numRows, numCols, numScales)
    [yy, xx] = find(newPixelsCovered);
    xminCovered = min(xx);
    xmaxCovered = max(xx);
    yminCovered = min(yy);
    ymaxCovered = max(yy);
    newPixelsCovered = double(newPixelsCovered);
    for r = 1:numScales
        scale = mat.scales(r);
        x1 = max(xminCovered - scale, 1);
        y1 = max(yminCovered - scale, 1);
        x2 = min(xmaxCovered + scale, numCols);
        y2 = min(ymaxCovered + scale, numRows);
        % Find how many of the newPixelsCovered are covered by other disks.
        numPixelsSubtracted = conv2(newPixelsCovered(y1:y2, x1:x2), mat.filters{r}, 'same');
        % and subtract the respective counts from those disks.
        mat.numNewPixelsCovered(y1:y2, x1:x2, r) = mat.numNewPixelsCovered(y1:y2, x1:x2, r) - numPixelsSubtracted;
        % update diskCost, diskCostPerPixel, and diskCostEfficiency *only* for
        % the locations that have been affected, for efficiency.
        mat.diskCost(y1:y2, x1:x2, r) = mat.diskCost(y1:y2, x1:x2, r) - ...
            numPixelsSubtracted .* mat.diskCostPerPixel(y1:y2, x1:x2, r);
        mat.diskCostPerPixel(y1:y2, x1:x2, r) = mat.diskCost(y1:y2, x1:x2, r) ./ ...
            max(eps, mat.numNewPixelsCovered(y1:y2, x1:x2, r)) + ... % avoid 0/0
            mat.BIG * (mat.numNewPixelsCovered(y1:y2, x1:x2, r) == 0); % x/0 = inf
        mat.diskCostEffective(y1:y2, x1:x2, r) = ...
            mat.diskCostPerPixel(y1:y2, x1:x2, r) + mat.ws / mat.scales(r);
    end
    % Make sure disk with the same center is not selected again
    mat.diskCost(yc, xc, :) = mat.BIG;
    mat.diskCostEffective(yc, xc, :) = mat.BIG;
end
