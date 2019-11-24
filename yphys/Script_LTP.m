delay = 200; %millisecond. time of stimulation.
windowSize = 1; %millisecond around the peak
signalStart = 1;
signalEnd = 50; %millisecond after stimulation.
maxS = 50; %pA. Ignore signal larger than this.

testPulseN = 57; %protocol number for test pulse.

baseStart = -20;
baseEnd = -2;

fname = dir('yphys*.mat');

afterLTP = 0;
LTPS = 0;

figure; 
hold on;
for i=1:length(fname)
    fn = fname(i).name;
    load(fn);
    evalc(['yphys=', fn(1:end-4)]);
    
    if yphys.pulseN == testPulseN
        ws = windowSize * yphys.inputRate/1000;
        time1 = yphys.data(:, 1);
        data1 = yphys.data(:, 2);

        signal_start = (delay+signalStart)*yphys.inputRate/1000;
        signal_end = (delay + signalEnd)*yphys.inputRate/1000;
        base_start = (delay + baseStart)*yphys.inputRate/1000;
        base_end = (delay + baseEnd)*yphys.inputRate/1000;

        data1 = data1 - mean(data1(base_start:base_end));    
        data2 = imfilter(data1(signal_start:signal_end), ones(ws, 1)/ws, 'replicate');
        peak1(i) = -min(data2);

        time2 = time1(signal_start:signal_end);
        if afterLTP
            plot(time2, -data2,'-r');
        else
            plot(time2, -data2, '-b');
        end
        pause(0.01);
        ylim([-5, maxS]);
    else
        afterLTP = 1;
        LTPS = i;
        peak1(i) = nan;
    end
    %fprintf('%s, %d\n', fn, yphys.pulseN);
end

peak1(peak1 > maxS) = nan;
figure; 
plot([1:LTPS-1], peak1(1:LTPS-1), '-ob');
hold on;
plot([LTPS+1:length(peak1)], peak1(LTPS+1:end), '-or');