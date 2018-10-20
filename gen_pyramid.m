function [pyramid] = gen_pyramid(img, min_size)
% Generation of images' pyramid.
% img - result of imread on a image
% min_size - minimum size of pyramid top

    if nargin < 2
        % if min_size not defined assumed 1x1 top
        min_size = 1;
    end
    
    img_size = size(img);
    min_img_size = min(img_size(1:2));
    
    pyramid_levels = ceil(log2(min_img_size) - log2(min_size)) + 1;
    pyramid = cell(pyramid_levels, 1);
    pyramid{1} = im2double(img);
    
    for i = 2:pyramid_levels
        pyramid{i} = pyramid_reduce(pyramid{i - 1});
    end
end

function [imgout] = pyramid_reduce(img)
% Reduce an image by half size.
% img - result of imread on a image

    cw = .375;
    ker1d = [.25-cw/2 .25 cw .25 .25-cw/2];
    kernel = kron(ker1d, ker1d');

    img = im2double(img);
    sz = size(img);
    imgout = [];

    for p = 1:size(img, 3)
        img1 = img(:, :, p);
        imgFiltered = imfilter(img1, kernel, 'replicate', 'same');
        imgout(:, :, p) = imgFiltered(1:2:sz(1), 1:2:sz(2));
    end

end
