function spc_read;
global state
global spc

pausetime10 = 2;
savespc = 0;
takemaximum = 0;
if state.acq.numberOfZSlices > 1
    if state.internal.zSliceCounter > 0;
            takemaximum = 1;
    end
    if state.internal.zSliceCounter + 1 == state.acq.numberOfZSlices %Done
		savespc = 1;
    end
end

filename = state.spc.files.fullFileName;
pausetime = (state.acq.pixelsPerLine/128)^2*pausetime10;
pause(pausetime);
state.spc.files.savePath = [state.files.savePath, 'spc\'];
filenames=dir(fullfile(state.spc.files.savePath, '*.sdt'));
b=struct2cell(filenames);
[sorted, whichfile] = sort(datenum(b(2, :)));
newest = whichfile(end);
filename = [state.spc.files.savePath, filenames(newest).name];
disp(['tcspc file = ', filename]);

try
    if takemaximum
        spc1 = spc;
    end
    if exist(filename)
        spc_readdata(filename);
    else
        disp('no such file');
    end
    if takemaximum
        index = (spc.project <= spc1.project);
		siz = size(index);
		
		index = repmat (index(:), [1,spc.size(1)]);
		index = reshape(index, siz(1), siz(2), spc.size(1));
		index = permute(index, [3,1,2]);
		
		spc.image = index .*  spc1.image + (1-index) .* spc.image;
        spc.project = reshape(sum(spc.image, 1), spc.size(2), spc.size(3));
        spc.imageMod = spc.image;
    end
    spc_redrawSetting;
catch
    disp('Error during reading FLIM data');
end

if savespc
    numstr1 = num2str(state.files.fileCounter);
    numstr2 = num2str(state.files.fileCounter + state.acq.numberOfZSlices - 1);
    while prod(size(numstr1)) < 3
        numstr1 = ['0', numstr1];
    end
    while prod(size(numstr2)) < 3
        numstr2 = ['0', numstr2];
    end    
    savestr = ['spc_', state.files.baseName, numstr1, '-', numstr2, 'max'];
    savestr = [state.files.savePath, savestr];
    disp(['saving into ', savestr]);
    save (savestr, 'spc');
end

pause(pausetime/2);