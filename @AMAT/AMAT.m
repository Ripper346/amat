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
        encoding = {}
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
        logProgress
        progFilename
        covered
        diskCost
        diskCostPerPixel
        diskCostEffective
        numNewPixelsCovered
        usePyramid
        pyramidOpts
    end

    methods
        initialize(mat, img, varargin);
        mat = group(mat, marginFactor, colortol);
        mat = simplify(mat, method, param);
        mat = compute(mat);
        rec = computeReconstruction(mat);
        seg = computeSegmentation(mat, minCoverage, minSegment);
        depth = computeDepth(mat, rad);
        setCover(mat);
        update(mat, minCost, areaCovered, xc, yc, rc, newPixelsCovered, numRows, numCols, numScales);
        showImg(mat, xc, yc, rc, numRows, numCols, numScales);
        exportGif(mat, filename);
        logNeighborhood(mat, xc, yc);
        pyramid = gen_pyramid(mat, img, min_size, filter, k);

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
