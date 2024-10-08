function spc_saveAsTiff (fname, append, newHeader)
global spc
%%%%newHeader = 2::: Making header quickly.
if nargin < 3
    newHeader = 1;
end

if ~append
    disp([datestr(clock), ': Spc file =', fname]);
else
    disp([datestr(clock), ': Appending to', fname]);
end

if ~nargin
    append = 0;
end


siz = [spc.size(1), spc.SPCdata.scan_size_x, spc.SPCdata.scan_size_y];
spc.size = siz;

saveimage = uint16(reshape(spc.imageMod, siz(1), siz(2)*siz(3)));

if append
    imwrite(saveimage, fname, 'WriteMode', 'append');
else
    if newHeader == 1
        spc.headerstr = spc_makeheaderstr;
    elseif newHeader == 2
        spc_quickheaderstr;
    end
    imwrite(saveimage, fname, 'WriteMode', 'overwrite', 'Description', spc.headerstr);
end

spc.filename = fname;


% image = reshape(full(spc.image), spc.size(1), spc.size(2), spc.size(3));
% 
% for i = 1:size(1)
%     saveimage = reshape(image(i, :, :),size(2),size(3));
%     if i == 1
%         imwrite(saveimage, fname, 'tiff', 'WriteMode', 'overwrite', 'Description', ['hohoho', 13 ...
%             , 'hohoho']);
%     else
%         imwrite(saveimage, fname, 'tiff', 'WriteMode', 'append');
%     end
% end