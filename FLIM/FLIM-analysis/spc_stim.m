function spc_stim;

global gh;
global state;

autoSetting.repeatPeriod = state.standardMode.repeatPeriod;
autoSetting.numberOfSlices = state.standardMode.numberOfZSlices;
autoSetting.zStepPerSlice = state.standardMode.zStepPerSlice;
autoSetting.numberOfFrames = state.standardMode.numberOfFrames;
%autoSetting.power = state.init.eom.maxPower(state.init.eom.scanLaserBeam);

autoSetting.zoomtens = state.acq.zoomtens;
autoSetting.zoomones = state.acq.zoomones;
autoSetting.zoomhundreds = state.acq.zoomhundreds;
autoSetting.scanRotation = state.acq.scanRotation;

repeatPeriod = 2;
numberOfSlices = 1;
zStepPerSlice = 1;
numberOfFrames = 1;

executeStartLoopCallback (gh.mainControls.loopButton);
