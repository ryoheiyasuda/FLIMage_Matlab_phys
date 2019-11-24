function yphys_roiDelete;
global spc
global gh

roiN = str2num(get(gco, 'Tag'));

pa = findobj('Tag', num2str(roiN));
if size(pa) > 0
	for j = 1:size(pa)
        delete(pa(j));
    end
end

% gh.yphys.figure.yphys_roi(roiN) = [];
% gh.yphys.figure.yphys_roiText(roiN) = [];