function area = getPointsCovered(mat, x, y, xc, yc, rc)
    if isa(mat.shape, 'cell')
        error('Mix of shapes not supported yet');
    elseif mat.shape ~= NaN
        area = mat.shape.getArea(x, y, xc, yc, mat.scales(rc));
    else
        error('Shape is not supported');
    end
end
