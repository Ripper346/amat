function initialize(mat, img, varargin)
    defaults = {'scales', 2:41, ...
                'ws', 1e-4, ...
                'vistop', 0, ...
                'shape', 'disk', ...
                'thetas', []
                };
    opts = parseVarargin(defaults, varargin);
    if isscalar(opts('scales'))
        mat.scales = 2:opts('scales');
    else
        mat.scales = opts('scales');
    end
    mat.ws = opts('ws');
    mat.vistop = opts('vistop');
    mat.shape = opts('shape');
    mat.thetas = opts('thetas');
    mat.input = im2double(img);
    mat.scaleIdx = containers.Map(mat.scales, 1:numel(mat.scales));
    initializeFilters(mat);
end

function initializeFilters(mat)
    numScales = numel(mat.scales);
    switch mat.shape
        case 'disk'
            mat.filters = cell(1, numScales);
            for i = 1:numScales
                mat.filters{i} = AMAT.disk(mat.scales(i));
            end
        case 'square'
            numShapes = 1 + numel(mat.thetas);
            mat.filters = cell(numShapes, numScales);
            for i = 1:numScales
                mat.filters{1, i} = AMAT.square(mat.scales(i));
            end
        case 'mixed'
            numShapes = 2 + numel(mat.thetas);
            mat.filters = cell(numShapes, numScales);

            % disks
            for i = 1:numScales
                mat.filters{1, i} = AMAT.disk(mat.scales(i));
            end
            % squares without rotation
            for i = 1:numScales
                mat.filters{2, i} = AMAT.square(mat.scales(i));
            end
        otherwise, error('Invalid filter shape');
    end
    % squares with rotations
    k = size(mat.filters, 1); % dimension corresponding to square
    for d = 1:numel(mat.thetas)
        for i = 1:numScales
            mat.filters{k + d, i} = AMAT.square(mat.scales(i), mat.thetas(d));
        end
    end
end
