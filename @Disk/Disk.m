classdef Disk < handle
    properties
    end

    properties(Access=private)
    end

    methods
        costs = computeCosts(ds, mat, levelIndex);
        enc = computeEncodings(ds, level, inputlab);

        function ds = Disk()
        end

        function filters = getFilters(ds, mat, numScales)
            filters = cell(1, numScales);
            for i = 1:numScales
                filters{i} = Disk.get(mat.scales(i));
            end
        end

        function area = getArea(ds, x, y, xc, yc, rc)
            area = (x - xc) .^ 2 + (y - yc) .^ 2 <= rc ^ 2;
        end
    end

    methods (Static)
        function d = get(r)
            r = double(r); % make sure r can take negative values
            [x, y] = meshgrid(-r:r, -r:r);
            d = double(x .^ 2 + y .^ 2 <= r ^ 2);
        end
    end
end
