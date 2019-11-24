function yphys_getData_patch(~, evnt)
global state;
global gh;

%data1 = evnt.data;
%evnt
data1 = state.yphys.init.phys_inputPatch.readAnalogData();

% if get(state.yphys.init.phys_input, 'SamplesAvailable') >= get(state.yphys.init.phys_input, 'SamplesPerTrigger')
%     data1 = getdata(state.yphys.init.phys_input);

if ~isempty(data1)
    for i = 1:state.yphys.init.n_physChannels
        if state.yphys.acq.cclamp(i)
            gain(i) = state.yphys.acq.gainC(i);
        else
            gain(i) = state.yphys.acq.gainV(i);
        end
    
    
    
        rate = state.yphys.acq.inputRate;
        data_ch{i} = data1(:, i)/gain(i);
    end
    
        t = 1:length(data_ch{i});

        %plot(t/rate*1000, data2);
        if ishandle(gh.yphys.patchPlot(1))
            state.yphys.acq.data = zeros(length(data_ch{state.yphys.internal.activeCh}), 2);
            state.yphys.acq.data(:,1) = state.yphys.acq.inputRate/1000*(1:length(data_ch{state.yphys.internal.activeCh}));
            state.yphys.acq.data(:,2) = data_ch{state.yphys.internal.activeCh};
            if ~state.yphys.internal.fft_on
                set(gh.yphys.patchPlot(1), 'XData', t/rate*1000, 'YData', data_ch{state.yphys.internal.activeCh});
                set(gh.yphys.scope.trace, 'XlimMode', 'auto');
            else
    %             l1 = length(data2);
    %             l2 = 2^floor(log(l1)/log(2));
                l2 = length(data_ch{state.yphys.internal.activeCh});
                a1 = abs(fft(data_ch{state.yphys.internal.activeCh}(1:l2)));
                f1 = (0:length(a1)-1)*state.yphys.acq.inputRate/l2;
                range = 2:round(l2/2);
                set(gh.yphys.patchPlot, 'XData', f1(range), 'YData', a1(range));
                set(gh.yphys.scope.trace, 'Xlim', [0, 600]);
            end
        else
            %yphys_patch;% stop function
        end
        
        %state.yphys.acq.data = [t(:)/rate*1000, data_ch{i}(:)];


    yphys_updateGUI;
    %catch
else
    %disp('XXX');
end

   stop(state.yphys.init.phys_input);