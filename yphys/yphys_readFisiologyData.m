function yphys_readFisiologyData(fileName)
%fileName = 'C:\Users\yasudar\Documents\Data\AnanT\10292019\New shortcut001.txt';
global yphys

yphys.filename = fileName;

[pn, fn, ext] = fileparts(fileName);
currentFileN = str2double(fn(end-2:end));

fi = dir(fileName);
triggerTime = fi.date; %Just in case there is no triggerTime in the format....
fid = fopen(fileName, 'r');
y = 0;
tline = fgetl(fid);
mode = 'None';
ch = 1;
data = cell(1,2);
PulseSet = '';

while ischar(tline)
    if ~isempty(tline)
        if strcmp(tline(end), ':')
            mode = tline(1:end-1);
        elseif contains(tline, ',') && strcmp(mode, 'Data')
            evalc(['data{ch} = [', tline, ']']);
            ch = ch+1;
        elseif strcmp(mode, 'TriggerTime')
            triggerTime = tline;
            triggerTime = strrep(triggerTime, 'T', ', '); %chagne string format to a standard one. FLIMage uses 'yyyy-mm-ddTHH:MM:SS.FFF'
        elseif contains(tline, 'PulseName')
            val = strsplit(tline, '=');
            PulseName = val{2};
        elseif contains(tline, 'PulseSet=')
            val = strsplit(tline, '=');
            PulseSet = val{2};
        elseif  contains(tline, '=')
            try
                val = strsplit(tline, '=');
                if strcmp(mode, 'MC700Parameters')
                    evalc(['MC700Parameters.', val{1}, '= [' lower(val{2}), ']']);
                elseif strcmp(mode, 'StimParameters') && ~isempty(PulseSet)
                    evalc(['StimParameters.', PulseSet, '.', val{1}, '=' lower(val{2})]);
                else
                    evalc(['StimParameters.', val{1}, '=' lower(val{2})]);
                end
            end
        end
    end
    
    tline = fgetl(fid);
    y = y + 1;
end

yphys.saveDirName = '';
yphys.data.triggerTime = triggerTime;
yphys.data.n_physChannels = StimParameters.nChannelsPatch;
yphys.data.outputRate = StimParameters.outputRate;
yphys.data.inputRate = StimParameters.outputRate;
nSamples = length(data{1});
timeData = [1:nSamples]/yphys.data.inputRate*1000;
yphys.data.data = zeros(nSamples, yphys.data.n_physChannels);
yphys.data.data(:,1) = timeData;
yphys.data.data(:, 2) = data{1};

yphys.data.data2 = zeros(nSamples, yphys.data.n_physChannels);
yphys.data.data2(:,1) = timeData;
yphys.data.data2(:,2) = data{2};

