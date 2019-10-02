function test()
    images = dir('data\BSR\BSDS500\data\images\test\*.jpg');
    for i = 3:numel(images)
        fprintf('%d\n', i);
        img = imread(sprintf('%s\\%s', images(i).folder, images(i).name));

        amat_simple = AMAT(img, 'scales', 2:40);
        export_data(images(i).name, 'simple');

        amat_pyramid = AMAT(img, 'scales', 2:40, 'pyramid', 1);
        export_data(images(i).name, 'pyramid');

        amat_neighbor = AMAT(img, 'scales', 2:40, 'followNeighbors', 1);
        export_data(images(i).name, 'neighbor');
        
        file = fopen(sprintf('test\\compression_%s.txt', images(i).name), 'w');
        fprintf(file, 'simple: %d\npyramid: %d\nneighbor: %d', nnz(amat_simple.radius), nnz(amat_pyramid.radius), nnz(amat_neighbor.radius));
        fclose(file);

%         save(['test\\', images(i).name, '.mat'], amat_simple, amat_pyramid, amat_neighbor);
        clearvars -except images i;
    end
end

function export_data(name, suffix)
    destination = sprintf('test\\%s_%s', name, suffix);
    mkdir(destination);
    save_all_figures(destination);
    close all;
    profsave(profile('info'), [destination, '\\profiler']);
end

function save_all_figures(destination)
    fig_list = findobj(allchild(0), 'flat', 'Type', 'figure');
    for i_fig = 1:length(fig_list)
      fig_handle = fig_list(i_fig);
      fig_name   = get(fig_handle, 'Name');
      set(0, 'CurrentFigure', fig_handle);
      savefig(fig_handle, fullfile(destination, [fig_name, '.fig']));    %<---- 'Brackets'
    end
end
