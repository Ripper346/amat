function logNeighborhood(mat, xc, yc)
    f = fopen(strcat(mat.progFilename, '_log.csv'), 'a');
    fprintf(f,'%d,%s\n', ...
        nnz(mat.covered), strjoin(getNeighborhoodValues(mat, xc, yc), ','));
    fclose(f);
end

function neighbor = getNeighborhoodValues(mat, xc, yc)
    x = xc - 1;
    y = yc - 1;
    k = 2;
    center = k + 4;
    neighbor = strings(9);
    for row = x:x + 2
        for col = y:y + 2
            % on top central (current) position
            if k == center
                index = 1;
            else
                index = k;
                k = k + 1;
            end
            try
                [minCost, r] = min(mat.diskCostEffective(x, y, :));
                neighbor(index) = sprintf('%d,%d,%d,%12.20f', x, y, r, minCost);
            catch ME
                k = k - 1;
                center = center - 1;
            end
        end
    end
end
