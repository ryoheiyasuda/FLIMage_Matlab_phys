function yphys_putSampleStim
%dwell in milisecond.

global state;
global gh;

%set(state.yphys.init.phys, 'SampleRate', state.yphys.acq.outputRate, 'RepeatOutput', 0);
ext = get(gh.yphys.stimScope.ext, 'value');
ap = get(gh.yphys.stimScope.ap, 'value'); %state.yphys.acq.ap;
uncage=get(gh.yphys.stimScope.Uncage, 'value');   %state.yphys.acq.uncage;
stim = get(gh.yphys.stimScope.Stim, 'value');
theta = get(gh.yphys.stimScope.theta, 'Value');

%AP
    a_ap1a = pulseSetup(1);

%STIM
    a_stim1 = pulseSetup(2)/1000;


if state.yphys.init.n_physChannels > 1
    a_ap2a = pulseSetup(4);
end

if state.yphys.init.n_stimChannels > 1
    a_stim2 = pulseSetup(5)/1000;
end

%%%INPUT
if ap
    n = length(a_ap1a);
elseif stim
    n = length(a_stim1);
else
    n = 1000;
end

nSamples = round(n*state.yphys.acq.inputRate/state.yphys.acq.outputRate);
set(state.yphys.init.phys_input, 'sampQuantSampPerChan', nSamples);
set(state.yphys.init.phys_input, 'everyNSamples', nSamples);
set(state.yphys.init.phys_input, 'everyNSamplesEventCallbacks', @yphys_getData);

%%%patch

if ~state.yphys.acq.cclamp(1)
    a_ap1 = a_ap1a/state.yphys.acq.commandSensV(1);
else
    a_ap1 = a_ap1a/state.yphys.acq.commandSensC(1);
end


if state.yphys.init.n_physChannels > 1
    if ~state.yphys.acq.cclamp(2)
        a_ap2 = a_ap2a/state.yphys.acq.commandSensV(2);
    else
        a_ap2 = a_ap2a/state.yphys.acq.commandSensC(2);
    end
    
    a_ap = [a_ap1, a_ap2];
else
    a_ap = a_ap1;
end

if state.yphys.init.n_stimChannels > 1
    a_stim = [a_stim1, a_stim2];
else
    a_stim = a_stim1;
end

if ~stim
    a_stim = 0 * a_stim;
end

if ~ap
    a_ap = 0*a_ap;
end

state.yphys.acq.physOutputData_stim = a_stim;
state.yphys.acq.physOutputData_ap = a_ap;

max_signal = 10;

sat1 = a_ap > max_signal;
sat2 = a_stim > max_signal;
sat3 = a_ap < -max_signal;
sat4 = a_stim < -max_signal;

if sum(sat1(:)) > 0 || sum(sat2(:)) > 0 || ...
        sum(sat3(:)) > 0 || sum(sat4(:)) > 0
    disp('Warning: Signal saturation!!');
end

a_ap (a_ap > max_signal) = max_signal ;
a_stim (a_stim > max_signal) = max_signal ;
a_ap (a_ap < -max_signal) = -max_signal ;
a_stim (a_stim < -max_signal) = -max_signal ;

if ap || stim
    state.yphys.init.phys_both.set('sampClkRate', state.yphys.acq.outputRate);
    state.yphys.init.phys_both.set('sampQuantSampPerChan', length(a_ap));
    state.yphys.init.phys_both.writeAnalogData([a_ap, a_stim]);
end

end


function a = pulseSetup(tag)
global state
    param = state.yphys.acq.pulse{tag,state.yphys.acq.pulseN};
    rate = param.freq;
    nstim = param.nstim;
    dwell = param.dwell;
    amp = param.amp;
    delay = param.delay;
    sLength = state.yphys.acq.sLength(state.yphys.acq.pulseN);
    if isfield(param, 'addP')
        addP = param.addP;
    else
        addP = -1;
    end
    a = yphys_mkPulse(rate, nstim, dwell, amp, delay, sLength, addP, tag);
end
    %