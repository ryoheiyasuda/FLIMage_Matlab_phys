function yphys2 = yphys_loadAverage
global gh;
global yphys;

if ~isfield(yphys, 'filename')
    yphys.filename = '';
end
if strcmp(yphys.filename, '')
    pathstr = pwd;
    if ~strcmp(pathstr(end-2:end), yphys.saveDirName)
        try
            cd(yphys.saveDirName);
        end
    end
    filenames=dir('yphys*.mat');

    if prod(size(filenames)) ~= 0
        b=zeros(1, length(filenames));
        for i = 1:length(filenames)
            b(i) = filenames(i).datenum;
        end
        [sorted, whichfile] = sort(datenum(b));
	    newest = whichfile(end);
	    filename = filenames(newest).name;
        yphys_loadYphys ([pathstr, '\', filename]);
    end
end

if ~strcmp(yphys.filename, '');
	[pathstr,filenamestr,extstr] = fileparts(yphys.filename);
	
	valName = ['e', get(gh.yphys.stimScope.epochN, 'String'), 'p', get(gh.yphys.stimScope.pulseN, 'String')];
	valFileName = [pathstr, '\', valName, '.mat'];
     if ~isfield(yphys, 'aveString')
         yphys.aveString{1} = '';
     end
     if iscell(yphys.aveString)
     else
        yphys.aveData = yphys.data.data;
        try
            yphys.aveData2 = yphys.data.data2;
        end
        yphys.aveString = [];
        yphys.aveString{1} = yphys.filename;
    end
	if exist(valFileName) == 2
		load(valFileName);
		
		evalc(['yphys2 = ', valName]);
		yphys.aveData = yphys2.aveData;
        try
            yphys.aveData2 = yphys2.aveData2;
        end
		yphys.aveString = yphys2.aveString;
        yphys_dispEphys;
	else
        yphys.aveString = [];
        yphys.aveData = [];
	end


end

try
	imageFile = [valName, '_int'];
	imagefileName = [pathstr, '\', valName,'_int.mat'];
	if exist(imagefileName);
           load(imagefileName);
           evalc(['image2 = ', imageFile]);
           yphys.image.aveImage = image2.aveImage;
           yphys.image.average = image2.average;
           yphys.image.currentImage = length(yphys.image.intensity);
           yphys_showImageTraces(0);
    else
        if isfield(yphys.image, 'intensity')
            saveIntensity = yphys.image.intensity;
        else
            saveIntensity = {};
        end
           %yphys.image = rmfield(yphys.image, 'aveImage');
        yphys.image.aveImage = [];
        yphys.image.intensity = saveIntensity;

	end
catch
end