classdef Square < handle
    properties
    end

    properties(Access=private)
    end

    methods
        costs = computeCosts(sq, mat, scales);
        enc = computeEncodings(sq, mat, inputlab);

        function sq = Square()
        end

        function filters = getFilters(sq, mat, numScales)
            numShapes = 1 + numel(mat.thetas);
            filters = cell(numShapes, numScales);
            for i = 1:numScales
                filters{1, i} = Square.get(mat.scales(i));
            end
        end

        function area = getArea(sq, x, y, xc, yc, rc)
            area = abs(x - xc) <= rc & abs(y - yc) <= rc;
        end
    end

    methods (Static)
        function s = get(r, theta)
            s = ones(2 * r + 1);
            if nargin > 1
                s = imrotate(s, theta);
            end
        end
    end
end
