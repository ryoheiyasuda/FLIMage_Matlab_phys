function spc_define (n)
global spc_d
global state;

autoSetting.repeatPeriod = state.standardMode.repeatPeriod;
autoSetting.numberOfSlices = state.standardMode.numberOfZSlices;
autoSetting.zStepPerSlice = state.standardMode.zStepPerSlice;
autoSetting.numberOfFrames = state.standardMode.numberOfFrames;
autoSetting.power = state.init.eom.maxPower(state.init.eom.scanLaserBeam);

autoSetting.zoomtens = state.acq.zoomtens;
autoSetting.zoomones = state.acq.zoomones;
autoSetting.zoomhundreds = state.acq.zoomhundreds;
autoSetting.scanRotation = state.acq.scanRotation;

str = ['spc_d.def', num2str(n),  '= autoSetting'];

eval(str);
	global gh
set(gh.motorGUI.positionSlider, 'Value', n);
genericCallback(gh.motorGUI.positionSlider);


	figure(gh.motorGUI.figure1)
	turnOffMotorButtons;
	definePosition;
	turnOnMotorButtons;
 
 % spc_goto(n);