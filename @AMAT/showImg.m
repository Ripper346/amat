function showImg(mat, xc, yc, rc)
    if exist('xc', 'var') == 1 && ...
            exist('yc', 'var') == 1 && ...
            exist('rc', 'var') == 1
        set(0, 'CurrentFigure', mat.fig);
        showProgress(mat, xc, yc, rc);
        if mat.gif == 1
            mat.exportGif();
        end
    else
        showFinal(mat);
    end
end

function showFinal(mat)
    % cmap = jet(max(mat.radius(:)));
    if isempty(mat.fig)
        mat.initializeFigure(true);
    end
    set(0, 'CurrentFigure', mat.fig);
    subplot(221); imshow(mat.axis);           title('Medial axes');
    subplot(222); imshow(mat.radius, []);     title('Radii');
    subplot(223); imshow(mat.input);          title('Original image');
    subplot(224); imshow(mat.reconstruction); title('Reconstructed image');
    drawnow;
end

function showProgress(mat, xc, yc, rc)
    % Function called when enabled vistop parameter.
    % It shows 4 different progress perspectives: selected disk, covered image, found axex in CIELAB and found radii.
    showProgressSelectedDisk(mat, 221, xc, yc, rc);
    showProgressCovered(mat, 222, xc, yc, rc);
    showProgressAxesCIELAB(mat, 223);
    showProgressRadii(mat, 224);
    drawnow;
end

function showProgressSelectedDisk(mat, subplotIndex, xc, yc, rc)
    subplot(subplotIndex);
    imshow(reshape(mat.input, mat.numRows, mat.numCols, []));
    viscircles([xc, yc], rc, 'Color', 'k', 'EnhanceVisibility', false);
    title(sprintf('Selected disk, radius: %d', mat.scales(rc)));
end

function showProgressCovered(mat, subplotIndex, xc, yc, rc)
    % Sort costs in ascending order to visualize updated top disks.
    [~, indSorted] = mink(mat.diskCost(:), mat.vistop);
    [yy, xx, rr] = ind2sub([mat.numRows, mat.numCols, mat.numScales], indSorted);
    subplot(subplotIndex);
    imshow(bsxfun(@times, reshape(mat.input, mat.numRows, mat.numCols, []), double(~mat.covered)));
    viscircles([xx, yy], rr, 'Color', 'w', 'EnhanceVisibility', false, 'Linewidth', 0.5);
    viscircles([xx(1), yy(1)], rr(1), 'Color', 'b', 'EnhanceVisibility', false);
    viscircles([xc, yc], rc, 'Color', 'y', 'EnhanceVisibility', false);
    title(sprintf('Covered %d/%d, mat.numCols: Top-%d disks, \nB: Top-1 disk, Y: previous disk', ...
        nnz(mat.covered), mat.numRows * mat.numCols, mat.vistop));
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
