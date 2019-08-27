function convertSmallerCover(mat, smallerLevel, idx)
% Convert axis and radius matrices to one times bigger level
    % mat.prevLevel = smallerLevel;
    scales = getBiggerScales(smallerLevel, idx);
    %scalesIdx = containers.Map(scales, 1:numel(scales));
    [numNewPixelsCoveredBig, diskCostBig, diskCostPerPixelBig, diskCostEffBig, filters] = getBiggerCosts(mat, scales);
    scales = horzcat(mat.scales, scales);
    filters = horzcat(mat.filters, filters);
    scalesMax = max(scales);
    diskCostEffBig = cat(3, mat.diskCostEffective, diskCostEffBig);
    diskCostEffBigSorted = unique(diskCostEffBig(:), 'sorted');
    diskCostEffBigSorted = containers.Map(diskCostEffBigSorted, 1:numel(diskCostEffBigSorted));
    mat.prevLevelCovered = zeros(mat.numRows, mat.numCols);
    mat.radius = zeros(mat.numRows, mat.numCols);
    mat.axis = rgb2labNormalized(zeros(mat.numRows, mat.numCols, mat.numChannels));
    debugCosts = [];
    file = fopen(sprintf('ranking_%d.csv', mat.numRows), 'w');
    PERCENTRANK = @(YourArray, TheProbes) reshape(mean(bsxfun(@le, YourArray(:), TheProbes(:).')) * 100, size(TheProbes));
    pickedPoints = [];
    for y = 1:smallerLevel.numRows
        for x = 1:smallerLevel.numCols
            % ySelected = -mat.BIG;
            % xSelected = -mat.BIG;
            % ySmaller = -mat.BIG;
            % xSmaller = -mat.BIG;
            % rSelected = -mat.BIG;
            % minCost = mat.BIG;
            for yb = 1:2
                for xb = 1:2
                    yc = (y - 1) * 2 + yb;
                    xc = (x - 1) * 2 + xb;
                    if mat.numCols > yc && mat.numRows > xc
                        rb = smallerLevel.radius(y, x) * 2;
                        if rb > 1
                            % [pointMinCost, idx] = min(diskCostEffBig(yc, xc, :));
                            % if pointMinCost < minCost
                            %     minCost = pointMinCost;
                            %     ySelected = yc;
                            %     xSelected = xc;
                            %     ySmaller = y;
                            %     xSmaller = x;
                            %     rSelected = idx;
                            % end
                            [pointMinCost, rc] = min(diskCostEffBig(yc, xc, :));
                            % filt = diskCostEffBigSorted(pointMinCost) * mat.numRows * mat.numCols * (scalesMax - scales(rc) + 1) / (double(diskCostEffBigSorted.Count) * double(diskCostEffBigSorted.Count) * scalesMax);
                            fprintf(file, '%d, %d, %d, %d, %d, %d, %d, %.20f\n', yc, xc, scales(rc), pointMinCost, ...
                                    scalesMax, diskCostEffBigSorted(pointMinCost), diskCostEffBigSorted.Count, filt);
                            pickedPoints = [pickedPoints; [yc, xc, y, x, pointMinCost, rc, rb]];
                            debugCosts = [debugCosts; [yc, xc, pointMinCost, scales(rc)]];
                            % if PERCENTRANK(diskCostEffBig, pointMinCost) < 25
                            %     mat.axis(yc, xc, :) = smallerLevel.axis(y, x, :);
                            %     mat.radius(yc, xc) = scales(rc);
                            %     areaCovered = mat.getPointsCovered(yc, xc, rb);
                            %     newPixelsCovered = areaCovered & ~mat.covered;
                            %     mat.covered(newPixelsCovered) = true;
                            %     try
                            %         if rc <= mat.numScales
                            %             mat.price(newPixelsCovered) = pointMinCost / mat.numNewPixelsCovered(yc, xc, rc);
                            %         else
                            %             mat.price(newPixelsCovered) = pointMinCost / numNewPixelsCoveredBig(yc, xc, rc - mat.numScales);
                            %         end
                            %     catch
                            %         i=0;
                            %     end
                            %     mat.updateCosts(xc, yc, newPixelsCovered);
                            % end
                        end
                    end
                end
            end
            % if rSelected > -mat.BIG
            %     mat.diskCost(ySelected, xSelected, :) = mat.BIG;
            %     mat.diskCostEffective(ySelected, xSelected, :) = mat.BIG;
            %     % TODO fix ignoring all calculations only set new min
            %     areaCovered = mat.getPointsCovered(xSelected, ySelected, scales(rSelected) * 2);
            %     newPixelsCovered = areaCovered & ~mat.covered;
            %     mat.covered(newPixelsCovered) = true;
            %     % updateCosts(mat, xSelected, ySelected, newPixelsCovered);
            %     % if mat.diskCostEffective(mat.nextIdxMinCost) == mat.BIG
            %     %     [mat.nextMinCost, mat.nextIdxMinCost] = min(mat.diskCostEffective(:));
            %     % end
            % end
        end
    end
    fclose(file);
    for pt = 1:size(pickedPoints, 1)
        if PERCENTRANK(pickedPoints(:, 5), pickedPoints(pt, 5)) < 25
            mat.axis(pickedPoints(pt, 1), pickedPoints(pt, 2), :) = smallerLevel.axis(pickedPoints(pt, 3), pickedPoints(pt, 4), :);
            mat.radius(pickedPoints(pt, 1), pickedPoints(pt, 2)) = scales(pickedPoints(pt, 6));
            areaCovered = mat.getPointsCovered(pickedPoints(pt, 1), pickedPoints(pt, 2), pickedPoints(pt, 7));
            newPixelsCovered = areaCovered & ~mat.covered;
            mat.covered(newPixelsCovered) = true;
            try
                if pickedPoints(pt, 6) <= mat.numScales
                    mat.price(newPixelsCovered) = pointMinCost / mat.numNewPixelsCovered(pickedPoints(pt, 1), pickedPoints(pt, 2), pickedPoints(pt, 6));
                else
                    mat.price(newPixelsCovered) = pointMinCost / numNewPixelsCoveredBig(pickedPoints(pt, 1), pickedPoints(pt, 2), pickedPoints(pt, 6) - mat.numScales);
                end
            catch
                i=0;
            end
            mat.updateCosts(pickedPoints(pt, 2), pickedPoints(pt, 1), newPixelsCovered);
        end
    end
    showDebug(debugCosts, mat.numRows, mat.numCols);
end

function scales = getBiggerScales(mat, idx)
    scales = arrayfun(@(x) round(x / 2 ^ (idx - 1)), mat.originScales(mat.originScales > max(mat.scales) * 2 ^ (idx - 1) + 1), 'UniformOutput', false);
    scales = sort(unique(horzcat(scales{:})));
end

function [numNewPixelsCovered, diskCost, diskCostPerPixel, diskCostEffective, filters] = getBiggerCosts(mat, scales)
    filters = mat.initializeFilters(scales);
    encodings = mat.computeEncodings(scales);
    [numNewPixelsCovered, diskCost, diskCostPerPixel, diskCostEffective] = mat.calculateDiskCosts(scales, filters, encodings);
end

function showDebug(debugCosts, numRows, numCols)
    figure('Name', sprintf('%dx%d costs', numRows, numCols));
    colors = [0 0 255; 0 176 80; 255 255 0; 255 0 0; 117 76 36];
    scatter(debugCosts(:, 2), debugCosts(:, 1), ...
        arrayfun(@(x) x/max(debugCosts(:, 4)) * 20, debugCosts(:, 4)), ...
        cell2mat(arrayfun(@(x) getColor(x, debugCosts(:, 3), colors),  debugCosts(:, 3), 'UniformOutput',false)), ...
        'filled');
    set(gca,'XAxisLocation','top','YAxisLocation','left','Ydir','reverse');
    ylim([0 numRows]);
    xlim([0 numCols]);
    grid on;
    pbaspect([1 1 1]);
end

function color = getColor(x, range, colors)
    PERCENTRANK = @(YourArray, TheProbes) reshape(mean(bsxfun(@le, YourArray(:), TheProbes(:).')) * 100, size(TheProbes));
    colorIdx = PERCENTRANK(range, x) / 100 * (size(colors, 1) - 1);
    if colorIdx == size(colors, 1) - 1; colorIdx = colorIdx - 1; end;
    color = [...
        (colors(floor(colorIdx) + 1, 1) + (colorIdx - floor(colorIdx)) * (colors(floor(colorIdx) + 2, 1) - colors(floor(colorIdx) + 1, 1))) / 255, ...
        (colors(floor(colorIdx) + 1, 2) + (colorIdx - floor(colorIdx)) * (colors(floor(colorIdx) + 2, 2) - colors(floor(colorIdx) + 1, 2))) / 255, ...
        (colors(floor(colorIdx) + 1, 3) + (colorIdx - floor(colorIdx)) * (colors(floor(colorIdx) + 2, 3) - colors(floor(colorIdx) + 1, 3))) / 255, ...
    ];
end

% cell2mat(arrayfun(@(x) [...
%             (colors(floor(x / maxx * (size(colors, 1) - 1)) + 1, 1) + (x / maxx * ...
%                 (size(colors, 1) - 1) - floor(x / maxx * (size(colors, 1) - 1))) * ...
%                 (colors(floor(x / maxx * (size(colors, 1) - 1)) + 2, 1) - colors(floor(x / maxx * (size(colors, 1) - 1)) + 1, 1))) / 255, ...
%             (colors(floor(x / maxx * (size(colors, 1) - 1)) + 1, 2) + (x / maxx * ...
%                 (size(colors, 1) - 1) - floor(x / maxx * (size(colors, 1) - 1))) * ...
%                 (colors(floor(x / maxx * (size(colors, 1) - 1)) + 2, 2) - colors(floor(x / maxx * (size(colors, 1) - 1)) + 1, 2))) / 255, ...
%             (colors(floor(x / maxx * (size(colors, 1) - 1)) + 1, 3) + (x / maxx * ...
%                 (size(colors, 1) - 1) - floor(x / maxx * (size(colors, 1) - 1))) * ...
%                 (colors(floor(x / maxx * (size(colors, 1) - 1)) + 2, 3) - colors(floor(x / maxx * (size(colors, 1) - 1)) + 1, 3))) / 255, ...
%             ],  debugCosts(:, 3), 'UniformOutput',false)), ...
