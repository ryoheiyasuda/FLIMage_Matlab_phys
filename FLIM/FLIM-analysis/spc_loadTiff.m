function error = spc_loadTiff (fname, page, fast)
global spc;

if nargin < 2
    page = 1;
end
if nargin < 3
    fast = 0;
end

error = 0;

if fast
    header = spc.headerstr;
else
    finfo = imfinfo (fname);
    header = finfo(1).ImageDescription;

    if length(finfo) < page
        page = length(finfo);
    end
    spc.header = header;
end

if findstr(header, 'spc')
    if ~fast
        evalc(header);    
    end
    try
        image1 = double(imread(fname, round(page)));
    catch
        error = 1;
        disp('Did not read...');
    end
else
    error = 1;
    disp('This is not a spc file !!');
end

if ~error
    spc.filename = fname;
    spc.page = page;
end

% frames = length(imfinfo(fname));
% for i = 1:frames
%     image (i, :, :) = double(imread(fname, i));
% end

 spc.size = [spc.size(1), spc.SPCdata.scan_size_y, spc.SPCdata.scan_size_x];
 siz = spc.size;
 spc.imageMod = reshape(image1, siz);
 spc.project = reshape(sum(image1, 1), spc.size(2), spc.size(3));
 %spc.image = sparse(reshape(image, spc.size(1), spc.size(2)*spc.size(3)));
 %spc.imageMod = spc.image;
% 
% 
% spc.size = size(spc.image);
% 
% spc.switches.imagemode = 1;
% spc.switches.lutlim = [50, 300];
% spc.switches.logscale = 1;
% spc.switches.peak = [-1, 4];
% spc.switches.lifetime_limit = [0.5, 5];
% 
% spc.fit.range = [1, spc.size(2)];
