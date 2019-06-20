function initializeFigure(mat, forced)
    if mat.vistop > 0 || exist('forced', 'var') == 1
        if mat.vistop > 0
            name = 'Progress';
        else
            name = 'Results';
        end
        mat.fig = figure('Name', name, 'rend', 'painters', 'pos', [10 10 900 600]);
        mat.progFilename = strcat('progress_', datestr(datetime, 'yyyy-mm-dd_HH.MM.SS'));
    end
end
