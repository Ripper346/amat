classdef AMAT < handle
    % TODO: add private flags for profiling
    % TODO: set properties to Transient, Private etc
    % TODO: should setCover() be private?
    properties
        scales   = 2:41
        ws       = 1e-4
        vistop   = 0
        shapeStr = 'disk'
        shape    = NaN
        axis
        branches
        cost
        depth
        encoding
        filters
        info
        input
        price
        radius
        reconstruction
        scaleIdx
        shapeId
        thetas  % in degrees
        BIG = 1e60
    end

    properties(Transient)
    end

    properties(Access=private)
        fig
        gif
        gifFilename
        covered
        diskCost
        diskCostPerPixel
        diskCostEffective
        numNewPixelsCovered
    end

    methods
        initialize(mat, img, varargin);
        mat = group(mat, marginFactor, colortol);
        mat = simplify(mat, method, param);
        setCover(mat);
        showImg(mat, xc, yc, rc, numRows, numCols, numScales);
        exportGif(mat, filename);

        costs = computeDiskCosts(mat);
        enc = computeDiskEncodings(mat, inputlab);

        costs = computeSquareCosts(mat);
        enc = computeSquareEncodings(mat, inputlab);
        
        function mat = AMAT(img, varargin)
            if nargin > 0
                % Optionally copy from input AMAT object
                if isa(img, 'AMAT')
                    mat = img.clone();
                    img = mat.input;
                end
                assert(ismatrix(img) || size(img, 3) == 3, 'Input image must be 2D or 3D array')
                mat.initialize(img, varargin{:});
                mat.compute();
            end
        end

        function new = clone(mat)
            new = AMAT();
            props = properties(mat);
            for i = 1:numel(props)
                new.(props{i}) = mat.(props{i});
            end
        end

        function mat = compute(mat)
            mat.computeEncodings();
            mat.computeCosts();
            profile on;
            mat.setCover();
            profile off;
            profile viewer;
        end

        function computeEncodings(mat)
            inputlab = rgb2labNormalized(mat.input);
            if isa(mat.shape, 'cell')
                encd = mat.shape{1}.computeEncodings(mat, inputlab);
                encs = mat.shape{2}.computeEncodings(mat, inputlab);
                mat.encoding = cat(5, encd, encs);
            elseif mat.shape ~= NaN
                mat.encoding = mat.shape.computeEncodings(mat, inputlab);
            else
                error('Invalid shape');
            end
        end

        function computeCosts(mat)
            if isa(mat.shape, 'cell')
                dcost = mat.shape{1}.computeCosts(mat);
                scost = mat.shape{2}.computeCosts(mat);
                mat.cost = cat(4, dcost, scost);
            elseif mat.shape ~= NaN
                mat.cost = mat.shape.computeCosts(mat);
            else
                error('Invalid shape');
            end
        end

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

        function seg = computeSegmentation(mat, minCoverage, minSegment)
            % TODO: maybe return segments as well
            % Coverage is a scalar controlling how much % of the image we want to cover
            if nargin < 2, minCoverage = 1; end
            if nargin < 3, minSegment = 0; end
            assert(isscalar(minCoverage) && minCoverage > 0 && minCoverage <= 1, ...
                'minCoverage must be a scalar in (0, 1]');
            assert(isscalar(minSegment), 'minSegment must be scalar');

            % Using this function assumes you have already grouped the medial points
            % into branches. A "refined" MAT (using function refineMAT()) is not
            % necessary, although it might lead to better results.
            if isempty(mat.branches)
                mat.group();
            end

            % Compute the depth contribution of each branch separately.
            [numRows, numCols] = size(mat.depth);
            numBranches = max(mat.branches(:));
            depthBranch = zeros(numRows, numCols, numBranches);
            for i = 1:numBranches
                depthBranch(:, :, i) = mat.computeDepth(mat.radius .* double(mat.branches == i));
            end

            % Segments are the areas covered by individual branches.
            segments = double(depthBranch > 0);

            % Sort by segment "importance", which is proportional to the area covered.
            % Because of potential grouping errors, significant areas of the image may
            % be covered by multiple segments, so we must take into account only the
            % *new* pixels covered by each segment, by using this hack:
            [~, idxSorted] = sort(sum(sum(segments)), 'descend');
            segments = segments(:, :, idxSorted);
            sumSeg = cumsum(segments, 3);
            segments = ((segments - sumSeg) == 0) & (sumSeg > 0);
            [areaSorted, idxSorted] = sort(sum(sum(segments)), 'descend');
            segments = segments(:, :, idxSorted);

            % Assign a different label to each segment. After sorting, the smaller the
            % label, the larger the respective segment.
            segments = bsxfun(@times, segments, reshape(1:numBranches, 1, 1, []));

            % Discard small segments
            if minSegment > 0
                if minSegment < 1                       % ratio of the min segment area over image area
                    small = areaSorted/(numRows*numCols) < minSegment;
                elseif minSegment < numRows*numCols     % #pixels of min segment
                    small = areaSorted < minSegment;
                else
                    error('minSegment is larger than the size of the image');
                end
                % If no segment satisfies the contraint, just use the largest segment
                if numel(small) == numel(areaSorted)
                    small(1) = false;
                end
                segments(:, :, small) = [];
                areaSorted(small) = [];
            end

            % Keep segments that cover at least (minCoverage*100) % of the image area.
            if minCoverage < 1
                cumAreaSorted = cumsum(areaSorted) / (numRows * numCols);
                numSegmentsKeep = find(cumAreaSorted >= minCoverage, 1);
                if isempty(numSegmentsKeep)
                    numSegmentsKeep = numel(cumAreaSorted);
                    warning('%.1f%% coverage achieved (<%.1f%%)', ...
                        cumAreaSorted(numSegmentsKeep) * 100, minCoverage * 100);
                end
                segments = segments(:, :, 1:numSegmentsKeep);
            end
            seg = max(segments, [], 3);
        end

        function setCoverMex(mat)
            % It's easier to compute CIE Lab zeros in MATLAB
            [numRows, numCols, numChannels, ~] = size(mat.encoding);
            zeroLabNormalized = rgb2labNormalized(zeros(numRows, numCols, numChannels));
            [mat.reconstruction, mat.axis, mat.radius, mat.depth, mat.price] = ...
                setCoverGreedy(mat, zeroLabNormalized);
            mat.axis = labNormalized2rgb(mat.axis);
            mat.computeReconstruction()
        end
        
    end % end of public methods

    methods (Static)
        function c = circle(r)
            r = double(r); % make sure r can take negative values
            [x, y] = meshgrid(-r:r, -r:r);
            c = double((x .^ 2 + y .^ 2 <= r ^ 2) & (x .^ 2 + y .^ 2 > (r - 1) ^ 2));
        end
    end
end
