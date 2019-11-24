% pathNs = {'C:\data\Ana\ac113\ac113b\spc', 'C:\data\Ana\ac113\ac113c\spc', 'C:\data\Ana\ac113\ac113d\spc', ...
%     'C:\data\Ana\ac114\ac114a\spc', 'C:\data\Ana\ac114\ac114b\spc', 'C:\data\Ana\ac115\ac115a\spc'}
pathNs = {pwd};
for j = 1:length(pathNs)
    cd (pathNs{j});
    yphys = yphys_mini_scanFolder;
    warning off;
    disp('***** Channel 1******');
    mini = yphys_mini_statFolder(yphys, 1);
    disp('***** Channel 2******');
    mini2 = yphys_mini_statFolder(yphys, 2);
end