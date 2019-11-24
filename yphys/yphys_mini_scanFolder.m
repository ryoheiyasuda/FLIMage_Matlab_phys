function yphys = yphys_mini_scanFolder

fnames = dir('yphys*.mat');
for i=1:length(fnames)
    vname = fnames(i).name;
    if isempty(strfind(vname, 'mini'))
        disp(['Pre-scanning ', vname, '...']);
        load(fnames(i).name);
        vname = vname(1:8);
        evalc(['a =', vname]);
        
        [b.peak_pos, b.peak_amp, b.base_amp] = yphys_mini_preScan (a, 1);
        [b.peak_pos2, b.peak_amp2, b.base_amp2] = yphys_mini_preScan (a, 2);
        
        yphys = a;
        vname_n = [vname, '_mini'];
        evalc([vname_n, '=b']);
        save(vname_n, vname_n);
    end
end