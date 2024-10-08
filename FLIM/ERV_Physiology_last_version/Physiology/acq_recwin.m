%Physiology scope software
%Emiliano Rial Verde
%October-November 2005
%Updated for better performance in Matlab 2006a. November 2006
%Version 2 adds capability to record 12 channels and output 4 channels
%November 2006
%
%Recording parameter windows

if isempty(findobj('Tag', 'recwindow'))
else
    close(findobj('Tag', 'recwindow'));
end

%Rec window
h0 = figure(...
'Units','normalized',...
'MenuBar','none',...
'Name','ERV Physiology Recorder. V 2.0',...
'NumberTitle','off',...
'Position',[0.08 0.035 0.4 0.23],...
'Tag','recwindow');

%Recording time parameters
h1 = uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.01 0.86 0.11 0.1],...
'Style', 'text', ...
'String','Sweep length:',...
'HorizontalAlignment', 'left', ...
'FontSize', 10);
a=get(gcf, 'Color');
set(h1, 'BackgroundColor', a);
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.12 0.86 0.1 0.12],...
'Style', 'edit', ...
'String', 'nan',...
'Callback', ...
['set(findobj(''Tag'', ''acqtime2text''), ''String'', num2str(0.001*str2num(get(findobj(''Tag'',', ...
    '''sweepnumberedit''), ''String''))*(str2num(get(findobj(''Tag'', ''sweeplengthedit''),', ...
    '''String''))+str2num(get(findobj(''Tag'', ''sweepintervaledit''), ''String'')))));', ...
    'set(findobj(''Tag'', ''acqtimetext''), ''String'', num2str(0.001*str2num(get(findobj(''Tag'',', ...
    '''sweepnumberedit''), ''String''))*(str2num(get(findobj(''Tag'', ''sweeplengthedit''),', ...
    '''String'')))));'], ...
'ToolTipString', 'Sweep length in ms', ...
'FontSize', 8, ...
'Tag','sweeplengthedit');

uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.01 0.72 0.11 0.1],...
'Style', 'text', ...
'String','IS interval:',...
'HorizontalAlignment', 'left', ...
'BackgroundColor', a, ...
'FontSize', 10);
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.12 0.72 0.1 0.12],...
'Style', 'edit', ...
'String', 'nan',...
'Callback', ...
['set(findobj(''Tag'', ''acqtime2text''), ''String'', num2str(0.001*str2num(get(findobj(''Tag'',', ...
    '''sweepnumberedit''), ''String''))*(str2num(get(findobj(''Tag'', ''sweeplengthedit''),', ...
    '''String''))+str2num(get(findobj(''Tag'', ''sweepintervaledit''), ''String'')))));', ...
    'set(findobj(''Tag'', ''acqtimetext''), ''String'', num2str(0.001*str2num(get(findobj(''Tag'',', ...
    '''sweepnumberedit''), ''String''))*(str2num(get(findobj(''Tag'', ''sweeplengthedit''),', ...
    '''String'')))));'], ...
'ToolTipString', 'Inter-sweep interval in ms', ...
'FontSize', 8, ...
'Tag','sweepintervaledit');

uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.01 0.58 0.11 0.1],...
'Style', 'text', ...
'String','Sweep num:',...
'HorizontalAlignment', 'left', ...
'BackgroundColor', a, ...
'FontSize', 10);
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.12 0.58 0.1 0.12],...
'Style', 'edit', ...
'String', 'nan',...
'Callback', ...
['set(findobj(''Tag'', ''acqtime2text''), ''String'', num2str(0.001*str2num(get(findobj(''Tag'',', ...
    '''sweepnumberedit''), ''String''))*(str2num(get(findobj(''Tag'', ''sweeplengthedit''),', ...
    '''String''))+str2num(get(findobj(''Tag'', ''sweepintervaledit''), ''String'')))));', ...
    'set(findobj(''Tag'', ''acqtimetext''), ''String'', num2str(0.001*str2num(get(findobj(''Tag'',', ...
    '''sweepnumberedit''), ''String''))*(str2num(get(findobj(''Tag'', ''sweeplengthedit''),', ...
    '''String'')))));'], ...
