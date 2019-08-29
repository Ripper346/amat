function coverNeighbors(mat, areaCovered, xc, yc, rc)
    [neighbors] = getSelectedNeighbors(mat, areaCovered, xc, yc, rc);
    for n = 1:size(neighbors, 1)
        xc = neighbors(n, 1);
        yc = neighbors(n, 2);
        rc = neighbors(n, 3);
        if mat.diskCost(yc, xc, rc) ~= mat.BIG
            nieghAreaCovered = mat.getPointsCovered(xc, yc, mat.scales(rc));
            newPixelsCovered = nieghAreaCovered & ~mat.covered;
            if any(newPixelsCovered(:))
                mat.update(mat.diskCostEffective(yc, xc, rc), xc, yc, rc, newPixelsCovered);
                if mat.vistop
                    mat.showImg(xc, yc, rc);
                end
            else
                mat.updateCosts(xc, yc, newPixelsCovered);
            end
            mat.coverNeighbors(areaCovered, xc, yc, rc);
        end
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
    top = repmat(areaCovered, 1, mat.numChannels);
    covered = reshape(mat.input(:) .* top(:), mat.numRows, mat.numCols, mat.numChannels);
    covered = covered(min(yCover(yCover > 0)):max(yCover(:)), min(xCover(xCover > 0)):max(xCover(:)), :);
    % if nargin == 2
    %     % Calculus of image's percentage not in the cover
    %     exclZone = 1 - sum(areaCovered(:)) / ((max(yCover(:)) - min(yCover(yCover > 0))) * (max(xCover(:)) - min(xCover(xCover > 0))));
    % end
end

function [neighbor] = getSelectedNeighbors(mat, areaCovered, xc, yc, rc)
    mainCover = getCoveredArea(mat, areaCovered);
    neighbor = [];
    for i = -1:1
        for j = -1:1
            if ~(i == 0 && j == 0) && mat.diskCost(yc + j, xc + i, rc) ~= mat.BIG
                for rs = numel(mat.scales):-1:1
                    covered = getCoveredArea(mat, rs, xc + i, yc + j);
                    try
                    if size(mainCover, 1) > size(covered, 1)
                        similarity = ssim(imresize(covered, [size(mainCover, 1), size(mainCover, 2)]), mainCover);
                    else
                        similarity = ssim(covered, imresize(mainCover, [size(covered, 1), size(covered, 2)]));
                    end
                    catch
                        continue;
                    end
                    if similarity > 0.98
                        neighbor = [neighbor; [xc + i, yc + j, rs, similarity]];
                        break;
                    end
                end
            end
        end
    end
    if ~isempty(neighbor)
        neighbor = sortrows(neighbor, [4 3]);
    end
end
