function rec = computeReconstruction(mat, level)
    diskf = cell(1, numel(level.scales));
    for r = 1:numel(diskf)
        diskf{r} = double(repmat(level.filters{r}, [1 1 size(level.result, 3)]));
    end

    rec = zeros(size(level.result));
    [yc, xc] = find(level.radius);
    for p = 1:numel(yc)
        x = xc(p); y = yc(p);
        r = round(level.radius(y, x));
        c = level.axis(y, x, :);
        rec((y-r):(y+r), (x-r):(x+r), :) = ...
            rec((y-r):(y+r), (x-r):(x+r), :) + bsxfun(@times, diskf{mat.scaleIdx(r)}, c);
    end
    rec = bsxfun(@rdivide, rec, level.depth);
    % Sometimes not all pixels are covered (e.g. at image corners
    % or after AMAT simplification), so we complete these NaN holes
    % using inpainting.
    if any(isnan(rec(:)))
        rec = reshape(inpaint_nans(rec), size(rec, 1), size(rec, 2), []);
        rec = min(1, max(0, rec));
    end
    level.reconstruction = rec;
end
