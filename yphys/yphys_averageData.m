function yphys_averageData
global yphys


yphys_loadAverage;

if ~isfield(yphys, 'aveData')
    yphys.aveData = yphys.data.data;   
    yphys.aveString{1} = yphys.filename;
end

if (yphys.data.n_physChannels > 1)
    if ~isfield(yphys, 'aveData2')
        yphys.aveData2 = yphys.data.data2;
    end
end
    
tmpData = yphys.data.data;
if (yphys.data.n_physChannels > 1)
    tmpData2 = yphys.data.data2;
end

[pathstr, filenamestr, extstr]=fileparts(yphys.filename);

if iscell(yphys.aveString)
    nave = length(yphys.aveString);
    if isempty(findstr(cell2mat(yphys.aveString),filenamestr))
        yphys.aveString{end+1} = yphys.filename;
        if length(yphys.aveData) > length(tmpData)
            yphys.aveData = yphys.aveData(1:length(tmpData), :);
        elseif length(yphys.aveData) < length(tmpData)
            tmpData = tmpData(1:length(yphys.aveData), :);
        end
        yphys.aveData(:, 2) = (tmpData(:, 2) + yphys.aveData(:, 2)*(nave-1))/nave;
        
        if (yphys.data.n_physChannels > 1)
            if length(yphys.aveData2) > length(tmpData2)
                yphys.aveData2 = yphys.aveData2(1:length(tmpData2), :);
            elseif length(yphys.aveData2) < length(tmpData2)
                tmpData2 = tmpData2(1:length(yphys.aveData2), :);
            end

            yphys.aveData2(:, 2) = (tmpData2(:, 2) + yphys.aveData2(:, 2)*(nave-1))/nave;
        end
    else
        %beep;
        %disp('Already in average');
    end
else
    yphys.aveData = yphys.data.data;
    if (yphys.data.n_physChannels > 1)
        yphys.aveData2 = yphys.data.data2;
    end
    yphys.aveString = [];
    yphys.aveString{1} = yphys.filename;
end

if ishandle(yphys.figure.avePlot)
    %yphys.fwindow = 1;
    fave = imfilter(yphys.aveData(:,2), ones(yphys.fwindow, 1)/yphys.fwindow);
    set(yphys.figure.avePlot, 'XData', yphys.aveData(:,1), 'YData', fave, 'Color', 'red');
end

if isfield(yphys.figure, 'avePlot2')
    if ishandle(yphys.figure.avePlot2)
        %yphys.fwindow = 1;
        fave = imfilter(yphys.aveData2(:,2), ones(yphys.fwindow, 1)/yphys.fwindow);
        set(yphys.figure.avePlot2, 'XData', yphys.aveData(:,1), 'YData', fave, 'Color', 'red');
    end
end

yphys_updateAverage;