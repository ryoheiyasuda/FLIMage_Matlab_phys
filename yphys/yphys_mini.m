function yphys_mini
global state;


duration = 60; % measurement time in sec
updateDuration = 1;
updateRate = round(1 / updateDuration);
yphys_setup;
yphys_getGain;

for ch = 1:2
    if state.yphys.acq.cclamp(ch)
        gain(ch) = state.yphys.acq.gainC(ch);
    else
        gain(ch) = state.yphys.acq.gainV(ch);
    end
end
%%%%%%%%%%%%
%setting
%analoginput
samplesize = state.yphys.acq.inputRate*duration;
ai1 = analoginput('nidaq',state.yphys.init.phys_boardIndex);
set(ai1, 'SampleRate', state.yphys.acq.inputRate, 'Tag', 'yphys');
set(ai1, 'SamplesPerTrigger', samplesize);
set(ai1, 'TriggerType', 'Immediate');
aiC1 = addchannel(ai1, state.yphys.init.phys_dataIndex);
aiC2 = addchannel(ai1, state.yphys.init.phys_dataIndex2);
set(aiC1, 'InputRange', [-10, 10]);
set(aiC2, 'InputRange', [-10, 10]);

figure;
updatesize = updateDuration * state.yphys.acq.inputRate;
%%%%%%%%%%%%
set(gcf, 'doublebuffer', 'on');
for ch= 1:2
    subplot(2,1,ch);
    P(ch) = plot(zeros(updatesize, 1));
    xlabel('Time(s)');
    if state.yphys.acq.cclamp
        ylabel('V (mV)');
    else
        ylabel('I (pA)');
    end
    data1 = [];
    data2 = [];
end

start(ai1);
for i=0:duration*updateRate-1
   while get(ai1, 'SamplesAvailable') < updatesize
       pause(0.1);
   end
   data = getdata(ai1, updatesize);
   data1 = [data1; data(:,1)/gain(1)];
   data2 = [data2; data(:,2)/gain(2)];
   xdata1 = [1:length(data1)]/state.yphys.acq.inputRate;
   size(data1);
   set(P(1), 'xdata', xdata1, 'ydata', data1);
   set(P(2), 'xdata', xdata1, 'ydata', data2);
end

miniData = [xdata1(:), data1(:)];
miniData2 = [xdata1(:), data2(:)];

%%%%%%%%%%%%%%%%%Save%%%%%%%%%%%%%%%%%%%%%%%%%%
state.yphys.acq.data = miniData;
state.yphys.acq.data2 = miniData2;

if ~isfield (state.yphys.acq, 'phys_counter')
    state.yphys.acq.phys_counter = 1;
end
if state.yphys.acq.phys_counter == 1;
    filenames=dir(fullfile(state.files.savePath, '\spc\yphys*.mat'));
    if prod(size(filenames)) ~= 0
        b=struct2cell(filenames);
        [sorted, whichfile] = sort(datenum(b(2, :)));
        newest = whichfile(end);
        filename = filenames(newest).name;
        pos1 = strfind(filename, '.');
        state.yphys.acq.phys_counter = str2num(filename(pos1-3:pos1-1))+1;
    else
        state.yphys.acq.phys_counter = 1;
    end
else
    state.yphys.acq.phys_counter =  state.yphys.acq.phys_counter + 1;
end

if isfield(state, 'files')
    numchar = sprintf('%03d', state.yphys.acq.phys_counter);
    filen = ['yphys', numchar];
    evalc([filen, '= state.yphys.acq']);
    filedir = [state.files.savePath, 'spc\'];
end
if exist(filedir)
    cd(filedir);
    save(filen, filen);
else
    cd ([filedir, '\..\']);
    mkdir('spc');
    cd(filedir);
    save(filen, filen);
end