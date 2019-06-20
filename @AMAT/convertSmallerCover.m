function convertSmallerCover(mat, smallerLevel)
% Convert axis and radius matrices to one times bigger level
    mat.radius = zeros(mat.numRows, mat.numCols);
    mat.axis = rgb2labNormalized(zeros(mat.numRows, mat.numCols, mat.numChannels));
    for y = 1:smallerLevel.numRows
        for x = 1:smallerLevel.numCols
            for yb = 1:2
                for xb = 1:2
                    if mat.numCols > (y - 1) * 2 + yb && mat.numRows > (x - 1) * 2 + xb
                        % axis
                        mat.axis((y - 1) * 2 + yb, (x - 1) * 2 + xb, :) = smallerLevel.axis(y, x, :);

                        % radius
                        rb = smallerLevel.radius(y, x) * 2;
                        % if rb > 1 && ...
                        %     % TODO calc costs
                        %     mat.cost((y - 1) * 2 + yb, (x - 1) * 2 + xb, rb) > ...
                        %     mat.cost((y - 1) * 2 + yb, (x - 1) * 2 + xb, rb - 1)

                        %     mat.radius((y - 1) * 2 + yb, (x - 1) * 2 + xb) = rb - 1;
                        % else
                            mat.radius((y - 1) * 2 + yb, (x - 1) * 2 + xb) = rb;
                        % end
                    end
                end
            end
        end
    end
end
