function initialize(mat, img, varargin)
    defaults = {'scales', 2:41, ...
                'ws', 1e-4, ...
                'vistop', 0, ...
                'shape', 'disk', ...
                'thetas', [], ...
                'gif', 0, ...
                'log', 0, ...
                'followNeighbors', 0
                };
    opts = parseVarargin(defaults, varargin);
    if isscalar(opts('scales'))
        mat.scales = 2:opts('scales');
    else
        mat.scales = opts('scales');
    end
    mat.ws = opts('ws');
    mat.vistop = opts('vistop');
    mat.shapeStr = opts('shape');
    mat.thetas = opts('thetas');
    mat.logProgress = opts('log');
    mat.gif = opts('gif');
    mat.followNeighbors = opts('followNeighbors');
    mat.input = im2double(img);
    mat.scaleIdx = containers.Map(mat.scales, 1:numel(mat.scales));
    initializeProgresses(mat);
    initializeShape(mat);
    initializeFilters(mat);
end

function initializeFilters(mat)
    numScales = numel(mat.scales);
    if isa(mat.shape, 'cell')
        for sh = 1:numel(mat.shapes)
            mat.filters{sh} = mat.shapes(sh).getFilters(mat, numScales);
        end
    elseif mat.shape ~= NaN
        mat.filters = mat.shape.getFilters(mat, numScales);
    else
        error('Invalid filter shape');
    end
    % squares with rotations
    k = size(mat.filters, 1); % dimension corresponding to square
    for d = 1:numel(mat.thetas)
        for i = 1:numScales
            mat.filters{k + d, i} = Square.get(mat.scales(i), mat.thetas(d));
        end
    end
end

function initializeShape(mat)
    switch mat.shapeStr
        case 'disk'
            mat.shape = Disk();
        case 'square'
            mat.shape = Square();
        case 'mixed'
            mat.shape = {Disk() Square()};
        otherwise
            error('Invalid shape');
    end
end

function initializeProgresses(mat)
    if mat.vistop > 0
        mat.fig = figure('Name', 'Progress', 'rend', 'painters', 'pos', [10 10 900 600]);
        mat.progFilename = strcat('progress_', datestr(datetime, 'yyyy-mm-dd_HH.MM.SS'));
    end
end
