function depth = computeDepth(mat, rad)
    % rad: double, HxW radius array
    if nargin < 2
        rad = mat.radius;
    end
    depth = zeros(size(rad));
    [yc, xc] = find(rad);
    for p = 1:numel(yc)
        x = xc(p);
        y = yc(p);
        r = round(rad(y, x));
        depth((y - r):(y + r), (x - r):(x + r)) = ...
            depth((y - r):(y + r), (x - r):(x + r)) + mat.filters{mat.scaleIdx(r)};
    end
    if nargout == 0
        mat.depth = depth;
    end
end
