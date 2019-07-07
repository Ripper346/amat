function filters = initializeFilters(mat, scales)
    if nargin < 2
        scales = mat.scales;
    end
    if isa(mat.shape, 'cell')
        filters = cell(numel(mat.shape));
        for sh = 1:numel(mat.shape)
            filters{sh} = mat.shape(sh).getFilters(mat, numel(scales));
        end
    elseif mat.shape ~= NaN
        filters = mat.shape.getFilters(mat, numel(scales));
    else
        error('Invalid filter shape');
    end
    % squares with rotations
    k = size(filters, 1); % dimension corresponding to square
    for d = 1:numel(mat.thetas)
        for i = 1:numScales
            filters{k + d, i} = Square.get(scales(i), mat.thetas(d));
        end
    end
end
