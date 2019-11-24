function spc_endAcquisition;

global state;
global gh;



spc_stopGrab;
FLIM_StopMeasurement;
closeShutter;

spc_parkLaser;
parkLaser;
stopGrab;
closeShutter;

if state.internal.usePage & state.acq.numberOfPages > 1
    if state.internal.pageCounter == 0
        tic
        state.spc.acq.timing(1) = 0;
    else
        state.spc.acq.timing(state.internal.pageCounter+1) = toc;
    end
    if state.internal.pageCounter + 1 == state.acq.numberOfPages
        spc_parkLaser;
        parkLaser;
        stopGrab;
        closeShutter;
        %for i=0:state.acq.numberOfPages-1
            i = state.acq.numberOfPages - 1;
            %state.spc.acq.page = i;
            state.spc.acq.page = mod (i, 2);
            doneAcqusition (i == state.acq.numberOfPages-1);
        %end
        state.internal.pageCounter = 0;
    else
        state.internal.pageCounter = state.internal.pageCounter + 1;
        if isfield(state, 'yphys')
           %state.internal.pageCounter
            if sum(state.internal.pageCounter == state.yphys.acq.uncagePage)
                uncageOnce;
            end
            spc_stopGrab;
        end
        state.spc.acq.page = mod (state.internal.pageCounter, 2);
        spc_putData(1);
        FLIM_SetPage (state.spc.acq.page); 
        FLIM_fillMemory (state.spc.acq.page);
        FLIM_StartMeasurement;
        spc_startGrab;
        %%%%%%%%%EXPERIMENTAL 
        state.spc.acq.page = mod (state.internal.pageCounter-1, 2);
        FLIM_imageAcq(0);
        %%%%%%%%%%%%%%%%%%%%%%
        openShutter;
		spc_diotrigger;
        %%%%%%%%%EXPERIMENTAL 
        %state.spc.acq.page = mod (state.internal.pageCounter-1, 2);
        %FLIM_imageAcq(0);
        spc_redrawSetting;
        global gui;
        if isfield (gui, 'spc')
            if isfield (gui.spc, 'spc_main')
                if get(gui.spc.spc_main.selectAll, 'Value')
                    spc_selectAll;
                end
            end
        end
        spc_writeData;
        state.files.fileCounter=state.files.fileCounter+1;
        updateGUIByGlobal('state.files.fileCounter');
        updateFullFileName(0);
        %%%%%%%%%%%%%%%%%%%%%%
    end
    return;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%FRAME acquisition!!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if acqFLIM
    if ~state.spc.acq.spc_average & ~state.internal.usePage
           if strcmp(get(gh.spc.FLIMimage.loop, 'String'), 'LOOP')
                set(gh.spc.FLIMimage.focus, 'Visible', 'on');
                set(gh.spc.FLIMimage.grab, 'Visible', 'on');
                stop(state.spc.acq.mt);
                delete(state.spc.acq.mt);
           end
            alldata = state.acq.acquiredData;
            state.spc.acq.SPCdata.scan_size_y = state.spc.acq.SPCdata.scan_size_y / state.acq.numberOfFrames;
            saveTriggerTime = state.spc.acq.triggerTime;
            for i=0:state.acq.numberOfFrames-1
                if acqFLIM
                    state.spc.acq.page = i;
                    a1 = datenum(saveTriggerTime) + state.acq.msPerLine * state.acq.linesPerFrame * i/60/60/24;
                    state.spc.acq.triggerTime = datestr(a1);
                else
                    a1 = datenum(saveTriggerTime) + state.acq.msPerLine * state.acq.linesPerFrame * i/60/60/24;
                    state.spc.acq.triggerTime = datestr(a1);
                end
%                 for j=find(state.acq.acquiringChannel)
%                     state.acq.acquiredData{j} = alldata{j}(:,:,i+1);
%                 end
                doneAcquisition(i == state.acq.numberOfFrames-1, acqFLIM);
            end
            state.spc.acq.page = 0;
            state.internal.pageCounter = 0;
            state.spc.acq.SPCdata.scan_size_y = state.spc.acq.SPCdata.scan_size_y * state.acq.numberOfFrames;
            return;
    end
end
if state.internal.zSliceCounter + 1 == state.acq.numberOfZSlices
% Done Acquisition.
    doneAcqusition (1);

elseif state.internal.zSliceCounter < state.acq.numberOfZSlices - 1
% Between Acquisitions or ZSlices
	setStatusString('Next Slice...');

	if state.acq.numberOfZSlices > 1
		startMoveStackFocus; 	% start movement - focal plane down one step
	end    
%%%%%%%%%%%%%%%%%%%%%% FLIM
    if state.spc.init.spc_on & state.spc.acq.spc_dll
        FLIM_imageAcq;
        set(gh.spc.FLIMimage.focus,'Enable','Off');
        set(gh.spc.FLIMimage.grab,'Enable','Off');
        set(gh.spc.FLIMimage.loop,'Enable','Off');
        spc_writeData;
        spc_maxProc;
    end
