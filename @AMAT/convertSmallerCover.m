function convertSmallerCover(mat, smallerLevel, idx)
% Convert axis and radius matrices to one times bigger level
    if mat.scales == 0
        % no scales to cover, copy plain the solution
        convertToEmptyLevel(mat, smallerLevel);
    else
        convertToWorkerLevel(mat, smallerLevel, idx);
    end
end

function convertToEmptyLevel(mat, smallerLevel)
    mat.radius = zeros(mat.numRows, mat.numCols);
    mat.axis = rgb2labNormalized(zeros(mat.numRows, mat.numCols, mat.numChannels));
    for y = 1:smallerLevel.numRows
        for x = 1:smallerLevel.numCols
            for yb = 1:2
                for xb = 1:2
                    yc = (y - 1) * 2 + yb;
                    xc = (x - 1) * 2 + xb;
                    if mat.numCols > xc && mat.numRows > yc
                        rb = smallerLevel.radius(y, x) * 2;
                        if rb > 1
                            mat.axis(yc, xc, :) = smallerLevel.axis(y, x, :);
                            mat.radius(yc, xc) = rb;
                        end
                    end
                end
            end
        end
    end
end

function convertToWorkerLevel(mat, smallerLevel, idx)
    scales = getBiggerScales(smallerLevel, idx);
    [numNewPixelsCoveredBig, diskCostBig, diskCostPerPixelBig, diskCostEffBig, filters] = getBiggerCosts(mat, scales);
    scales = horzcat(mat.scales, scales);
    scalesMax = max(scales);
    diskCostEffBig = cat(3, mat.diskCostEffective, diskCostEffBig);
    diskCostEffBigSorted = unique(diskCostEffBig(:), 'sorted');
    diskCostEffBigSorted = containers.Map(diskCostEffBigSorted, 1:numel(diskCostEffBigSorted));
    mat.prevLevelCovered = zeros(mat.numRows, mat.numCols);
    mat.radius = zeros(mat.numRows, mat.numCols);
    mat.axis = rgb2labNormalized(zeros(mat.numRows, mat.numCols, mat.numChannels));
    if mat.origin.debugLevelConversion
        debugCosts = [];
        file = fopen(sprintf('ranking_%d.csv', mat.numRows), 'w');
    end
    for y = 1:smallerLevel.numRows
        for x = 1:smallerLevel.numCols
            for yb = 1:2
                for xb = 1:2
                    yc = (y - 1) * 2 + yb;
                    xc = (x - 1) * 2 + xb;
                    if mat.numCols > xc && mat.numRows > yc
                        rb = smallerLevel.radius(y, x) * 2;
                        if rb > 1
                            [pointMinCost, rc] = min(diskCostEffBig(yc, xc, :));
                            filt = diskCostEffBigSorted(pointMinCost) * mat.numRows * mat.numCols * (scalesMax - scales(rc) + 1) / (double(diskCostEffBigSorted.Count) * double(diskCostEffBigSorted.Count) * scalesMax);
                            if mat.origin.debugLevelConversion
                                fprintf(file, '%d, %d, %d, %d, %d, %d, %d, %.20f\n', yc, xc, scales(rc), pointMinCost, ...
                                        scalesMax, diskCostEffBigSorted(pointMinCost), diskCostEffBigSorted.Count, filt);
                                debugCosts = [debugCosts; [yc, xc, filt, scales(rc)]];
                            end
                            if filt < 0.05
                                mat.axis(yc, xc, :) = smallerLevel.axis(y, x, :);
                                mat.radius(yc, xc) = scales(rc);
                                areaCovered = mat.getPointsCovered(yc, xc, rb);
                                newPixelsCovered = areaCovered & ~mat.covered;
                                mat.covered(newPixelsCovered) = true;
                                try
                                    if rc <= mat.numScales
                                        mat.price(newPixelsCovered) = pointMinCost / mat.numNewPixelsCovered(yc, xc, rc);
                                    else
                                        mat.price(newPixelsCovered) = pointMinCost / numNewPixelsCoveredBig(yc, xc, rc - mat.numScales);
                                    end
                                catch
                                    continue;
                                end
                                mat.updateCosts(xc, yc, newPixelsCovered);
                            end
                        end
                    end
                end
            end
        end
    end
    if mat.origin.debugLevelConversion
        fclose(file);
        showDebug(mat, debugCosts);
    end
end

function scales = getBiggerScales(mat, idx)
    scales = arrayfun(@(x) round(x / 2 ^ (idx - 1)), mat.origin.scales(mat.origin.scales > max(mat.scales) * 2 ^ (idx - 1) + 1), 'UniformOutput', false);
    scales = sort(unique(horzcat(scales{:})));
end

function [numNewPixelsCovered, diskCost, diskCostPerPixel, diskCostEffective, filters] = getBiggerCosts(mat, scales)
    filters = mat.initializeFilters(scales);
    encodings = mat.computeEncodings(scales);
    [numNewPixelsCovered, diskCost, diskCostPerPixel, diskCostEffective] = mat.calculateDiskCosts(scales, filters, encodings);
end

function showDebug(mat, debugCosts)
    figure('Name', sprintf('%dx%d costs', mat.numRows, mat.numCols));
    gray = rgb2hsv(mat.origin.input);
    gray(:,:,2) = gray(:,:,2) * 0;
    image('CData', hsv2rgb(gray), 'XData', [1 mat.numCols + 1], 'Ydata', [1 mat.numRows + 1]);
    hold on;
    colors = [0 0 255; 0 176 80; 255 255 0; 255 0 0; 117 76 36];
    ylim([0 mat.numRows]);
    xlim([0 mat.numCols]);
    grid = yticks;
    for i = 1:numel(grid)
        x = [0 mat.numCols];
        y = [grid(i) grid(i)];
        plot(x,y,'Color','#e6e6e6');
    end
    grid = xticks;
    for i = 1:numel(grid)
        y = [0 mat.numRows];
        x = [grid(i) grid(i)];
        plot(x,y,'Color','#e6e6e6');
    end
    scatter(debugCosts(:, 2), debugCosts(:, 1), ...
        arrayfun(@(x) x/max(debugCosts(:, 4)) * 20, debugCosts(:, 4)), ...
        cell2mat(arrayfun(@(x) getColor(x, debugCosts(:, 3), colors),  debugCosts(:, 3), 'UniformOutput',false)), ...
        'filled');
    set(gca,'XAxisLocation','top','YAxisLocation','left','Ydir','reverse');
    pbaspect([1 1 1]);
    hold off;
end

function color = getColor(x, range, colors)
    PERCENTRANK = @(YourArray, TheProbes) reshape(mean(bsxfun(@le, YourArray(:), TheProbes(:).')) * 100, size(TheProbes));
    colorIdx = PERCENTRANK(range, x) / 100 * (size(colors, 1) - 1);
    if colorIdx == size(colors, 1) - 1; colorIdx = colorIdx - 1; end
    color = [...
        (colors(floor(colorIdx) + 1, 1) + (colorIdx - floor(colorIdx)) * (colors(floor(colorIdx) + 2, 1) - colors(floor(colorIdx) + 1, 1))) / 255, ...
        (colors(floor(colorIdx) + 1, 2) + (colorIdx - floor(colorIdx)) * (colors(floor(colorIdx) + 2, 2) - colors(floor(colorIdx) + 1, 2))) / 255, ...
        (colors(floor(colorIdx) + 1, 3) + (colorIdx - floor(colorIdx)) * (colors(floor(colorIdx) + 2, 3) - colors(floor(colorIdx) + 1, 3))) / 255, ...
    ];
end
