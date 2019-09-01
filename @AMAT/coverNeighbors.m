function coverNeighbors(mat, xc, yc, rc)
    mainCover = containers.Map('KeyType', 'double', 'ValueType', 'any');
    getSelectedNeighbors(mat, xc, yc, mainCover, rc);
    while mat.currentNeighbor <= size(mat.neighbors, 1)
        xn = mat.neighbors(mat.currentNeighbor, 1);
        yn = mat.neighbors(mat.currentNeighbor, 2);
        rn = mat.neighbors(mat.currentNeighbor, 3);
        if mat.diskCost(yn, xn, rn) ~= mat.BIG
            nieghAreaCovered = mat.getPointsCovered(xn, yn, mat.scales(rn));
            newPixelsCovered = nieghAreaCovered & ~mat.covered;
            if any(newPixelsCovered(:))
                mat.update(mat.diskCostEffective(yn, xn, rn), xn, yn, rn, newPixelsCovered);
                if mat.vistop
                    mat.showImg(xn, yn, rn);
                end
                if ~isempty(mat.printBreakPoints) && nnz(~mat.covered) < mat.printBreakPoints(1)
                    fprintf('%d...', mat.printBreakPoints(1));
                    mat.printBreakPoints(1) = [];
                end
            else
                mat.updateCosts(xn, yn, newPixelsCovered);
            end
            getSelectedNeighbors(mat, xn, yn, mainCover, rc, xc, yc);
        end
        mat.neighbors = mat.neighbors(mat.currentNeighbor + 1:end, :);
    end
end

function [covered] = getCoveredArea(mat, areaOrRc, xc, yc)
    if nargin > 2
        areaCovered = mat.getPointsCovered(xc, yc, mat.scales(areaOrRc));
    else
        areaCovered = areaOrRc;
    end
    xCover = mat.x .* areaCovered;
    yCover = mat.y .* areaCovered;
    areaCoveredChannels = repmat(areaCovered, 1, mat.numChannels);
    covered = reshape(mat.input(:) .* areaCoveredChannels(:), mat.numRows, mat.numCols, mat.numChannels);
    covered = covered(min(yCover(yCover > 0)):max(yCover(:)), min(xCover(xCover > 0)):max(xCover(:)), :);
end

function getSelectedNeighbors(mat, xc, yc, mainCover, ro, xo, yo)
    if nargin < 7
        xo = xc;
        yo = yc;
        if nargin < 6
            mainCover = containers.Map('KeyType', 'double', 'ValueType', 'any');
        end
    end
    neighbor = [];
    for i = -1:1
        for j = -1:1
            if ~(i == 0 && j == 0) && mat.diskCost(yc + j, xc + i, ro) ~= mat.BIG
                [~, rs] = min(mat.diskCostEffective(yc + j, xc + i, :));
                if rs <= ro
                    covered = getCoveredArea(mat, rs, xc + i, yc + j);
                    if ~isKey(mainCover, rs)
                        mainCover(rs) = getCoveredArea(mat, rs, xo, yo);
                    end
                    nieghAreaCovered = mat.getPointsCovered(xc + i, yc + j, mat.scales(rs));
                    newPixelsCovered = nieghAreaCovered & ~mat.covered;
                    if any(newPixelsCovered(:))
                        try
                            similarity = ssim(covered, mainCover(rs));
                            if similarity > 0.98
                                neighbor = [neighbor; [xc + i, yc + j, rs, similarity]];
                            end
                        catch
                            fprintf("ssim exc: y: %d, x: %d, r: %d, yo: %d, xo: %d\n", yc, xc, rs, yo, xo);
                        end
                    end
                end
            end
        end
    end
    if ~isempty(neighbor)
        mat.neighbors = sortrows([mat.neighbors; neighbor], [3 4], 'descend');
    end
end
