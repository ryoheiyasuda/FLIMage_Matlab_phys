function yphys_setTrigger(ext)

global state;

if ext
    triggerPort = state.yphys.init.externalTrigger;
else
    triggerPort = state.init.triggerInputTerminal;
end

state.yphys.init.phys_both.cfgDigEdgeStartTrig(triggerPort);
state.yphys.init.phys_input.cfgDigEdgeStartTrig(triggerPort);

state.yphys.init.phys_input.set('doneEventCallbacks', @yphys_getData);
