function spc_diotrigger(long)

global state

% diotrigger.m****
% Function that ouputs a single 1,0 to the dio device, acting as the falling edge trigger for the DAQ devices.
%
% This function is used to "start" the DAQ session. 
%
% This function also opens the shutter prior to acquisition.
%
% Written By: Thomas Pologruto
% Cold Spring Harbor Labs
% February 7, 2001

state.internal.dioTriggerTime = clock;

state.spc.acq.triggerTime = datestr(now);
%Ryohei 9/17/2 For FLIM
if ~nargin
    long = 0;
end

if state.shutter.open
    shutterState = state.shutter.shutterOpen;
else
    shutterState = ~state.shutter.shutterOpen;
end
dio_flim = [0, shutterState, state.spc.init.dio_flim(end-1:end)];
dio_image = [0, shutterState, state.spc.init.dio_image(end-1:end)];

%RY092909D Ryohei
if ~long
    pulseW = 0;
else
    pulseW = 0.2;
end
%RY092909D Ryohei

% Acquisition Board Trigger
% putvalue(state.init.triggerLine, 0);			% VI022708A (for good measure)
% pause(pulseW);                                      % VI022708A %RY092909D Ryohei
% putvalue(state.init.triggerLine, 1);			% Places an 'on' signal on the line initially
% pause(pulseW);                                      % VI022708A %RY092909D Ryohei
%putvalue(state.init.triggerLine, 0); 			% Digital Trigger: Places a go signal (1 to 0 transition; FallingEdge) to 
												% the line to trigger the ao1, ao2, & ai.

if state.spc.acq.spc_takeFLIM && state.spc.internal.ifstart
%     putvalue(state.spc.init.spc_dio, dio_flim);
%     pause(pulseW);
    putvalue(state.spc.init.spc_dio, [1, dio_flim(2:end)]);
    pause(pulseW);
    putvalue(state.spc.init.spc_dio, dio_flim);
else
%     putvalue(state.spc.init.spc_dio, dio_image);		% VI022708A (for good measure)
%     pause(pulseW);                                      % VI022708A %RY092909D Ryohei
    putvalue(state.spc.init.spc_dio, [1, dio_image(2:end)]);			% Places an 'on' signal on the line initially
    pause(pulseW);   
    putvalue(state.spc.init.spc_dio, dio_image);
end