'ToolTipString', 'Number of sweeps to acquire (inf is a valid entry)', ...
'FontSize', 8, ...
'Tag','sweepnumberedit');

uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.01 0.45 0.11 0.1],...
'Style', 'text', ...
'String','Rec. time (s):',...
'HorizontalAlignment', 'left', ...
'BackgroundColor', a, ...
'FontSize', 10);
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.12 0.45 0.1 0.1],...
'Style', 'text', ...
'String', '?',...
'ToolTipString', 'Recording time in s', ...
'FontSize', 10, ...
'Tag','acqtimetext');

uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.01 0.34 0.11 0.1],...
'Style', 'text', ...
'String','Acq. time (s):',...
'HorizontalAlignment', 'left', ...
'BackgroundColor', a, ...
'FontSize', 10);
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.12 0.34 0.1 0.1],...
'Style', 'text', ...
'String', '?',...
'ToolTipString', 'Acquisition time in s (includes inter-sweep interval)', ...
'FontSize', 10, ...
'Tag','acqtime2text');

uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.01 0.02 0.145 0.1],...
'Style', 'text', ...
'String','Sweeps recorded:',...
'HorizontalAlignment', 'left', ...
'BackgroundColor', a, ...
'FontSize', 10);
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.16 0.02 0.06 0.12],...
'Style', 'text', ...
'String','0',...
'ToolTipString', 'Sweeps acquired and recorded to disk', ...
'FontSize', 12, ...
'FontWeight', 'bold', ...
'Tag','acqnumbertext');

%Status text
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.23 0.02 0.15 0.12],...
'Style', 'text', ...
'String','Ready',...
'ToolTipString', 'Status', ...
'FontSize', 12, ...
'FontWeight', 'bold', ...
'BackgroundColor', 'y', ...
'ForegroundColor', 'r', ...
'Tag','recstatustext');
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.23 0.145 0.15 0.06],...
'Style', 'text', ...
'Visible', 'off', ...
'String','waiting...',...
'ToolTipString', 'Timer status', ...
'BackgroundColor', 'r', ...
'ForegroundColor', 'y', ...
'Tag','timerstatustext');


%Recording channel parameters
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.228 0.88 0.152 0.1],...
'Style', 'text', ...
'String','Data channels',...
'BackgroundColor', a, ...
'FontSize', 12, ...
'FontWeight', 'bold');

uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.23 0.78 0.07 0.1],...
'Style', 'edit', ...
'String', 'nan',...
'ToolTipString', 'Channel #1 in the recorded file', ...
'FontSize', 8, ...
'Tag','recch1edit');

uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.23 0.67 0.07 0.1],...
'Style', 'edit', ...
'String', 'nan',...
'ToolTipString', 'Channel #2 in the recorded file', ...
'FontSize', 8, ...
'Tag','recch2edit');

uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.23 0.56 0.07 0.1],...
'Style', 'edit', ...
'String', 'nan',...
'ToolTipString', 'Channel #3 in the recorded file', ...
'FontSize', 8, ...
'Tag','recch3edit');

uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.23 0.45 0.07 0.1],...
'Style', 'edit', ...
'String', 'nan',...
'ToolTipString', 'Channel #4 in the recorded file', ...
'FontSize', 8, ...
'Tag','recch4edit');

uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.23 0.34 0.07 0.1],...
'Style', 'edit', ...
'String', 'nan',...
'ToolTipString', 'Channel #5 in the recorded file', ...
'FontSize', 8, ...
'Tag','recch5edit');

uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.23 0.23 0.07 0.1],...
'Style', 'edit', ...
'String', 'nan',...
'ToolTipString', 'Channel #6 in the recorded file', ...
'FontSize', 8, ...
'Tag','recch6edit');

uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.31 0.78 0.07 0.1],...
'Style', 'edit', ...
'String', 'nan',...
'ToolTipString', 'Channel #7 in the recorded file', ...
'FontSize', 8, ...
'Tag','recch7edit');

uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.31 0.67 0.07 0.1],...
'Style', 'edit', ...
'String', 'nan',...
'ToolTipString', 'Channel #8 in the recorded file', ...
'FontSize', 8, ...
'Tag','recch8edit');

uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.31 0.56 0.07 0.1],...
'Style', 'edit', ...
'String', 'nan',...
'ToolTipString', 'Channel #9 in the recorded file', ...
'FontSize', 8, ...
'Tag','recch9edit');

uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.31 0.45 0.07 0.1],...
'Style', 'edit', ...
'String', 'nan',...
'ToolTipString', 'Channel #10 in the recorded file', ...
'FontSize', 8, ...
'Tag','recch10edit');

uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.31 0.34 0.07 0.1],...
'Style', 'edit', ...
'String', 'nan',...
'ToolTipString', 'Channel #11 in the recorded file', ...
'FontSize', 8, ...
'Tag','recch11edit');

uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.31 0.23 0.07 0.1],...
'Style', 'edit', ...
'String', 'nan',...
'ToolTipString', 'Channel #12 in the recorded file', ...
'FontSize', 8, ...
'Tag','recch12edit');

%Stim and command channel parameters
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.385 0.02 0.002 0.96],...
'Style', 'frame', ...
'BackgroundColor', 'k');

uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.39 0.88 0.3 0.1],...
'Style', 'text', ...
'String','Stims and Comands',...
'BackgroundColor', a, ...
'FontSize', 12, ...
'FontWeight', 'bold');

uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.39 0.78 0.05 0.1],...
'Style', 'edit', ...
'String', 'nan',...
'Callback', ['if strcmp(get(findobj(''Tag'', ''comch1edit''), ''String''), ''nan'');', ...
    'set(findobj(''Tag'', ''comch1text''), ''String'', ''?''); end'], ...
'ToolTipString', 'Analog output channel #1', ...
'FontSize', 8, ...
'Tag','comch1edit');
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.39 0.67 0.05 0.1],...
'Style', 'edit', ...
'String', 'nan',...
'Callback', ['if strcmp(get(findobj(''Tag'', ''comch2edit''), ''String''), ''nan'');', ...
    'set(findobj(''Tag'', ''comch2text''), ''String'', ''?''); end'], ...
'ToolTipString', 'Analog output channel #2', ...
'FontSize', 8, ...
'Tag','comch2edit');
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.39 0.56 0.05 0.1],...
'Style', 'edit', ...
'String', 'nan',...
'Callback', ['if strcmp(get(findobj(''Tag'', ''comch3edit''), ''String''), ''nan'');', ...
    'set(findobj(''Tag'', ''comch3text''), ''String'', ''?''); end'], ...
'ToolTipString', 'Analog output channel #3', ...
'FontSize', 8, ...
'Tag','comch3edit');
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.39 0.45 0.05 0.1],...
'Style', 'edit', ...
'String', 'nan',...
'Callback', ['if strcmp(get(findobj(''Tag'', ''comch4edit''), ''String''), ''nan'');', ...
    'set(findobj(''Tag'', ''comch4text''), ''String'', ''?''); end'], ...
'ToolTipString', 'Analog output channel #4', ...
'FontSize', 8, ...
'Tag','comch4edit');

h1 = uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.45 0.78 0.17 0.1],...
'Style', 'text', ...
'String', '?',...
'UserData', '', ...
'FontSize', 8, ...
'Tag','comch1text');
set(h1, 'ToolTipString', ['Stim. file for AO #1: ', get(h1, 'UserData'), get(h1, 'String')]);
h1 = uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.45 0.67 0.17 0.1],...
'Style', 'text', ...
'String', '?',...
'UserData', '', ...
'FontSize', 8, ...
'Tag','comch2text');
set(h1, 'ToolTipString', ['Stim. file for AO #2: ', get(h1, 'UserData'), get(h1, 'String')]);
h1 = uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.45 0.56 0.17 0.1],...
'Style', 'text', ...
'String', '?',...
'UserData', '', ...
'FontSize', 8, ...
'Tag','comch3text');
set(h1, 'ToolTipString', ['Stim. file for AO #3: ', get(h1, 'UserData'), get(h1, 'String')]);
h1 = uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.45 0.45 0.17 0.1],...
'Style', 'text', ...
'String', '?',...
'UserData', '', ...
'FontSize', 8, ...
'Tag','comch4text');
set(h1, 'ToolTipString', ['Stim. file for AO #4: ', get(h1, 'UserData'), get(h1, 'String')]);

uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.63 0.78 0.06 0.1],...
'String','Browse',...
'Callback', 'acq_findfile(1);', ...
'ToolTipString', 'Find file for AO #1', ...
'FontSize', 8);
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.63 0.67 0.06 0.1],...
'String','Browse',...
'Callback', 'acq_findfile(2);', ...
'ToolTipString', 'Find file for AO #2', ...
'FontSize', 8);
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.63 0.56 0.06 0.1],...
'String','Browse',...
'Callback', 'acq_findfile(3);', ...
'ToolTipString', 'Find file for AO #3', ...
'FontSize', 8);
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.63 0.45 0.06 0.1],...
'String','Browse',...
'Callback', 'acq_findfile(4);', ...
'ToolTipString', 'Find file for AO #4', ...
'FontSize', 8);


%Trigger
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.39 0.34 0.3 0.1],...
'Style', 'text', ...
'String','Trigger configuration',...
'BackgroundColor', a, ...
'FontSize', 12, ...
'FontWeight', 'bold');

uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.39 0.24 0.07 0.08],...
'Style', 'text', ...
'HorizontalAlignment', 'left', ...
'String','Trigger ch.',...
'BackgroundColor', a, ...
'FontSize', 8);
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.465 0.24 0.075 0.1],...
'Style', 'popup', ...
'String','AI 0|AI 1|AI 2|AI 3|AI 4|AI 5|AI 6|AI 7|AI 8|AI 9|AI 10|AI 11|AI 12|AI 13|AI 14|AI 15|AI 16|AI 17|AI 18|AI 19|AI 20|AI 21|AI 22|AI 23|AI 24|AI 25|AI 26|AI 27|AI 28|AI 29|AI 30|AI 31',...
'ToolTipString', 'Channel that triggers acquisition', ...
'FontSize', 8, ...
'Visible', 'on', ...
'Tag', 'rectriggerchanneledit');

uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.39 0.13 0.1 0.08],...
'Style', 'text', ...
'HorizontalAlignment', 'left', ...
'String','Trigger thresh.',...
'BackgroundColor', a, ...
'FontSize', 8);
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.5 0.13 0.04 0.1],...
'Style', 'edit', ...
'String', '?',...
'ToolTipString', 'Trigger threshold level. This is Volts into the trigger channel.', ...
'FontSize', 8, ...
'Visible', 'on', ...
'Tag', 'recthresholdedit');

uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.39 0.02 0.1 0.08],...
'Style', 'text', ...
'HorizontalAlignment', 'left', ...
'String','Pre/post trig.',...
'BackgroundColor', a, ...
'FontSize', 8);
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.5 0.02 0.04 0.1],...
'Style', 'edit', ...
'String', '0',...
'Callback', ['if get(findobj(''Tag'', ''recpiftriggerradio''), ''Value'')==1; ', ...
    'str=get(findobj(''Tag'', ''rectimedelayedit''), ''String'');', ...
    'if str2num(str)<0;', ...
    'warndlg(''Only Post-triggers allowed!'');', ...
    'set(findobj(''Tag'', ''rectimedelayedit''), ''String'', num2str(abs(str2num(str)))); end;', ...
    'end;'], ...
'ToolTipString', 'Length, in ms, of the pre/post-trigger (negative values for pre-triggers and positive values for post-triggers)', ...
'FontSize', 8, ...
'Tag', 'rectimedelayedit');

uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.55 0.24 0.05 0.08],...
'Style', 'text', ...
'HorizontalAlignment', 'left', ...
'String','Cond.',...
'BackgroundColor', a, ...
'FontSize', 8);
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.6 0.24 0.09 0.1],...
'Style', 'popup', ...
'String','Rising|Falling',...
'ToolTipString', 'Trigger condition', ...
'FontSize', 8, ...
'Tag', 'rectriggerconditionedit');
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.55 0.13 0.045 0.1],...
'Style', 'radio', ...
'HorizontalAlignment', 'left', ...
'String','AO',...
'Callback', ['if get(findobj(''Tag'', ''recaotriggerradio''), ''Value'')==1; ', ...
    'set(findobj(''Tag'', ''recaotriggertext''), ''Visible'', ''On'');', ...
    'set(findobj(''Tag'', ''recpiftriggerradio''), ''Visible'', ''Off'');', ...
    'set(findobj(''Tag'', ''recaitriggerradio''), ''Visible'', ''Off'');', ...
    'else; set(findobj(''Tag'', ''recpiftriggerradio''), ''Visible'', ''On'');', ...
    'set(findobj(''Tag'', ''recaitriggerradio''), ''Visible'', ''On'');', ...
    'set(findobj(''Tag'', ''recaotriggertext''), ''Visible'', ''Off''); end;'], ...
'BackgroundColor', a, ...
'FontSize', 8, ...
'Value', 0, ...
'Visible', 'on', ...
'ToolTipString', 'An analog output triggers the start of acquisition (Set Trigger ch. to the corresponding AI).', ...
'Tag', 'recaotriggerradio');
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.595 0.13 0.06 0.075],...
'Style', 'text', ...
'HorizontalAlignment', 'left', ...
'String','trigger',...
'BackgroundColor', a, ...
'FontSize', 8, ...
'Visible', 'off', ...
'Tag', 'recaotriggertext');
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.6 0.13 0.09 0.1],...
'Style', 'radio', ...
'HorizontalAlignment', 'left', ...
'String','AI trigger',...
'Callback', ['if get(findobj(''Tag'', ''recaitriggerradio''), ''Value'')==1; ', ...
    'set(findobj(''Tag'', ''recpiftriggerradio''), ''Visible'', ''Off'');', ...
    'set(findobj(''Tag'', ''recaotriggerradio''), ''Visible'', ''Off'');', ...
    'else; set(findobj(''Tag'', ''recpiftriggerradio''), ''Visible'', ''On'');', ... 
    'set(findobj(''Tag'', ''recaotriggerradio''), ''Visible'', ''On''); end;'], ...
'BackgroundColor', a, ...
'FontSize', 8, ...
'Value', 0, ...
'Visible', 'on', ...
'ToolTipString', 'An analog input triggers the start of acquisition (Set Trigger ch. to the corresponding AI).', ...
'Tag', 'recaitriggerradio');
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.55 0.02 0.14 0.1],...
'Style', 'radio', ...
'HorizontalAlignment', 'left', ...
'String','PFI trigger',...
'Callback', ['if get(findobj(''Tag'', ''recpiftriggerradio''), ''Value'')==1; ', ...
    'set(findobj(''Tag'', ''rectriggerchanneledit''), ''Visible'', ''Off'');', ...
    'set(findobj(''Tag'', ''recthresholdedit''), ''Visible'', ''Off'');', ...
    'set(findobj(''Tag'', ''recaotriggerradio''), ''Visible'', ''Off'');', ...
    'set(findobj(''Tag'', ''recaitriggerradio''), ''Visible'', ''Off'');', ...
    'str=get(findobj(''Tag'', ''rectimedelayedit''), ''String'');', ...
    'if str2num(str)<0;', ...
    'warndlg(''Only Post-triggers allowed!'');', ...
    'set(findobj(''Tag'', ''rectimedelayedit''), ''String'', num2str(abs(str2num(str)))); end;', ...
    'else; set(findobj(''Tag'', ''rectriggerchanneledit''), ''Visible'', ''On'');', ...
    'set(findobj(''Tag'', ''recaotriggerradio''), ''Visible'', ''On'');', ...
    'set(findobj(''Tag'', ''recaitriggerradio''), ''Visible'', ''On'');', ...
    'set(findobj(''Tag'', ''recthresholdedit''), ''Visible'', ''On''); end;'], ...
'BackgroundColor', a, ...
'FontSize', 8, ...
'Value', 0, ...
'Visible', 'off', ...
'ToolTipString', 'PIF triggers the start of acquisition (HwDigital is the TriggerType, For AI ONLY: TriggerCondition Rising is PositiveEdge, Falling is NegativeEdge).', ...
'Tag', 'recpiftriggerradio');


