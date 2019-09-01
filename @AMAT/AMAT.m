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
        img
        result
        numScales
        numRows
        numCols
        numChannels
        levels
        covered
        diskCostEffective
        prevLevelCovered
        originScales
        neighbors = []
        currentNeighbor = 1
        useGpu
    end

    properties(Transient)
    end

    properties(Access=private)
        followNeighbors
        fig
        gif
        logProgress
        progFilename
        diskCost
        diskCostPerPixel
        numNewPixelsCovered
        usePyramid
        pyramidOpts
        x
        y
        isLevel = 0
        nextMinCost
        nextIdxMinCost
        debugLevelConversion = 0
        origin
        printBreakPoints
    end

    methods
        [numNewPixelsCovered, diskCost, diskCostPerPixel, diskCostEffective] = calculateDiskCosts(mat, scales, filters, encoding);
        enc = computeEncodings(ds, mat, inputlab, scales)
        filters = initializeFilters(mat, scales);
        mat = compute(mat);
        depth = computeDepth(mat, rad);
        rec = computeReconstruction(mat);
        seg = computeSegmentation(mat, minCoverage, minSegment);
        convertSmallerCover(mat, smallerLevel, idx);
        coverNeighbors(mat, xc, yc, rc);
        exportGif(mat, filename);
        pyramid = generatePyramid(mat, img, minSize, filter, k);
        area = getPointsCovered(mat, xc, yc, rc)
        mat = group(mat, marginFactor, colortol);
        initialize(mat, img, varargin);
        logNeighborhood(mat, xc, yc);
        setCover(mat);
        setCoverParams(mat, img, scales);
        showImg(mat, xc, yc, rc);
        mat = simplify(mat, method, param);
        update(mat, minCost, xc, yc, rc, newPixelsCovered);
        updateCosts(mat, xc, yc, newPixelsCovered);

        function mat = AMAT(origin, varargin)
            if nargin > 0
                % Optionally copy from input AMAT object
                if isa(origin, 'AMAT')
                    mat.ws = origin.ws;
                    mat.shape = origin.shape;
                    mat.thetas = origin.thetas;
                    mat.vistop = origin.vistop;
                    mat.scaleIdx = origin.scaleIdx;
                    mat.isLevel = 1;
                    mat.logProgress = origin.logProgress;
                    mat.gif = origin.gif;
                    mat.followNeighbors = origin.followNeighbors;
                    mat.useGpu = origin.useGpu;
                    mat.origin = origin;
                else
                    assert(ismatrix(origin) || size(origin, 3) == 3, 'Input image must be 2D or 3D array')
                    mat.initialize(origin, varargin{:});
                    mat.compute();
                end
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

    methods (Access=private)
        initializeFigure(mat, forced);
    end

    methods (Static)
        function c = circle(r)
            r = double(r); % make sure r can take negative values
            [x, y] = meshgrid(-r:r, -r:r);
            c = double((x .^ 2 + y .^ 2 <= r ^ 2) & (x .^ 2 + y .^ 2 > (r - 1) ^ 2));
        end

        function help()
            % Helper how to use the class
            fprintf("Input arguments of the constructor. All are optional:" ...
            + "\n'scales' - [array]{2:41}\n     range of diameters" ...
            + "\n'ws' - [double]{1e-4}\n     weight to apply to input scales on cost computation" ...
            + "\n'vistop' - [int]{0}\n     show progess with highest scoring shapes" ...
            + "\n'shape' - [disk|square|mixed]{'disk'}\n     set covering object" ...
            + "\n'thetas' - [array]{[]}\n     set of square rotations" ...
            + "\n'gif' - [0|1]{0}\n     export the covering process as gif. Works only with vistop argument" ...
            + "\n'log' - [0|1]{0}\n     log process in csv files" ...
            + "\n'followNeighbors' - [0|1]{0}\n     use the system of neighbor similarity alongside the classic method" ...
            + "\n'pyramid' - [1|array]{{}}\n     use pyramid reduction system. If an array is provided" ...
            + "\n'debugLevelConversion' - [0|1]{0}\n     log data from level conversion when using pyramid reduction" ...
            + "\n'gpu' - [0|1]{0}\n     use gpu structures in the process" ...
            + "\n");
        end
    end
end
