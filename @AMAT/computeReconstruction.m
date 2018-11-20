function rec = computeReconstruction(mat)
    diskf = cell(1, numel(mat.scales));
    for r = 1:numel(diskf)
        diskf{r} = double(repmat(mat.filters{r}, [1 1 size(mat.input, 3)]));
    end

    rec = zeros(size(mat.input));
    [yc, xc] = find(mat.radius);
    for p = 1:numel(yc)
        x = xc(p); y = yc(p);
        r = round(mat.radius(y, x));
        c = mat.axis(y, x, :);
        rec((y-r):(y+r), (x-r):(x+r), :) = ...
            rec((y-r):(y+r), (x-r):(x+r), :) + bsxfun(@times, diskf{mat.scaleIdx(r)}, c);
    end
    rec = bsxfun(@rdivide, rec, mat.depth);
    % Sometimes not all pixels are covered (e.g. at image corners
    % or after AMAT simplification), so we complete these NaN holes
    % using inpainting.
    if any(isnan(rec(:)))
        rec = reshape(inpaint_nans(rec), size(rec, 1), size(rec, 2), []);
        rec = min(1, max(0, rec));
    end
    mat.reconstruction = rec;
end
