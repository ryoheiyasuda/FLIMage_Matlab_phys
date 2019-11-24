function spc_openprevious

global spc;

try
    [filepath, basename, filenumber, max] = spc_AnalyzeFilename(spc.filename);
catch
    error('Current filename not specified');
end

previous_filenumber_str = '000';
previous_filenumber_str ((end+1-length(num2str(filenumber-1))):end) = num2str(filenumber-1);
max = 1;
if max == 0
    previous_filename = [filepath, basename, previous_filenumber_str, '.tif'];
    previous_filename2 = [filepath, basename, previous_filenumber_str, '_max.tif'];
else
    previous_filename2 = [filepath, basename, previous_filenumber_str, '.tif'];
    previous_filename = [filepath, basename, previous_filenumber_str, '_max.tif'];
end

if exist(previous_filename)
    spc_openCurves (previous_filename);
elseif exist (previous_filename2)
    spc_openCurves (previous_filename2);
else
    disp([previous_filename, ' not exist!']);
end

spc_updateMainStrings;