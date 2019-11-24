function result = FLIM_getParameters(hObject,handles)

global state;


data=libstruct('s_SPCdata');
data.base_adr=0;
[out1, state.spc.acq.SPCdata]=calllib(state.spc.init.dllname,'SPC_get_parameters',state.spc.acq.module,data);


if (out1~=0)
    error = FLIM_get_error_string (out1);    
    disp(['error during getting parameters:', error]);
end


if nargin
	handles.SPCdata=state.spc.acq.SPCdata;
	guidata(hObject,handles);
end

if nargout && nargin
    result = handles;
end
