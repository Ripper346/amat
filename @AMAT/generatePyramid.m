function [pyramid] = generatePyramid(mat, img, minSize, filter, k)
% Generation of images' pyramid.
% img - result of imread on a image
% minSize - optional. Minimum size of pyramid top
% filter - optional. Name of the filter to use. Use name 'kernel' associated with k matrix of kernel or
%          see supported filters in getKernel function
% k - optioal. Kernel matrix or costant to use in filters

    if nargin <= 2
        % if minSize not defined assumed 1x1 top
        minSize = 1;
    end

    imgSize = size(img);
    minImgSize = min(imgSize(1:2));

    pyramidLevels = ceil(log2(minImgSize) - log2(minSize)) + 1;
    pyramid = cell(pyramidLevels, 1);
    pyramid{1} = im2double(img);

    % parse kernel to use
    if exist('filter', 'var') == 1 && strcmp(filter, 'kernel')
        kernel = k;
    elseif nargin < 3
        kernel = getKernel();
    elseif nargin < 4
        kernel = getKernel(filter);
    else
        kernel = getKernel(filter, k);
    end

    % generating pyramid
    for i = 2:pyramidLevels
        pyramid{i} = pyramidReduce(pyramid{i - 1}, 'kernel', kernel);
    end
end


function [y] = cubicFilter(x, k)
% Compute cubic filter coefficient for 2x decimation.
    if x >= 2
        y = 0.0;
    elseif x < 1
        y = 1 - (k + 3) * x * x + (k + 2) * x * x * abs(x);
    else % 1 <= x < 2
        y = k * (abs(x) - 1) * (abs(x) - 2) * (abs(x) - 2);
    end
    y = y / 2;
end


function [imgout] = pyramidReduce(img, filter, k)
% Reduce an image by half size.
% img - result of imread on a image
% filter - optional. Name of the filter to use. Use name 'kernel' associated with k matrix of kernel or
%          see supported filters in getKernel function
% k - optioal. Kernel matrix or costant to use in filters

    if exist('filter', 'var') == 1 && strcmp(filter, 'kernel')
        kernel = k;
    elseif nargin < 2
        kernel = getKernel();
    elseif nargin < 3
        kernel = getKernel(filter);
    else
        kernel = getKernel(filter, k);
    end

    img = im2double(img);
    sz = size(img);
    imgout = [];

    for p = 1:size(img, 3)
        img1 = img(:, :, p);
        imgFiltered = imfilter(img1, kernel, 'replicate', 'same');
        imgout(:, :, p) = imgFiltered(1:2:sz(1), 1:2:sz(2));
    end

end


function [kernel] = getKernel(filter, k)
% Select kernel.
% Numerical filters are from table 3.4 p149 of Computer Vision: Algorithms and Applications from Szeliski R., 2010
% filter - optional. Name of the filter to use. Use name 'gaussian' (default), 'binomial', 'cubic', 'windowed-sinc', 'QMF-9' or 'JPEG2000'
% k - optioal. Costant to use in gaussian (default 0.375) and cubic (default -1) filters

    kernel = [];
    if nargin < 1 || strcmp(filter, 'gaussian') || strcmp(filter, 'binomial')
        if nargin < 2
            k = 0.375;
        end
        ker1d = [0.25-k/2 0.25 k 0.25 0.25-k/2];
    elseif strcmp(filter, 'cubic')
        if nargin < 2
            k = -1;
        end
        ker1d = [cubicFilter(1.5, k) cubicFilter(1, k) cubicFilter(0.5, k) cubicFilter(0, k) ...
                 cubicFilter(0.5, k) cubicFilter(1, k) cubicFilter(1.5, k)];
    elseif strcmp(filter, 'windowed-sinc') || strcmp(filter, 'windowed sinc')
        ker1d = [0 -0.0153 0 0.2684 0.4939 0.2684 0 -0.0153 0];
    elseif strcmp(filter, 'QMF-9')
        ker1d = [0.0198 -0.0431 -0.0519 0.2932 0.5638 0.2932 -0.0519 -0.0431 0.0198];
    elseif strcmp(filter, 'JPEG2000')
        ker1d = [0.0267 -0.0169 -0.0782 0.2669 0.6029 0.2669 -0.0782 -0.0169 0.0267];
    else
        return;
    end
    kernel = kron(ker1d, ker1d');

end
