function spc_executeLoop


global state gh
state.internal.whatToDo=3;
h = gh.mainControls.startLoopButton;
val=get(h, 'String');
state.internal.cyclePaused=0;
try
    stop(state.spc.acq.mt);
end
try
    delete(state.spc.acq.mt);
end
try
    stop(state.spc.acq.timer.looptimer);
end
try
    delete(state.spc.acq.timer.looptimer);
end

if strcmp(val, 'LOOP')
	if strcmp(get(gh.basicConfigurationGUI.figure1, 'Visible'), 'on')
		beep;
		setStatusString('Close ConfigurationGUI');
		return
	end
    if state.init.syncToPhysiology
        if isfield(state,'physiology') & isfield(state.physiology,'mainPhysControls') & isfield(state.physiology.mainPhysControls,'acqNumber')
            maxVal=max(state.physiology.mainPhysControls.acqNumber,...
                state.files.fileCounter);
            state.physiology.mainPhysControls.acqNumber=maxVal;
            state.files.fileCounter=maxVal;
            updateGUIByGlobal('state.physiology.mainPhysControls.acqNumber');
            updateGUIByGlobal('state.files.fileCounter');
        end
    end
	if ~savingInfoIsOK;
		return
	end
	% Check if file exisits
	% TPMOD
	overwrite = checkFileBeforeSave([state.files.fullFileName '.tif']);
	if isempty(overwrite)
		return;
	elseif ~overwrite
		%TPMOD 2/6/02
		if state.files.autoSave	
			disp('Overwriting Data!!');
		end
	end
	
	mp285Flush;
	set(h, 'String', 'ABORT');
    set(h, 'Visible', 'off');
	set(gh.mainControls.grabOneButton, 'Visible', 'off');
	turnOffMenus;
	
	if state.internal.configurationChanged==1
		closeConfigurationGUI;
	end
	
	resetCounters;
	state.internal.abortActionFunctions=0;
	
	setStatusString('Starting cycle...');
	
	stopFocus;
	
	updateGUIByGlobal('state.internal.frameCounter');
	updateGUIByGlobal('state.internal.zSliceCounter');
	
	state.internal.firstTimeThroughLoop=1;
	state.acqParams.triggerTime=clock;
	state.internal.abort=0;
	state.internal.currentMode=3;
	
	spc_mainLoop;
else
	state.internal.looping=0;
	state.internal.abortActionFunctions=1;
	state.internal.abort=1;
	closeShutter;
	setStatusString('Stopping cycle...');
	set(h, 'Enable', 'off');
	
    spc_stopGrab;
    %spc_parkLaser;
    
	stopGrab;
	parkLaserCloseShutter;
	%flushAOData;
	
	executeGoHome;
	
	pause(.05);
	
    %%%%%%%%%%%%%%FLIM
    set(gh.spc.FLIMimage.loop, 'String', 'LOOP');
    get(gh.spc.FLIMimage.grab, 'String')
    if strcmp(get(gh.spc.FLIMimage.grab, 'String'), 'STOP')
        spc_executeGrabOne;
        stopAllChannels(state.acq.dm);
        MP285Clear;
        scim_parkLaser;
        flushAOData;       
        %FLIM_StopMeasurement;    
    end
    set(gh.spc.FLIMimage.grab,'String','GRAB');
    set (state.spc.init.spc_ao, 'SamplesOutputFcn', '');
    set(gh.spc.FLIMimage.grab, 'Visible', 'on');
    set(gh.spc.FLIMimage.focus, 'Visible', 'on'); 
    

    
    %%%%%%%%%%%%%%%FLIM
    
	set([gh.mainControls.focusButton gh.mainControls.grabOneButton], 'Visible', 'On');
    set([gh.mainControls.focusButton gh.mainControls.grabOneButton], 'Enable', 'On');
	turnOnMenus;
	set(h, 'String', 'LOOP');
	set(h, 'Enable', 'on');
    set(h, 'Visible', 'on');
    set(gh.spc.FLIMimage.focus,'Enable','On');
    set(gh.spc.FLIMimage.grab,'Enable','On');
    set(gh.spc.FLIMimage.loop,'Enable','On');

	setStatusString('');
end

