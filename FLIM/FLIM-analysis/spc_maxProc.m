function spc_maxProc
global spc;
global state;
global spc_max;

if state.acq.numberOfZSlices > 1    
	if state.internal.zSliceCounter == 1 % if its the first frame of first channel, then overwrite...
        spc_max = spc;
        siz = spc_max.size;
        spc_max.project1 = reshape(sum(spc_max.imageMod, 1), siz(2), siz(3));
    else
        spc.size = size(spc.imageMod);
        siz = spc.size;
        spc.project1 = reshape(sum(spc.imageMod, 1), siz(2), siz(3));
        index = (spc.project1 <= spc_max.project1);
		siz = size(index);
		index = repmat (index(:), [1,spc.size(1)]);
		index = reshape(index, siz(1), siz(2), spc.size(1));
		index = permute(index, [3,1,2]);
        index = index(:);
		spc_max.imageMod = index .* spc_max.imageMod(:) + (1-index) .* spc.imageMod(:);
        spc_max.imageMod = reshape(spc_max.imageMod, spc.size(1), spc.size(2), spc.size(3));
        spc_max.project1 = reshape(sum(spc_max.imageMod, 1), spc.size(2), spc.size(3));
        %spc_max.imageMod = spc_max.image;
        spc = spc_max;
    end
else
    %spc_max = spc;
end

try
    spc_redrawSetting(1, 1);
catch
end