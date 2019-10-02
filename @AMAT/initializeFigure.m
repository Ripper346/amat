function initializeFigure(mat, forced)
    if mat.vistop > 0 || exist('forced', 'var') == 1
        if mat.vistop > 0
            name = 'Progress';
        elseif mat.isLevel == 1
            name = sprintf('Results %dx%d', mat.numRows, mat.numCols);
        else
            name = 'Results';
        end
        mat.fig = figure('Name', name, 'rend', 'painters', 'pos', [10 10 900 600]);
        drawnow;
        mat.progFilename = strcat('progress_', datestr(datetime, 'yyyy-mm-dd_HH.MM.SS'));
    end
end
