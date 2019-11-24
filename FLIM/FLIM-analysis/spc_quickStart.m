function spc_quickStart(defFile)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function that starts the ScanImage software.
% 
% defFile is the default file name of a .usr file if called as a function.
%
% Software Description:
%
% ScanImage controls a laser-scanning microscope (Figure 1A). It is written 
% entirely in MATLAB and makes use of standard multifunction boards 
% (e.g. National Instruments, Austin, TX) for data acquisition and 
% control of scanning. The software generates the analog voltage 
% waveforms to drive the scan mirrors, acquires the raw data from 
% the photomultiplier tubes (PMTs), and processes these signals to 
% produce images. ScanImage controls three input channels 
% (12-bits each) simultaneously, and the software is written to be 
% easily expandable to the maximum number of channels the data acquisition 
% (DAQ) board supports and that the CPU can process efficiently. 
% The computer bus speed dictates the number of samples that can be 
% acquired before an overflow of the input buffer occurs, while the 
% CPU speed and bus speed combine to determine the rate of data 
% processing and ultimately the refresh rate of images on the screen. 
% Virtually no customized data acquisition hardware is required for 
% either scan mirror motion or data acquisition.
%
% Reference: Pologruto, T.A., Sabatini, B.L., and Svoboda, K. (2003)
%            ScanImage: Flexible software for operating laser scanning microscopes.
%            Biomedical Engineering Online, 2:13.
%            Link: www.biomedical-engineering-online.com/content/2/1/13
%
% Copyright 2003 Cold Spring harbor Laboratory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Create waitbar to track process of application.

% Global declaration: all variables used by ScanImage are contained in the structure
% state, while all the handles to the grpahics objects (GUIs) are contained in
% the structure gh
global state gh

%User File Manipulations from outside the function....
if nargin<1
    defFile='';
end

% Select user file if one exists....
% Remembers the path to the last one loaded from the last session if possible....
scanimagepath=fileparts(which('scanimage'));
if isdir(scanimagepath) & exist(fullfile(scanimagepath,'lastUserPath.mat'))==2
    temp=load(fullfile(scanimagepath,'lastUserPath.mat'));
    userpath=getfield(temp,char(fieldnames(temp)));
    if isdir(userpath)
        cd(userpath);
    end
end
if ~nargin
	[fname, pname]=uigetfile('*.usr', 'Choose user file');
	if isnumeric(fname)
        fname='';
        pname='';
        full=[];
	else
        cd(pname);
        full=fullfile(pname, fname);
        defFile = full;
	end
end

%Build GUIs 
state.internal.guinames={'roiCycleGUI','imageGUI','channelGUI','basicConfigurationGUI','advancedConfigurationGUI','motorGUI',...
        'mainControls','standardModeGUI','UserFcnGUI','cc','userPreferenceGUI','powerControl','powerTransitions'};

for guicounter=1:length(state.internal.guinames)
    gh=setfield(gh,state.internal.guinames{guicounter},eval(['guidata(' state.internal.guinames{guicounter} ')']));
end

% Open the waitbar for loading
openini('standard.ini');

setStatusString('Initializing...');

MP285Config; % Configure Motor Driver
makeImageFigures;	% config independent...rleies only on the .ini file for maxNumberOfChannles.

setupDAQDevices_Common;				% config independent
makeAndPutDataPark;					% config independent
setStatusString('Initializing...');

if state.video.videoOn
    waitbar(.6,h, 'Starting Video Controls...');
    videoSetup;
end

%Activate Pockels Cell.
state.internal.eom.calibrateOnStartup = 0;
if state.init.pockelsOn
    startEomGui;
    powerControl('usePowerArray_Callback',gh.powerControl.usePowerArray);
else
    set(gh.powerControl.figure1,'Visible','off');
    set(get(gh.powerControl.figure1,'Children'),'Enable','off');
end

parkLaserCloseShutter;				% config independent

if length(defFile)==0
    applyModeCycleAndConfigSettings;
    updateAutoSaveCheckMark;	% BSMOD
    updateKeepAllSlicesCheckMark; % BSMOD
    updateAutoOverwriteCheckMark;
else
    openusr(defFile);
end

if state.init.roiManagerOn==1
    startROIManager('off');
end

setStatusString('Initializing...');

updateMotorPosition;

setStatusString('Initializing...');
state.internal.startupTime=clock;
state.internal.startupTimeString=clockToString(state.internal.startupTime);
updateHeaderString('state.internal.startupTimeString');


setStatusString('Ready to use');
state.initializing=0;
setStatusString('Ready to use');

%TPMODPockels
advancedConfigurationGUI('pockelsClosedOnFlyback_Callback',gh.advancedConfigurationGUI.pockelsClosedOnFlyback);
roicyclegui('roiCyclePosition_Callback',gh.roiCycleGUI.roiCyclePosition);   %setup initila cycle....
