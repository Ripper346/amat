function logNeighborhood(mat, xc, yc)
    f = fopen(strcat(mat.progFilename, '_log.csv'), 'a');
    fprintf(f,'%d,%s\n', ...
        nnz(mat.covered), strjoin(getNeighborhoodValues(mat, xc, yc), ','));
    fclose(f);
end

function neighbor = getNeighborhoodValues(mat, xc, yc)
    k = 2;
    center = k + 4;
    neighbor = strings(9);
    for col = yc - 1:yc + 1
        for row = xc - 1:xc + 1
            % on top central (current) position
            if k == center
                index = 1;
                center = -1;
            else
                index = k;
                k = k + 1;
            end
            try
                [minCost, r] = min(mat.diskCostEffective(col, row, :));
                lesser_count = sum(mat.diskCostEffective(:) < minCost);
                equal_count = sum(mat.diskCostEffective(:) == minCost);
                greater_count = sum(mat.diskCostEffective(:) > minCost);
                max_count = sum(mat.diskCostEffective(:) == mat.BIG);
                neighbor(index) = sprintf('%d,%d,%d,%60.60f,%d,%d,%d,%d', row, col, r, minCost, lesser_count, equal_count, greater_count, max_count);
            catch
                % possibly out of bounds
                k = k - 1;
                center = center - 1;
            end
        end
    end
end
