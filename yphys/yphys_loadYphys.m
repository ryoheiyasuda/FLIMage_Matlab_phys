function yphys_loadYphys (filestr)
global yphys
global gh

if ~nargin
     pwdstr = pwd;
     lendir = length(yphys.saveDirName);
     if ~strcmp(pwdstr(end-lendir+1:end), yphys.saveDirName)
         pwdstr = [pwdstr, filesep, saveDirName];
     end
     filenames=dir([pwdstr, '\yphys*']);
     b=struct2cell(filenames);
     b = zeros(1, length(filenames));
     for i = 1:length(filenames)
         b(i) = filenames(i).datenum;
     end
     [sorted, whichfile] = sort(b);
     if prod(size(filenames)) ~= 0
		  newest = whichfile(end);
		  filename = filenames(newest).name;
          filestr = [pwdstr, filesep, filename];
     end
end

if ~ischar(filestr)     
     if isempty(yphys.filename)
         pwdstr = pwd;
         lenDir = length(yphys.saveDirName);
         if ~strcmp(pwdstr(end-lenDir + 1:end), saveDirName)
             pathstr = [pwdstr, filesep, saveDirName];
         else
             pathstr = pwdstr;
         end
         filename1=sprintf('%s%03d', 'yphys', filestr);
         extstr = '.mat';
     else
         [pathstr,filenamestr,extstr] = fileparts(filestr);
         basename = filenamestr(1:end-3);
         filename1 = sprintf('%s%03d', basename, filestr);
     end
     filestr = [pathstr, filesep, filename1, extstr];
end

if exist(filestr, 'file')
    [pathstr,filenamestr,extstr] = fileparts(filestr);
    if strcmpi(filenamestr(1:end-3), 'yphys') && strcmpi(extstr, '.mat')
        load(filestr);	
        yphys.filename = filestr;
        evalc(['yphys.data = ', filenamestr]);
    else
        yphys_readFisiologyData(filenamestr);
    end
    
    num = str2double(filenamestr(end-2: end));
    nstr = num2str(num);
    set(gh.yphys.stimScope.fileN, 'String', nstr);
    
    yphys_dispEphys;
end