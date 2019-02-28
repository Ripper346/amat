function initialize(mat, img, varargin)
    defaults = {'scales', 2:41, ...
                'ws', 1e-4, ...
                'vistop', 0, ...
                'shape', 'disk', ...
                'thetas', [], ...
                'gif', 0, ...
                'log', 0, ...,
                'pyramid', {}
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
    mat.usePyramid = 0;
    if isscalar(opts('pyramid'))
        mat.usePyramid = 1;
        mat.pyramidOpts = {};
    elseif size(opts('pyramid'), 1)
        mat.usePyramid = 1;
        mat.pyramidOpts = opts('pyramid');
    end
    mat.input = im2double(img);
    mat.scaleIdx = containers.Map(mat.scales, 1:numel(mat.scales));
    initializeProgresses(mat);
    initializeShape(mat);
end

function initializeShape(mat)
    switch mat.shapeStr
        case 'disk'
            mat.shape = Disk();
        case 'square'
            mat.shape = Square();
        case 'mixed'
            mat.shape = {Disk(), Square()};
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