%Cell parameters calculator
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.695 0.02 0.002 0.96],...
'Style', 'frame', ...
'BackgroundColor', 'k');

uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.7 0.88 0.04 0.1],...
'Style', 'radiobutton', ...
'HorizontalAlignment', 'left', ...
'String','Rs',...
'ToolTipString', 'Perform online Rs calculation', ...
'FontSize', 8, ...
'BackgroundColor', a, ...
'Value', 0, ...
'Tag', 'recrsradio');
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.74 0.88 0.04 0.1],...
'Style', 'radiobutton', ...
'HorizontalAlignment', 'left', ...
'String','Ri',...
'ToolTipString', 'Perform online Ri calculation', ...
'BackgroundColor', a, ...
'FontSize', 8, ...
'Value', 0, ...
'Tag', 'recriradio');
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.78 0.88 0.04 0.1],...
'Style', 'radiobutton', ...
'HorizontalAlignment', 'left', ...
'String','Cm',...
'ToolTipString', 'Perform online Cm calculation', ...
'BackgroundColor', a, ...
'FontSize', 8, ...
'Tag', 'reccmradio');
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.82 0.88 0.06 0.1],...
'Style', 'radiobutton', ...
'HorizontalAlignment', 'left', ...
'String','Mean',...
'ToolTipString', 'Perform online trace averaging', ...
'BackgroundColor', a, ...
'FontSize', 8, ...
'Tag', 'recmeanradio');

uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.7 0.78 0.1 0.08],...
'Style', 'text', ...
'HorizontalAlignment', 'left', ...
'String','Test pulse amp.',...
'BackgroundColor', a, ...
'FontSize', 8);
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.81 0.78 0.04 0.1],...
'Style', 'edit', ...
'String','',...
'ToolTipString', 'Test pulse amplitude in mV.', ...
'FontSize', 8, ...
'Tag', 'rectestamplitudeedit');

uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.7 0.67 0.1 0.08],...
'Style', 'text', ...
'HorizontalAlignment', 'left', ...
'String','Test pulse dur.',...
'BackgroundColor', a, ...
'FontSize', 8);
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.81 0.67 0.04 0.1],...
'Style', 'edit', ...
'String','',...
'ToolTipString', 'Test pulse duration in ms.', ...
'FontSize', 8, ...
'Tag', 'rectestlengthedit');

uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.7 0.56 0.1 0.08],...
'Style', 'text', ...
'HorizontalAlignment', 'left', ...
'String','Rs window',...
'BackgroundColor', a, ...
'FontSize', 8);
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.81 0.56 0.04 0.1],...
'Style', 'edit', ...
'String','',...
'ToolTipString', 'Length of the window over which peak current is searched to calculate series resistance (in ms).', ...
'FontSize', 8, ...
'Tag', 'recrsedit');

uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.7 0.45 0.1 0.08],...
'Style', 'text', ...
'HorizontalAlignment', 'left', ...
'String','Ri window',...
'BackgroundColor', a, ...
'FontSize', 8);
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.81 0.45 0.04 0.1],...
'Style', 'edit', ...
'String','',...
'ToolTipString', 'Length of the window over which current is averaged to calculate input resistance (in ms). NOTE: it must be bigger than 1ms.', ...
'FontSize', 8, ...
'Tag', 'recriedit');

uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.7 0.34 0.1 0.06],...
'Style', 'text', ...
'HorizontalAlignment', 'left', ...
'String','Baseline',...
'BackgroundColor', a, ...
'FontSize', 8);
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.77 0.34 0.04 0.1],...
'Style', 'edit', ...
'String', '0',...
'ToolTipString', 'Length of the baseline in ms.', ...
'FontSize', 8, ...
'Tag', 'recbaseedit');
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.81 0.34 0.04 0.1],...
'Style', 'edit', ...
'String', '0',...
'ToolTipString', 'Start of test pulse in ms. after the start of the sweep', ...
'FontSize', 8, ...
'Tag', 'rectestpulsestartedit');

