function initialize(mat, img, varargin)
    defaults = {'scales', 2:41, ...
                'ws', 1e-4, ...
                'vistop', 0, ...
                'shape', 'disk', ...
                'thetas', [], ...
                'gif', 0, ...
                'log', 0, ...
                'followNeighbors', 0, ...
                'topNeighSelection', 15, ...
                'pyramid', {}, ...
                'debugLevelConversion', 0, ...
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
    mat.topNeighSelection = opts('topNeighSelection');
    mat.usePyramid = 0;
    if isscalar(opts('pyramid'))
        mat.usePyramid = 1;
        mat.pyramidOpts = {};
    elseif size(opts('pyramid'), 1)
        mat.usePyramid = 1;
        mat.pyramidOpts = opts('pyramid');
    end
    mat.debugLevelConversion = opts('debugLevelConversion');
    mat.input = im2double(img);
    mat.scaleIdx = containers.Map(mat.scales, 1:numel(mat.scales));
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
