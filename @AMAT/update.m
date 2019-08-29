function update(mat, minCost, xc, yc, rc, newPixelsCovered, nextLevel)
    mat.covered(newPixelsCovered) = true;
    mat.price(newPixelsCovered) = minCost / mat.numNewPixelsCovered(yc, xc, rc);
    mat.axis(yc, xc, :) = mat.encoding(yc, xc, :, rc);
    mat.radius(yc, xc) = mat.scales(rc);
    mat.updateCosts(xc, yc, newPixelsCovered);
    % if nargin > 7
    %     updateNextLevel(mat, nextLevel, xc, yc, rc);
    % end
end

function updateNextLevel(mat, nextLevel, xc, yc, rc)
    % TODO check if enlargement works for odd and rectangular images - DONE ignore exceeding margins
    for yb = 1:2
        for xb = 1:2
            if nextLevel.numCols > (yc - 1) * 2 + yb && nextLevel.numRows > (xc - 1) * 2 + xb
                nextLevel.diskCost((yc - 1) * 2 + yb, (xc - 1) * 2 + xb, :) = nextLevel.BIG;
                nextLevel.diskCostEffective((yc - 1) * 2 + yb, (xc - 1) * 2 + xb, :) = nextLevel.BIG;
                % TODO fix ignoring all calculations only set new min
                areaCovered = nextLevel.getPointsCovered((xc - 1) * 2 + xb, (yc - 1) * 2 + yb, mat.scales(rc) * 2);
                newPixelsCovered = areaCovered & ~nextLevel.covered;
                nextLevel.covered(newPixelsCovered) = true;
                % updateCosts(nextLevel, (xc - 1) * 2 + xb, (yc - 1) * 2 + yb, newPixelsCovered);
                if nextLevel.diskCostEffective(mat.nextIdxMinCost) == mat.BIG
                    [mat.nextMinCost, mat.nextIdxMinCost] = min(nextLevel.diskCostEffective(:));
                end
            end
        end
    end
end
