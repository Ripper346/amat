function exportGif(mat)
    % Export a figure as a gif image
    frame = getframe(mat.fig);
    im = frame2im(frame);
    [imind, cm] = rgb2ind(im, 256);
    if isfile(mat.gifFilename)
        imwrite(imind, cm, mat.gifFilename, 'gif', 'WriteMode', 'append');
    else
        imwrite(imind, cm, mat.gifFilename, 'gif', 'Loopcount', inf);
    end
end
