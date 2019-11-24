function flim_ini
global state
global spc
    version -java;
    str1 = ans;
        
    state.internal.usePage=0;
    state.acq.numberOfPages=64;
    state.acq.numberOfBinPages=4;
    state.acq.pageInterval=2.0;
    state.acq.framesPerPage=6;
    
    state.yphys.acq.uncagePageText='8:37';
    state.yphys.acq.uncagePage=8:37;
    state.yphys.acq.depolarize=0;
    state.yphys.acq.startDep=1;
    state.yphys.acq.stopDep=1;
    state.yphys.acq.frame_scanning=[];
%%%    
    state.init.spc_on = 1;
    state.spc.acq.spc_outputRate = 312500; %Ryohei 1/28/03 inputRate / 4 ** for fast board.
	state.spc.acq.spc_amplitude=5;   %Digital output.
	state.spc.acq.spc_pixel=0;
	state.spc.acq.spc_image=0;
	state.spc.acq.spc_dll=1;
	state.spc.acq.uncageBox=0;
	state.spc.acq.spc_takeFLIM=1;
    state.spc.acq.spc_average=1; %Average all frames.
	state.spc.acq.spc_binning=0; %Pixel binning. 
	state.spc.acq.binFactor=1; %Pixel binning factor.
	%state.spc.acq.spc_DataOutput=[];
	state.spc.acq.SPCModInfo=[];
	state.spc.acq.module=[];
    state.spc.acq.page=0;
    state.spc.acq.mData=[];
    state.spc.acq.SPCdata=[];
    state.spc.acq.SPCMemConfig=[];
	state.spc.acq.ifInactive=0;
    state.spc.acq.timing=0;
    state.spc.acq.resolution=6; %FLIM resolution. 6 bits = 64 time points.
    state.spc.acq.mt=[];
    state.spc.acq.timer.timerRates=[];
    state.spc.acq.timer.timerRatesEver=[];
    state.spc.acq.SPCdata.mode = 2;
    %%%% Mode
            %%%% 2 = imaging.
            %%%% 5 = FIFO.
%%%%
	state.spc.init.spc_on=1;
    if isempty(strfind(computer, '64')) %32bit
        state.spc.init.dllname = 'spcm32x64';
    else
        state.spc.init.dllname = 'spcm64';
    end
    state.spc.init.ao_flim1=[]; %FLIM switch output
	state.spc.init.spc_boardIndex='Dev2'; %%FLIM control output (sending 10V for up).
    state.spc.init.ao_flim1_index=5; %FLIM on /off
    state.spc.init.ao_flim2_index=6; %FLIM on /off
% 	state.spc.init.spc_triggerBoardIndex='Dev1';
% 	state.spc.init.spc_lineChannelIndex=0;
% 	state.spc.init.spc_frameChannelIndex=1;
% 	state.spc.init.spc_pixelChannelIndex=2;
% 	state.spc.init.pockelsChannelIndex=3;
% 	state.spc.init.pockelsChannel2Index=4;
% 	state.spc.init.pockelsChannel3Index=5;
    state.spc.init.spc_dualB=0;  %Does not work for now
    state.spc.init.infinite_Npages=1;
    state.spc.init.infinite_Nframes=1;
    state.spc.init.numSlicesPerFrames=2;
    state.spc.init.spc_showImages=1;
    %state.spc.init.dio_flim2=7;
    %state.spc.init.dio_flim=[1,0];
    %state.spc.init.dio_image=[0,1];                   		    
	state.spc.internal.spc_delay=.005;                    %Ryohei 9/17/2, Time for line/frame clock to begin
	state.spc.internal.ifstart=0;
    
    state.spc.files.savePath='';
    state.spc.files.autoSave=1;
    state.spc.files.automaticOverwrite=0;
    state.spc.files.fullFileName='001';
    
    state.spc.internal.sumSpc=zeros(64,128,128);

    spc.datainfo.pulseRate=0;
    spc.fit.range=[4,51];
    spc.fit.fixtau1=0;
    spc.fit.fixtau2=0;
    spc.fit.fix_g=0;
    spc.fit.fix_delta=0;
    spc.switches.lifetime_limit=[1.4,2.7];
    spc.switches.lutlim=[20,60];
