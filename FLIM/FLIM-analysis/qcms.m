function qcms(c)

global gh
global state
c = round(log2(c));
h = gh.advancedConfigurationGUI.msPerLine;
disp(['set to ', num2str(2^(c))]);
set(gh.advancedConfigurationGUI.msPerLine, 'Value', c+1);
state.internal.configurationChanged=1;
state.internal.configurationNeedsSaving=1;
genericCallback(h);
setAcquisitionParameters;
if state.internal.configurationChanged==1
	applyConfigurationSettings;
end
