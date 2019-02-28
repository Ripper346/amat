function showImg(mat, level, xc, yc, rc)
    if exist('xc', 'var') == 1 && ...
            exist('yc', 'var') == 1 && ...
            exist('rc', 'var') == 1 && ...
            exist('numRows', 'var') == 1 && ...
            exist('numCols', 'var') == 1 && ...
            exist('numScales', 'var') == 1
        set(0, 'CurrentFigure', mat.fig);
        showProgress(level, mat.vistop, xc, yc, rc);
        if mat.gif == 1
            mat.exportGif();
        end
    else
        showFinal(level);
    end
end

function showFinal(level)
    % cmap = jet(max(mat.radius(:)));
    subplot(221); imshow(level.axis);           title('Medial axes');
    subplot(222); imshow(level.radius, []);     title('Radii');
    subplot(223); imshow(level.result);         title('Original image');
    subplot(224); imshow(level.reconstruction); title('Reconstructed image');
end

function showProgress(level, vistop, xc, yc, rc)
    % Function called when enabled vistop parameter.
    % It shows 4 different progress perspectives: selected disk, covered image, found axex in CIELAB and found radii.
    showProgressSelectedDisk(level, 221, xc, yc, rc);
    showProgressCovered(level, 222, vistop, xc, yc, rc);
    showProgressAxesCIELAB(level, 223);
    showProgressRadii(level, 224);
    drawnow;
end

function showProgressSelectedDisk(level, subplotIndex, xc, yc, rc)
    subplot(subplotIndex);
    imshow(reshape(level.result, level.numRows, level.numCols, []));
    viscircles([xc, yc], rc, 'Color', 'k', 'EnhanceVisibility', false);
    title(sprintf('Selected disk, radius: %d', rc));
end

function showProgressCovered(level, subplotIndex, vistop, xc, yc, rc)
    % Sort costs in ascending order to visualize updated top disks.
    [~, indSorted] = mink(level.diskCost(:), vistop);
    [yy, xx, rr] = ind2sub([level.numRows, level.numCols, level.numScales], indSorted);
    subplot(subplotIndex);
    imshow(bsxfun(@times, reshape(level.result, level.numRows, level.numCols, []), double(~level.covered)));
    viscircles([xx, yy], rr, 'Color', 'w', 'EnhanceVisibility', false, 'Linewidth', 0.5);
    viscircles([xx(1), yy(1)], rr(1), 'Color', 'b', 'EnhanceVisibility', false);
    viscircles([xc, yc], rc, 'Color', 'y', 'EnhanceVisibility', false);
    title(sprintf('Covered %d/%d, numCols: Top-%d disks, \nB: Top-1 disk, Y: previous disk', ...
        nnz(level.covered), level.numRows * level.numCols, vistop));
end

function showProgressAxesCIELAB(level, subplotIndex)
    subplot(subplotIndex);
    imshow(level.axis);
    title('AMAT axes (in CIELAB)');
end

function showProgressRadii(level, subplotIndex)
    subplot(subplotIndex);
    imshow(level.radius, []);
    title('AMAT radii');
end
