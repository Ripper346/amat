function convertSmallerCover(mat, smallerLevel)
% Convert axis and radius matrices to one times bigger level
    % mat.prevLevel = smallerLevel;
    scales = getBiggerScales(smallerLevel);
    [numNewPixelsCoveredBig, diskCostBig, diskCostPerPixelBig, diskCostEffectiveBig] = getBiggerCosts(smallerLevel, scales);
    mat.prevLevelCovered = zeros(mat.numRows, mat.numCols);
    mat.radius = zeros(mat.numRows, mat.numCols);
    mat.axis = rgb2labNormalized(zeros(mat.numRows, mat.numCols, mat.numChannels));
    for y = 1:smallerLevel.numRows
        for x = 1:smallerLevel.numCols
            for yb = 1:2
                for xb = 1:2
                    if mat.numCols > (y - 1) * 2 + yb && mat.numRows > (x - 1) * 2 + xb
                        % axis
                        mat.axis((y - 1) * 2 + yb, (x - 1) * 2 + xb, :) = smallerLevel.axis(y, x, :);

                        % radius
                        rb = smallerLevel.radius(y, x) * 2;
                        % if rb > 1 && ...
                        %     % TODO calc costs
                        %     diskCostBig((y - 1) * 2 + yb, (x - 1) * 2 + xb, rb) > ...
                        %     diskCostBig((y - 1) * 2 + yb, (x - 1) * 2 + xb, rb - 1)

                        %     mat.radius((y - 1) * 2 + yb, (x - 1) * 2 + xb) = rb - 1;
                        % else
                            mat.radius((y - 1) * 2 + yb, (x - 1) * 2 + xb) = rb;
                        % end
                        mat.covered((y - 1) * 2 + yb, (x - 1) * 2 + xb, :) = smallerLevel.covered(y, x, :);
                        mat.prevLevelCovered((y - 1) * 2 + yb, (x - 1) * 2 + xb, :) = smallerLevel.covered(y, x, :);
                    end
                end
            end
        end
    end
end

function scales = getBiggerScales(mat)
    scales = arrayfun(@(x) [x * 2, x * 2 - 1], unique(mat.radius(mat.radius > 0)), 'UniformOutput', false);
    scales = sort(horzcat(scales{:}));
end

function [numNewPixelsCovered, diskCost, diskCostPerPixel, diskCostEffective] = getBiggerCosts(mat, scales)
    filters = mat.initializeFilters(scales);
    encodings = mat.computeEncodings(scales);
    [numNewPixelsCovered, diskCost, diskCostPerPixel, diskCostEffective] = mat.calculateDiskCosts(scales, filters, encodings);
end
