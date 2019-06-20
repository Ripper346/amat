function area = getPointsCovered(mat, xc, yc, rc)
    if isa(mat.shape, 'cell')
        error('Mix of shapes not supported yet');
    elseif mat.shape ~= NaN
        area = mat.shape.getArea(mat.x, mat.y, xc, yc, rc);
    else
        error('Shape is not supported');
    end
end
