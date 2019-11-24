function FLIM_StartMeasurement

global state;
% if (state.spc.acq.SPCdata.mode == 2 | state.spc.acq.SPCdata.mode == 3)
%     status = 0;
%     [out1, status]=calllib(state.spc.init.dllname, 'SPC_get_scan_clk_state',state.spc.acq.module,status);
%     if (out1 ~= 0)
%         error = FLIM_get_error_string (out1);
%         disp(['error during scanning check:', error]);
%     else
%         status
%     end
% end

state.spc.internal.ifstart = 1;
out1=calllib(state.spc.init.dllname,'SPC_start_measurement',state.spc.acq.module);
if out1 ~= 0
    error = FLIM_get_error_string (out1);    
    disp(['Error during start measurement:', error]);
end
% a = FLIM_ifarmed;
% if a
%     disp('Starting FLIM')
% else
%     disp('Error in starting FLIM')
% end