%File to save the data
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.88 0.88 0.09 0.1],...
'Style', 'text', ...
'String','Data file',...
'BackgroundColor', a, ...
'FontSize', 12, ...
'FontWeight', 'bold');

h1 = uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.86 0.78 0.13 0.1],...
'Style', 'edit', ...
'String', '?',...
'UserData', '', ...
'Callback', 'set(findobj(''Tag'', ''recfiletext''), ''ToolTipString'', [get(findobj(''Tag'', ''recfiletext''), ''UserData''), get(findobj(''Tag'', ''recfiletext''), ''String'')]);', ...
'FontSize', 8, ...
'Tag', 'recfiletext');

uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.86 0.67 0.13 0.1],...
'String','Browse',...
'Callback', 'acq_findfile(5);', ...
'FontSize', 10);
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.86 0.56 0.13 0.1],...
'Style', 'radiobutton', ...
'String','Do not record',...
'BackgroundColor', a, ...
'FontSize', 8, ...
'Value', 0, ...
'Tag', 'donotrecordradio');

%Stimulator
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.855 0.33 0.14 0.24],...
'Style', 'frame', ...
'BackgroundColor', 'k');
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.86 0.45 0.13 0.1],...
'String','Stimulator',...
'Callback', 'acq_stim;', ...
'ToolTipString', 'Outputs a +5V square pulse', ...
'FontSize', 8);
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.86 0.34 0.04 0.1],...
'Style', 'edit', ...
'String', '0.1',...
'ToolTipString', 'Length of the stimulation (+5V) pulse to output in ms (minimum duration is 0.1)', ...
'Callback', ['if str2double(get(findobj(''Tag'', ''stimulationdurationedit''), ''string''))<0.1;', ...
'set(findobj(''Tag'', ''stimulationdurationedit''), ''string'', ''0.1''); end;'], ...
'FontSize', 8, ...
'Tag', 'stimulationdurationedit');
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.91 0.33 0.08 0.1],...
'Style', 'popup', ...
'String','AO 0|AO 1|AO 2|AO 3',...
'Value', 2, ...
'ToolTipString', 'AO channel where the stimulation (+5V) pulse goes', ...
'FontSize', 8, ...
'Tag', 'stimulationchannelnedit');

%Acquisition rate for recording
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.7 0.15 0.15 0.16],...
'Style', 'frame', ...
'BackgroundColor', 'k');
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.705 0.245 0.14 0.055],...
'String','Acquisition rate',...
'Style', 'text', ...
'BackgroundColor', a, ...
'FontWeight', 'bold');
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.705 0.16 0.14 0.07],...
'String', get(findobj('Tag', 'samplerateedit'), 'String'),...
'Style', 'edit', ...
'ToolTipString', 'Acquisition rate in Hz', ...
'Tag', 'recsamplerateedit');

%Record acquisition button
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.86 0.04 0.13 0.24],...
'String','Record',...
'Callback', ['if strcmp(''Stop'', get(findobj(''tag'', ''recbutton''), ''String''));', ...
'set(findobj(''tag'', ''recstatustext''), ''String'', ''Stopping...'');', ...
'else;', ...
'acq_rec;', ...
'end;'], ...
'ToolTipString', 'Start or stop recording', ...
'FontSize', 12, ...
'FontWeight', 'bold', ...
'Tag', 'recbutton');


%Error reset button
uicontrol(...
'Parent',h0,...
'Units','normalized',...
'Position',[0.75 0.04 0.1 0.1],...
'String','Reset',...
'Callback', ['if strcmp(''Stop'', get(findobj(''tag'', ''recbutton''), ''String''));', ...
'fclose all;', ...
'set(findobj(''tag'', ''recbutton''), ''String'', ''Record'');', ...
'set(findobj(''Tag'',''recstatustext''), ''String'', ''Ready'');', ...
'set(findobj(''Tag'',''acqnumbertext''), ''String'', ''0'');', ...
'set(findobj(''Tag'', ''resetgraphbutton''), ''Visible'', ''on'');', ...
'set(findobj(''Tag'', ''startsealbutton''), ''Visible'', ''on'');', ...
'end;'], ...
'ToolTipString', 'Resets the acquisition system after an error');