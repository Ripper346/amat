function [minCost, idxMinCost, yMin, xMin, rMin] = coverNeighbors(mat, xc, yc, x, y, pathNum, numRows, numCols, numScales)
    while true
        [minCost, idxMinCost, yMin, xMin, rMin, topIndexes] = getTop(mat);
        [neighbor] = getTopNeighbor(mat, xc, yc, topIndexes);
        if isempty(neighbor); return; end
        [yc, xc, rc] = ind2sub(size(mat.diskCostEffective), neighbor);
        areaCovered = mat.getPointsCovered(x, y, xc, yc, rc);
        newPixelsCovered = areaCovered & ~mat.covered;
        mat.update(minCost, areaCovered, xc, yc, rc, newPixelsCovered, numRows, numCols, numScales);
        if mat.vistop
            mat.showImg(xc, yc, rc, numRows, numCols, numScales);
        end
        [minCost, idxMinCost, yMin, xMin, rMin] = mat.coverNeighbors(xc, yc, x, y, pathNum + 1, numRows, numCols, numScales);
    end
end

function [minCost, idxMinCost, yc, xc, rc, ind] = getTop(mat)
    [minC, ind] = mink(mat.diskCostEffective(:), mat.topNeighSelection);
    [yc, xc, rc] = ind2sub(size(mat.diskCostEffective), ind(1));
    minCost = minC(1);
    idxMinCost = ind(1);
end

function [neighbor] = getTopNeighbor(mat, xc, yc, topIndexes)
    sizes = size(mat.diskCostEffective);
    neighbor = [];
    for j = 1:mat.topNeighSelection
        [y, x, ~] = ind2sub(sizes, topIndexes(j));
        if abs(xc - x) <= 1 && abs(yc - y) <= 1
            neighbor = topIndexes(j);
            break;
        end
    end
end
