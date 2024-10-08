function varargout = spc_main(varargin)
% SPC_MAIN Application M-file for spc_main.fig
%    FIG = SPC_MAIN launch spc_main GUI.
%    SPC_MAIN('callback_name', ...) invoke the named callback.

% Last Modified by GUIDE v2.5 06-Sep-2006 14:10:10
global gui;
global spc;

if nargin == 0  % LAUNCH GUI

	fig = openfig(mfilename,'reuse');
    
	% Generate a structure of handles to pass to callbacks, and store it. 
	handles = guihandles(fig);
    gui.spc.spc_main = handles;
	guidata(fig, handles);

	if nargout > 0
		varargout{1} = fig;
	end
    
    try
        spc.fit.beta0 = [1.8437e+003 10.1263 2.1007e+003 2.7551 5.7457 0.4692];
        range = round(spc.fit.range.*spc.datainfo.psPerUnit/100)/10;
        set(handles.spc_fitstart, 'String', num2str(range(1)));
        set(handles.spc_fitend, 'String', num2str(range(2)));
        set(handles.back_value, 'String', num2str(spc.fit.background));
        set(handles.filename, 'String', spc.filename);
        set(handles.spc_page, 'String', num2str(spc.switches.currentPage));
        set(handles.slider1, 'Value', (spc.switches.currentPage-1)/100);
        spc_dispbeta;
    catch
    end;
   set (handles.selectAll, 'Value', 1);    

elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK

	try
		if (nargout)
			[varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
		else
			feval(varargin{:}); % FEVAL switchyard
		end
	catch
		disp(lasterr);
	end

end


%| ABOUT CALLBACKS:
%| GUIDE automatically appends subfunction prototypes to this file, and 
%| sets objects' callback properties to call them through the FEVAL 
%| switchyard above. This comment describes that mechanism.
%|
%| Each callback subfunction declaration has the following form:
%| <SUBFUNCTION_NAME>(H, EVENTDATA, HANDLES, VARARGIN)
%|
%| The subfunction name is composed using the object's Tag and the 
%| callback type separated by '_', e.g. 'slider2_Callback',
%| 'figure1_CloseRequestFcn', 'axis1_ButtondownFcn'.
%|
%| H is the callback object's handle (obtained using GCBO).
%|
%| EVENTDATA is empty, but reserved for future use.
%|
%| HANDLES is a structure containing handles of components in GUI using
%| tags as fieldnames, e.g. handles.figure1, handles.slider2. This
%| structure is created at GUI startup using GUIHANDLES and stored in
%| the figure's application data using GUIDATA. A copy of the structure
%| is passed to each callback.  You can store additional information in
%| this structure at GUI startup, and you can change the structure
%| during callbacks.  Call guidata(h, handles) after changing your
%| copy to replace the stored original so that subsequent callbacks see
%| the updates. Type "help guihandles" and "help guidata" for more
%| information.
%|
%| VARARGIN contains any extra arguments you have passed to the
%| callback. Specify the extra arguments by editing the callback
%| property in the inspector. By default, GUIDE sets the property to:
%| <MFILENAME>('<SUBFUNCTION_NAME>', gcbo, [], guidata(gcbo))
%| Add any extra arguments after the last argument, before the final
%| closing parenthesis.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Menu bar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%File menu
% --------------------------------------------------------------------
function varargout = spc_file_Callback(h, eventdata, handles, varargin)
% --------------------------------------------------------------------
function varargout = spc_open_Callback(h, eventdata, handles, varargin)
global spc;
global spcs;
global gui;
%spc.fit.range(1) = 	str2num(get(handles.spc_fitstart, 'String'))/spc.datainfo.psPerUnit*1000;
%spc.fit.range(2) =	str2num(get(handles.spc_fitend, 'String'))/spc.datainfo.psPerUnit*1000;
page = str2num(get(handles.spc_page, 'String'));

[fname,pname] = uigetfile('*.sdt;*.mat;*.tif','Select spc-file');
cd (pname);
filestr = [pname, fname];
if exist(filestr) == 2
        spc_openCurves(filestr, page);
end
%spc_putIntoSPCS;
spc_updateMainStrings;

%%%Put into spc array if there is no state


% --------------------------------------------------------------------
function varargout = openall_Callback(h, eventdata, handles, varargin)
global spc
%spc.fit.range(1) = 	str2num(get(handles.spc_fitstart, 'String'))/spc.datainfo.psPerUnit*1000;
%spc.fit.range(2) =	str2num(get(handles.spc_fitend, 'String'))/spc.datainfo.psPerUnit*1000;
%spc_openAll;
spc_updateMainStrings;
% --------------------------------------------------------------------
function varargout = spc_loadPrf_Callback(h, eventdata, handles, varargin)
global spc;
[fname,pname] = uigetfile('*.mat','Select mat-file');
if exist([pname, fname]) == 2
    load ([pname,fname], 'prf');
end
spc.fit.prf = prf;

% --------------------------------------------------------------------
function varargout = spc_savePrf_Callback(h, eventdata, handles, varargin)
global spc;
[fname,pname] = uiputfile('*.mat','Select the mat-file');
prf = spc.fit.prf;
%if (pname == 7) & (fname ~= '')
    save ([pname,fname], 'prf');
%end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Fitting menu
% --------------------------------------------------------------------
function varargout = spc_fitting_Callback(h, eventdata, handles, varargin)
% --------------------------------------------------------------------
function varargout = spc_exps_Callback(h, eventdata, handles, varargin)
global spc
range = spc.fit.range;
lifetime = spc.lifetime(range(1):1:range(2));
x = [1:1:length(lifetime)];
beta0 = [max(lifetime), sum(lifetime)/max(lifetime)];
betahat = spc_nlinfit(x, lifetime, sqrt(lifetime)/sqrt(max(lifetime)), @expfit, beta0);
tau = betahat(2)*spc.datainfo.psPerUnit/1000;
set(handles.beta1, 'String', num2str(betahat(1)));
set(handles.beta2, 'String', num2str(tau));
set(handles.beta3, 'String', '0');
set(handles.beta4, 'String', '0');
set(handles.beta5, 'String', '0');
set(handles.pop1, 'String', '100');
set(handles.pop2, 'String', '0');
set(handles.average, 'String', num2str(tau));

%Drawing
fit = expfit(betahat, x);
t = [range(1):1:range(2)];
t = t*spc.datainfo.psPerUnit/1000;
spc_drawfit (t, fit, lifetime, betahat);


function y=expfit(beta0, x);
global spc;
if spc.switches.imagemode == 1
    spc_roi = get(spc.figure.roi, 'Position');
else
    spc_roi = [1,1,1,1]
end;
y=exp(-x/beta0(2))*beta0(1);

% --------------------------------------------------------------------
function varargout = spc_expgauss_Callback(h, eventdata, handles, varargin)
global spc;
range = spc.fit.range;
betahat=spc_fitexpgauss;
spc_dispbeta;
% --------------------------------------------------------------------
function varargout = spc_exp2gauss_Callback(h, eventdata, handles, varargin)
global spc;
range = spc.fit.range;
betahat=spc_fitexp2gauss;
spc_dispbeta;

% --------------------------------------------------------------------
function varargout = expgauss_triple_Callback(h, eventdata, handles, varargin)
spc_fitWithSingleExp_triple;

% --------------------------------------------------------------------
function varargout = Double_expgauss_triple_Callback(h, eventdata, handles, varargin)
spc_fitWithDoubleExp_triple;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Drawing menu
% --------------------------------------------------------------------
function varargout = spc_drawing_Callback(h, eventdata, handles, varargin)
% --------------------------------------------------------------------
function varargout = spc_drawall_Callback(h, eventdata, handles, varargin)
spc_spcsUpdate;
spc_redrawSetting;

% --------------------------------------------------------------------
function varargout = logscale_Callback(h, eventdata, handles, varargin)
spc_logscale;
% --------------------------------------------------------------------
function varargout = lifetime_map_Callback(h, eventdata, handles, varargin)
twodialog;
% --------------------------------------------------------------------
function varargout = show_all_Callback(h, eventdata, handles, varargin)
spc_drawLifetimeMap_All(0);
% --------------------------------------------------------------------
function varargout = redraw_all_Callback(h, eventdata, handles, varargin)
spc_drawLifetimeMap_All(1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Analysis menu
% --------------------------------------------------------------------
function varargout = analysis_Callback(h, eventdata, handles, varargin)
% --------------------------------------------------------------------
function varargout = smoothing_Callback(h, eventdata, handles, varargin)
spc_smooth;
% --------------------------------------------------------------------
function varargout = binning_Callback(h, eventdata, handles, varargin)
spc_binning;

% --------------------------------------------------------------------
function varargout = smooth_all_Callback(h, eventdata, handles, varargin)
spc_smoothAll;

% --------------------------------------------------------------------
function varargout = binning_all_Callback(h, eventdata, handles, varargin)
spc_binningAll;

% --------------------------------------------------------------------
function varargout = undoall_Callback(h, eventdata, handles, varargin)
spc_undoAll;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Buttons
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --------------------------------------------------------------------
function varargout = spc_fit1_Callback(h, eventdata, handles, varargin)
global spc;
betahat=spc_fitexpgauss;
spc_dispbeta;

% --------------------------------------------------------------------
function varargout = spc_fit2_Callback(h, eventdata, handles, varargin)
global spc;
betahat=spc_fitexp2gauss;
spc_dispbeta;

% --------------------------------------------------------------------
function varargout = spc_look_Callback(h, eventdata, handles, varargin)
global spc;
range = spc.fit.range;
lifetime = spc.lifetime(range(1):1:range(2));
x = [1:1:length(lifetime)];
beta0 = spc_initialValue_double;

% pop1 = beta0(1)/(beta0(1)+beta0(3));
% pop2 = beta0(3)/(beta0(1)+beta0(3));
% set(handles.pop1, 'String', num2str(pop1));
% set(handles.pop2, 'String', num2str(pop2));

%Drawing
fit = exp2gauss(beta0, x);
t = [range(1):1:range(2)];
t = t*spc.datainfo.psPerUnit/1000;

%Drawing
spc_drawfit (t, fit, lifetime, beta0);
spc_dispbeta;

% --------------------------------------------------------------------
function varargout = spc_redraw_Callback(h, eventdata, handles, varargin)
global spc;
fitstart = round(str2num(get(handles.spc_fitstart, 'String'))*1000/spc.datainfo.psPerUnit);
fitend = round(str2num(get(handles.spc_fitend, 'String'))*1000/spc.datainfo.psPerUnit);
if fitstart < 1
    fitstart = 1;
end
if fitend <0
    fitend = spc.size(1);
end
if fitend < fitstart
    fitend = spc.size(1);
    fitstart = 1;
end
spc.fit.range = [fitstart, fitend];
%spc_drawProject;
%spc_drawLifetime;
%spc_drawLifetimeMap;
spc_redrawSetting;
spc_spcsUpdate;

range = round(spc.fit.range.*spc.datainfo.psPerUnit/100)/10;
set(handles.spc_fitstart, 'String', num2str(range(1)));
set(handles.spc_fitend, 'String', num2str(range(2)));
set(handles.filename, 'String', spc.filename);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Beta windows
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --------------------------------------------------------------------
function varargout = beta1_Callback(h, eventdata, handles, varargin)
% --------------------------------------------------------------------
function varargout = beta2_Callback(h, eventdata, handles, varargin)
% --------------------------------------------------------------------
function varargout = beta3_Callback(h, eventdata, handles, varargin)
% --------------------------------------------------------------------
function varargout = beta4_Callback(h, eventdata, handles, varargin)
% --------------------------------------------------------------------
function varargout = beta5_Callback(h, eventdata, handles, varargin)
% --------------------------------------------------------------------
function varargout = beta6_Callback(hObject, eventdata, handles)
% --------------------------------------------------------------------
function varargout = spc_fitstart_Callback(h, eventdata, handles, varargin)
% --------------------------------------------------------------------
function varargout = spc_fitend_Callback(h, eventdata, handles, varargin)
% --------------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Spc, page control
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = spc_page_Callback(h, eventdata, handles, varargin)
global spc;

page = str2num(get(handles.spc_page, 'String'));
current = spc.page;
spc.page = page;


if current ~= spc.page
    spc_openCurves(spc.filename, spc.page);
    spc_redrawSetting;
end

spc_updateMainStrings;



% --------------------------------------------------------------------
function varargout = slider1_Callback(h, eventdata, handles, varargin)
global spc

slider_value = get(handles.slider1, 'Value');
slider_step = get(handles.slider1, 'sliderstep');
page = slider_value*100+1;

current = spc.page;
spc.page = page;


if current ~= spc.page
    spc_openCurves(spc.filename, spc.page);
    spc_redrawSetting;
end

spc_updateMainStrings;


% --------------------------------------------------------------------
function varargout = spcN_Callback(h, eventdata, handles, varargin)
global spcs;
global spc;

spcN = str2num(get(handles.spcN, 'String'));

spc_changeCurrent(spcN);

%set(handles.spcN, 'String', num2str(spcs.current));
%set(handles.slider2, 'Value', (spcs.current-1)/100);
%set(handles.filename, 'String', num2str(spc.filename));
spc_updateMainStrings;

% --------------------------------------------------------------------
function varargout = slider2_Callback(h, eventdata, handles, varargin)

slider_value = get(handles.slider2, 'Value');
slider_step = get(handles.slider2, 'sliderstep');
spcN = slider_value*100+1;

spc_changeCurrent(spcN);
    
%set(handles.spcN, 'String', num2str(spcs.current));
%set(handles.slider2, 'Value', (spcs.current-1)/100);
%set(handles.filename, 'String', num2str(spc.filename));
spc_updateMainStrings;


% --------------------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Utilities
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = fixtau1_Callback(h, eventdata, handles, varargin)
global spc;
spc.fit.fixtau1 = get(h, 'Value');

function varargout = fixtau2_Callback(h, eventdata, handles, varargin)
global spc;
spc.fit.fixtau2 = get(h, 'Value');

% --- Executes on button press in fix_g.
function fix_g_Callback(hObject, eventdata, handles)
global spc;
spc.fit.fix_g = get(hObject, 'Value');

% --- Executes on button press in fix_delta.
function fix_delta_Callback(hObject, eventdata, handles)
global spc;
spc.fit.fix_delta = get(hObject, 'Value');

% --- Executes on button press in pushbutton14.
function pushbutton14_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%timecourse.

spc_auto(1);





% --- Executes during object creation, after setting all properties.
function beta6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to beta6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


% --- Executes on button press in pushbutton15.
function pushbutton15_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton15 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in spc_opennext. Open the next file.
function spc_opennext_Callback(hObject, eventdata, handles)
% hObject    handle to spc_opennext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
spc_opennext;


% --- Executes on button press in spc_openprevious. Open the Previous file.
function spc_openprevious_Callback(hObject, eventdata, handles)
% hObject    handle to spc_openprevious (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
spc_openprevious;


% --------------------------------------------------------------------
function Roi_Callback(hObject, eventdata, handles)
% hObject    handle to Roi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Roi1_Callback(hObject, eventdata, handles)
% hObject    handle to Roi1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
spc_makeRoiA(1);

% --------------------------------------------------------------------
function Roi2_Callback(hObject, eventdata, handles)
% hObject    handle to Roi2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

spc_makeRoiA(2);
% --------------------------------------------------------------------
function Roi3_Callback(hObject, eventdata, handles)
% hObject    handle to Roi3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
spc_makeRoiA(3);


% --------------------------------------------------------------------
function Roi4_Callback(hObject, eventdata, handles)
% hObject    handle to Roi4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
spc_makeRoiA(4);

% --------------------------------------------------------------------
function Roi5_Callback(hObject, eventdata, handles)
% hObject    handle to Roi5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
spc_makeRoiA(5);

% --------------------------------------------------------------------
function RoiMore_Callback(hObject, eventdata, handles)
% hObject    handle to RoiMore (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
prompt = 'Roi Number:';
dlg_title = 'Roi';
num_lines= 1;
def     = {'6'};
answer  = inputdlg(prompt,dlg_title,num_lines,def);

spc_makeRoiA(str2num(answer{1}));



function File_N_Callback(hObject, eventdata, handles)
% hObject    handle to File_N (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of File_N as text
%        str2double(get(hObject,'String')) returns contents of File_N as a double

global spc;
try
    [filepath, basename, filenumber, max] = spc_AnalyzeFilename(spc.filename);
    fileN = get(handles.File_N, 'String');
    next_filenumber_str = '000';
    next_filenumber_str ((end+1-length(fileN)):end) = num2str(fileN);
    if max == 0
        next_filename = [filepath, basename, next_filenumber_str, '.tif'];
    else
        next_filename = [filepath, basename, next_filenumber_str, '_max.tif'];
    end
    if exist(next_filename)
        spc_openCurves (next_filename);
    else
        disp([next_filename, ' not exist!']);
    end
    spc_updateMainStrings;
end

% --- Executes during object creation, after setting all properties.
function File_N_CreateFcn(hObject, eventdata, handles)
% hObject    handle to File_N (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit14_Callback(hObject, eventdata, handles)
% hObject    handle to edit14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit14 as text
%        str2double(get(hObject,'String')) returns contents of edit14 as a double


% --- Executes during object creation, after setting all properties.
function edit14_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in auto_A.
function auto_A_Callback(hObject, eventdata, handles)
% hObject    handle to auto_A (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

spc_adjustTauOffset;

function F_offset_Callback(hObject, eventdata, handles)
% hObject    handle to F_offset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of F_offset as text
%        str2double(get(hObject,'String')) returns contents of F_offset as a double

spc_redrawSetting (1);

% --- Executes during object creation, after setting all properties.
function F_offset_CreateFcn(hObject, eventdata, handles)
% hObject    handle to F_offset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --------------------------------------------------------------------
function fit_single_prf_Callback(hObject, eventdata, handles)
% hObject    handle to fit_double_prf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global spc

if ~isfield(spc.fit, 'prf');
    spc_prfdefault; 
end
if length(spc.fit.prf) ~= spc.lifetime
    spc_prfdefault;
end

spc_fitWithSingleExp;
spc_dispbeta;
% --------------------------------------------------------------------
function fit_double_prf_Callback(hObject, eventdata, handles)
% hObject    handle to fit_double_prf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global spc

if ~isfield(spc.fit, 'prf');
    spc_prfdefault; 
end
if length(spc.fit.prf) ~= spc.lifetime
    spc_prfdefault;
end

spc_fitWithDoubleExp;
spc_dispbeta;


% --- Executes on button press in fit_eachtime.
function fit_eachtime_Callback(hObject, eventdata, handles)
% hObject    handle to fit_eachtime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of fit_eachtime


% --- Executes on button press in selectAll.
function selectAll_Callback(hObject, eventdata, handles)
% hObject    handle to selectAll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of selectAll


