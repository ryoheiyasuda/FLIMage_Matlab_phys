function h_background

% User function for ScanImaging to take background at the last z step

global state
global shutter_init

if state.internal.zSliceCounter == 0
    Frames_init = state.acq.numberOfFrames;
    shutter_init = state.shutter.open;
end

if state.internal.zSliceCounter + 2 == state.acq.numberOfZSlices
    state.shutter.open = 1;
%    numberOfFrames = 1;
else 
    state.shutter.open = shutter_init;
%    numberOfFrames = Frames_init;
end
