function startup()
% Startup function for AMAT project 

% Create all necessary directories
paths = setPaths();
if ~isdir('./output'), mkdir('output'); end
if ~isdir('./external'), mkdir('external'); end
if ~isdir('./data'), mkdir('data'); end
if ~isdir(paths.amat.models), mkdir(paths.amat.models); end

% Download dependencies
disp('Downloading dependencies...')
if isdir('./external/spb-mil')  % spb-mil
    disp('-- spb-mil: CHECK!')
else
    disp('Cloning spb-mil...')
    unzip('https://github.com/tsogkas/spb-mil/archive/master.zip', 'external')
    movefile('./external/spb-mil-master', './external/spb-mil')
end

if isdir('./external/matlab-utils') % matlab-utils
    disp('-- matlab-utils: CHECK!')
else
    disp('Cloning matlab-utils...')
    unzip('https://github.com/tsogkas/matlab-utils/archive/master.zip', './external')
    movefile('./external/matlab-utils-master', './external/matlab-utils')
end
if isdir('./external/L0smoothing')  % L0-smoothing
    disp('-- L0smoothing: CHECK!')
else
    disp('Downloading L0smoothing code...')
    unzip('http://www.cse.cuhk.edu.hk/leojia/projects/L0smoothing/L0smoothing.zip','./external')
end
if isdir('./data/BSR')  % BSDR500
    disp('-- BSDS500: CHECK!')
else
    % untar does not work with this url, so we do it in two steps
    disp('Downloading BSDS500...')
    websave('data/BSR.tgz','http://www.eecs.berkeley.edu/Research/Projects/CS/vision/grouping/BSR/BSR_bsds500.tgz')
    try
        gunzip('data/BSR.tgz','data/')
        delete('data/BSR.tgz')
    catch
        movefile('data/BSR.tgz','data/BSR.tar')
        untar('data/BSR.tar','data/')
        delete('data/BSR.tar')
    end
end
if isdir('./external/Inpaint_nans')
    disp('-- Inpaint nans: CHECK!')
else
    disp('Downloading Inpaint nans code...')
    unzip('https://www.mathworks.com/matlabcentral/mlc-downloads/downloads/submissions/4551/versions/2/download/zip', './external')
end

% Add all packages to matlab path
addpath(genpath('external/spb-mil/'))
addpath('external/L0smoothing/code')
addpath('external/matlab-utils/')
addpath('external/Inpaint_nans/')
disp('-- Added external packages to matlab path: CHECK!')