function showImg(mat, xc, yc, rc, numRows, numCols, numScales)
    if exist('xc', 'var') == 1 && ...
            exist('yc', 'var') == 1 && ...
            exist('rc', 'var') == 1 && ...
            exist('numRows', 'var') == 1 && ...
            exist('numCols', 'var') == 1 && ...
            exist('numScales', 'var') == 1
        set(0,'CurrentFigure',mat.fig);
        showProgress(mat, xc, yc, rc, numRows, numCols, numScales);
        if mat.gif == 1
            mat.exportGif();
        end
    else
        showFinal(mat);
    end
end

function showFinal(mat)
    % cmap = jet(max(mat.radius(:)));
    subplot(221); imshow(mat.axis);           title('Medial axes');
    subplot(222); imshow(mat.radius, []);     title('Radii');
    subplot(223); imshow(mat.input);          title('Original image');
    subplot(224); imshow(mat.reconstruction); title('Reconstructed image');
end

function showProgress(mat, xc, yc, rc, numRows, numCols, numScales)
    % Function called when enabled vistop parameter.
    % It shows 4 different progress perspectives: selected disk, covered image, found axex in CIELAB and found radii.
    showProgressSelectedDisk(mat, 221, xc, yc, rc, numRows, numCols);
    showProgressCovered(mat, 222, xc, yc, rc, numRows, numCols, numScales);
    showProgressAxesCIELAB(mat, 223);
    showProgressRadii(mat, 224);
    drawnow;
end

function showProgressSelectedDisk(mat, subplotIndex, xc, yc, rc, numRows, numCols)
    subplot(subplotIndex);
    imshow(reshape(mat.input, numRows, numCols, []));
    viscircles([xc, yc], rc, 'Color', 'k', 'EnhanceVisibility', false);
    title(sprintf('Selected disk, radius: %d', rc));
end

function showProgressCovered(mat, subplotIndex, xc, yc, rc, numRows, numCols, numScales)
    % Sort costs in ascending order to visualize updated top disks.
    [~, indSorted] = mink(mat.diskCost(:), mat.vistop);
    [yy, xx, rr] = ind2sub([numRows, numCols, numScales], indSorted);
    subplot(subplotIndex);
    imshow(bsxfun(@times, reshape(mat.input, numRows, numCols, []), double(~mat.covered)));
    viscircles([xx, yy], rr, 'Color', 'w', 'EnhanceVisibility', false, 'Linewidth', 0.5);
    viscircles([xx(1), yy(1)], rr(1), 'Color', 'b', 'EnhanceVisibility', false);
    viscircles([xc, yc], rc, 'Color', 'y', 'EnhanceVisibility', false);
    title(sprintf('Covered %d/%d, numCols: Top-%d disks, \nB: Top-1 disk, Y: previous disk', ...
        nnz(mat.covered), numRows * numCols, mat.vistop));
end

function showProgressAxesCIELAB(mat, subplotIndex)
    subplot(subplotIndex);
    imshow(mat.axis);
    title('AMAT axes (in CIELAB)');
end

function showProgressRadii(mat, subplotIndex)
    subplot(subplotIndex);
    imshow(mat.radius, []);
    title('AMAT radii');
end
