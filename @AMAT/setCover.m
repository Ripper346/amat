function setCover(mat, nextLevel)
    % -------------------------------------------------------------
    % Greedy approximation of the weighted set cover problem.
    % -------------------------------------------------------------
    % - Disk cost: cost incurred by selecting ena r-disk, centered at (i, j).
    % - numNewPixelsCovered: number of NEW pixels covered by a selected disk.
    % - Cost per pixel: diskCost / numNewPixelsCovered.
    % - Disk cost effective: adjusted normalized cost: diskCostPerPixel + scaleTerm
    % where scaleTerm is a term that favors selecting disks of larger
    % radii. Such a term is necessary, to resolve selection of disks in
    % the case where diskCost is zero for more than on radii.
    % NOTE: Even when using other types of shapes too (e.g.
    % squares), we still refer to them as "disks".
    %
    % TODO: is there a way to first sort scores and then pick the next one in
    % queue, to avoid min(diskCostEffective(:)) in each iteration?

    % Initializations
    mat.initializeFigure();
    zeroLabNormalized = rgb2labNormalized(zeros(mat.numRows, mat.numCols, mat.numChannels));
    mat.input = reshape(mat.img, mat.numRows * mat.numCols, mat.numChannels);
    mat.reconstruction = reshape(zeroLabNormalized, mat.numRows * mat.numCols, mat.numChannels);
    if isempty(mat.axis)
        mat.axis = zeroLabNormalized;
    end
    if isempty(mat.radius)
        mat.radius = zeros(mat.numRows, mat.numCols);
    end
    mat.price = zeros(mat.numRows, mat.numCols); % error contributed by each point
    % Print remaining pixels to be covered in these points
    printBreakPoints = floor((4:-1:1) .* (mat.numRows * mat.numCols / 5));
    prepareNextLevel = nargin > 1;
    if prepareNextLevel
        [mat.nextMinCost, mat.nextIdxMinCost] = min(nextLevel.diskCostEffective(:));
    else
        mat.nextMinCost = 1e-60;
    end

    % GREEDY ALGORITHM STARTS HERE --------------------------------
    fprintf('Pixels remaining: ');
    while ~all(mat.covered(:))
        jumpLoop = false;
        % Get disk with min cost
        if mat.followNeighbors <= 1
            [minCost, idxMinCost] = min(mat.diskCostEffective(:));
            [yc, xc, rc] = ind2sub(size(mat.diskCostEffective), idxMinCost);
            if mat.followNeighbors == 1
                mat.followNeighbors = 2;
            end
        end
        % if minCost == mat.BIG
        %     warning('All pixels cycled.');
        %     break;
        % end
        % if prepareNextLevel
        %     minSamePointNL = nextLevel.diskCostEffective((yc - 1) * 2 + 1:(yc - 1) * 2 + 2, (xc - 1) * 2 + 1:(xc - 1) * 2 + 2, :);
            %if minCost > min(minSamePointNL(:)) %mat.nextMinCost
            %    mat.diskCost(yc, xc, :) = mat.BIG;
            %    mat.diskCostEffective(yc, xc, :) = mat.BIG;
            %    jumpLoop = true;
            %end
        % end

        if isinf(minCost)
            warning('Stopping: selected disk has infinite cost.');
            break;
        end

        areaCovered = mat.getPointsCovered(xc, yc, mat.scales(rc));
        newPixelsCovered = areaCovered & ~mat.covered;
        if ~any(newPixelsCovered(:))
            %%% BLOCKING
%             if mat.prevLevelCovered
%                 [coveredCount, ~] = hist(mat.prevLevelCovered(:) + areaCovered(:), [0, 1, 2]);
%                 [currentCoveredCount, ~] = hist(areaCovered(:), [0, 1]);
%                 if coveredCount(2) - currentCoveredCount(1) == 0
%                     jumpLoop = true;
%                     mat.diskCost(yc, xc, :) = mat.BIG;
%                     mat.diskCostEffective(yc, xc, :) = mat.BIG;
%                 else
%                     warning('Stopping: selected disk covers zero (0) new pixels.');
%                     break;
%                 end
            %else
                warning('Stopping: selected disk covers zero (0) new pixels.');
                break;
            %end
        end


        if mat.logProgress
            mat.logNeighborhood(xc, yc);
        end
        if jumpLoop
            continue;
        end
        if prepareNextLevel
            mat.update(minCost, xc, yc, rc, newPixelsCovered, nextLevel);
        else
            mat.update(minCost, xc, yc, rc, newPixelsCovered);
        end
        if mat.logProgress
            mat.logNeighborhood(xc, yc);
        end

        % Visualize progress
        if mat.vistop
            mat.showImg(xc, yc, rc);
        end
        if ~isempty(printBreakPoints) && nnz(~mat.covered) < printBreakPoints(1)
            fprintf('%d...', printBreakPoints(1));
            printBreakPoints(1) = [];
        end
        if mat.followNeighbors > 0
            [minCost, idxMinCost, yc, xc, rc] = mat.coverNeighbors(xc, yc, x, y, 0, numRows, numCols, numScales);
        end
    end
    fprintf('\n');
    mat.input = reshape(mat.input, mat.numRows, mat.numCols, mat.numChannels);
    % mat.axis = labNormalized2rgb(mat.axis);
end
