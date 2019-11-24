function yphys_sendStim
%dwell in milisecond.

global state;
global gh;

ext = get(gh.yphys.stimScope.ext, 'value');
yphys_stopAll;

yphys_setTrigger(ext);

%yphys_setup;
yphys_getGain;

yphys_putSampleStim;

state.yphys.internal.waiting = 1;
state.yphys.init.phys_both.start();
state.yphys.init.phys_input.start();

if ~ext
    state.yphys.acq.triggerTime = datestr(now, 'yyyy-mm-dd, HH:MM:SS.FFF');
    dioTrigger;
end   