%%%%%%%%%%%%%%%%%%%%%%%%


	state.internal.zSliceCounter = state.internal.zSliceCounter + 1;
	updateGUIByGlobal('state.internal.zSliceCounter');

	state.internal.frameCounter = 1;
	updateGUIByGlobal('state.internal.frameCounter');
	
	setStatusString('Acquiring...');

    %putDataGrab;
	spc_putData;
	
	mp285FinishMove(0);	% check that movement worked
    FLIM_FillMemory;
    FLIM_StartMeasurement;
    spc_startGrab;
        
    looping = strcmp(get(gh.spc.FLIMimage.loop, 'String'), 'STOP');   
    if looping
        set(gh.spc.FLIMimage.loop, 'enable', 'on');
    else
        set(gh.spc.FLIMimage.grab, 'enable', 'on');
    end
	if (strcmp(get(gh.mainControls.grabOneButton, 'String'), 'GRAB') ...
			& strcmp(get(gh.mainControls.grabOneButton, 'Visible'),'on'))
		set(gh.mainControls.grabOneButton, 'enable', 'off');
		set(gh.mainControls.grabOneButton, 'enable', 'on');
	elseif (strcmp(get(gh.mainControls.startLoopButton, 'String'), 'LOOP') ...
			& strcmp(get(gh.mainControls.startLoopButton, 'Visible'),'on'))
		set(gh.mainControls.startLoopButton, 'enable', 'off');
		state.internal.abort=1;
		set(gh.mainControls.startLoopButton, 'enable', 'on');
	else

		openShutter;
		spc_diotrigger;
	end
	
else
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function doneAcqusition (last_frame);
global state;
global gh;

%%%%%%%%%%%%%%%FLIM
if state.spc.init.spc_on
    FLIM_imageAcq;
    spc_writeData;
    spc_maxProc;
    if state.acq.numberOfZSlices > 1 
            spc_saveAsTiff(state.spc.files.maxfullFileName, 0);
    end
    set (state.spc.init.spc_ao, 'SamplesOutputFcn', '');
    set(gh.spc.FLIMimage.grab, 'String', 'GRAB');

    if last_frame
       if strcmp(get(gh.spc.FLIMimage.loop, 'String'), 'LOOP')
            set(gh.spc.FLIMimage.focus, 'Visible', 'on');
            set(gh.spc.FLIMimage.grab, 'Visible', 'on');
            stop(state.spc.acq.mt);
            delete(state.spc.acq.mt);
        end
    end
end
  

state.files.fileCounter=state.files.fileCounter+1;

updateGUIByGlobal('state.files.fileCounter');
updateFullFileName(0);
    
if last_frame	
    state.internal.zSliceCounter = state.internal.zSliceCounter + 1;
	updateGUIByGlobal('state.internal.zSliceCounter');
    
	if state.acq.numberOfZSlices > 1
		%mp285FinishMove(1);	% check that movement worked during stack
		if ~executeGoHome
            disp('ERROR DURING EXECUTEGOHOME');
            pause(0.1);
            mp285FinishMove(1);
        else
            mp285FinishMove(1);
        end      
    end				

	setStatusString('Ending Grab...');
	set(gh.mainControls.focusButton, 'Visible', 'On');
	set(gh.mainControls.startLoopButton, 'Visible', 'On');
	set(gh.mainControls.grabOneButton, 'String', 'GRAB');
	set(gh.mainControls.grabOneButton, 'Visible', 'On');
	turnOnMenus;
	setStatusString('');

    looping = strcmp(get(gh.spc.FLIMimage.loop, 'String'), 'STOP');   

    if looping
        set(gh.mainControls.grabOneButton, 'Visible', 'Off');
    	set(gh.mainControls.startLoopButton, 'Visible', 'Off');
    end
end
    %flushAOData;


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %FLIM
    try
        spc_auto(1);
    catch
        disp('Error during evaluating spc_auto(1)');
    end

    %%%%Reset uncaging setup

    %%%%%%%%%%%%%%%%%%%%%%%%%
    % %TEMPORAL WORKAROUND
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if last_frame
    if isfield (state.spc.acq, 'twoPosition')
        if state.spc.acq.twoPosition
            posN = 2- (state.files.fileCounter-floor(state.files.fileCounter/2)*2);
            set(gh.motorGUI.positionSlider, 'Value', posN);
            genericCallback(gh.motorGUI.positionSlider);
            global gh
            %figure(gh.motorGUI.figure1);
            state.motor.maxXYMove = 300;
            turnOffMotorButtons;
            gotoPosition;
            turnOnMotorButtons;
        end
    end
 end
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function uncageOnce
%dwell in milisecond.

global state;

    stop(state.yphys.init.scan_ao);
    stop(state.yphys.init.pockels_ao);

 yphys_uncage;
param = state.yphys.acq.pulse{3,state.yphys.acq.pulseN};
rate = param.freq;
nstim = param.nstim;
dwell = param.dwell;
ampc = param.amp;
delay = param.delay;
sLength = param.sLength;
pause(sLength/1000+0.1);
return;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


   
