function yphys_getGain
global state;
global gh;

if ~state.yhys.init.yphys_on
    return;
end

try
    if state.yphys.acq.multiclamp == 1
        a = yphys_readGainMC700B;
        for i=1:length(a)
            vclamp = strcmpi(a(i).Mode, 'V-Clamp');
            state.yphys.acq.cclamp(i) = ~vclamp;
            try
                set(gh.yphys.scope.vclamp(i), 'Value', vclamp);
                set(gh.yphys.scope.vclamp(i), 'enable', 'off');
            end

            gain = a(i).Primary_Gain;

            if vclamp
                state.yphys.acq.gainV(i) = gain*a(i).ScaleFactor/1000;
                state.yphys.acq.commandSensV(i) = a(i).External_Cmd_Sens*1000;
            else
                state.yphys.acq.gainC(i) = a(i).Primary_Gain*10/1000;
                state.yphys.acq.commandSensC(i) = a(i).External_Cmd_Sens*1e12;
            end
            try
                set(gh.yphys.scope.gain, 'value', 1);
                set(gh.yphys.scope.gain, 'string', num2str(gain));
                set(gh.yphys.scope.gain, 'enable', 'off');
            end
        end
    else
        %stop(state.yphys.init.phys_setting);
        start(state.yphys.init.phys_setting);
        pause(0.05);
        if get(state.yphys.init.phys_setting, 'SamplesAvailable')
            data = getdata(state.yphys.init.phys_setting);
            data = mean(data, 1);
            
            if state.yphys.acq.multiclamp == 0
                gaindial = round(2*data(1,1));
                state.yphys.acq.cclamp = (data(1, 2) < 4);
            elseif state.yphys.acq.multiclamp == 2
                gaindial = round(data(1,1)/0.4)+3;
            end
            %gainArray = [1,2,5,10,20,50,100,200,500];
            switch gaindial
                case 4
                    gain = 0.5;
                case 5
                    gain = 1;
                case 6
                    gain = 2;
                case 7
                    gain = 5;
                case 8
                    gain = 10;
                case 9
                    gain = 20;
                case 10
                    gain = 50;
                case 11
                    gain = 100;
                case 12
                    gain = 200;
                case 13
                    gain = 500;
                case 14
                    gain = 1000;
                case 15
                    gain = 2000;
                otherwise
                    disp(['No gain', num2str(gaindial)]);
                    gain = 100;
            end
            state.yphys.acq.gainC = gain/100;
            state.yphys.acq.gainV = gain/1000;
            try
                if state.yphys.acq.multiclamp == 0
                    set(gh.yphys.scope.vclamp, 'enable', 'off');
                else
                    vclamp = get(gh.yphys.scope.vclamp, 'Value');
                    state.yphys.acq.cclamp = ~vclamp;
                end
                set(gh.yphys.scope.gain, 'enable', 'off');
                set(gh.yphys.scope.vclamp, 'Value', ~state.yphys.acq.cclamp);
                set(gh.yphys.scope.gain, 'string', {'0.5', '1', '2', '5', '10', '20', '50', '100', '200', '500', '1000', '2000'});
                set(gh.yphys.scope.gain, 'Value', gaindial-3);
            end
            %gain
        else
            pause(0.02);
            disp('Could not get Gain');
        end
    end
end