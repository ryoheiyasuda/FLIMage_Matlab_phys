function FLIM_setParameters (handles)

global state;

if nargin
    state.spc.acq.SPCdata = handles.SPCdata;
end

out1=calllib(state.spc.init.dllname,'SPC_set_parameters',state.spc.acq.module,state.spc.acq.SPCdata);

if (out1~=0)
    error = FLIM_get_error_string (out1);    
    disp(['error during setting parameters:', error]);
end
