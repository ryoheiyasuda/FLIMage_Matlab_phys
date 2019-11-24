function varargout = FLIMcontrol(varargin)
% FLIMCONTROL Application M-file for FLIMcontrol.fig
%    FIG = FLIMCONTROL launch FLIMcontrol GUI.
%    FLIMCONTROL('callback_name', ...) invoke the named callback.

% Last Modified by GUIDE v2.0 07-Aug-2003 23:48:32

if nargin == 0  % LAUNCH GUI

	fig = openfig(mfilename,'reuse');

	% Use system color scheme for figure:
	set(fig,'Color',get(0,'defaultUicontrolBackgroundColor'));

	% Generate a structure of handles to pass to callbacks, and store it. 
	handles = guihandles(fig);
	guidata(fig, handles);

	if nargout > 0
		varargout{1} = fig;
	end
    
    global gh;
    global state;
    gh.spc.flimControl = handles;
    set(handles.image, 'value', state.spc.acq.spc_image);

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



% --------------------------------------------------------------------
function varargout = image_Callback(h, eventdata, handles, varargin)

global state;

value = get(h, 'value');
state.spc.acq.spc_image = value;

% --------------------------------------------------------------------
function varargout = Focus_Callback(h, eventdata, handles, varargin)
state.internal.whatToDo=1;
spc_executeFocus;


% --------------------------------------------------------------------
function varargout = Grab_Callback(h, eventdata, handles, varargin)
state.internal.whatToDo=2;
spc_executeGrabOne;


% --------------------------------------------------------------------
function varargout = Loop_Callback(h, eventdata, handles, varargin)

spc_executeLoop;