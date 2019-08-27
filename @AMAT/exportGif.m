function exportGif(mat)
    % Export a figure as a gif image
    frame = getframe(mat.fig);
    im = frame2im(frame);
    [imind, cm] = rgb2ind(im, 256);
    filename = sprintf('%s_%dx%d.gif', mat.progFilename, mat.numCols, mat.numRows);
    if isfile(filename)
        imwrite(imind, cm, filename, 'gif', 'WriteMode', 'append');
    else
        imwrite(imind, cm, filename, 'gif', 'Loopcount', inf);
    end
end
