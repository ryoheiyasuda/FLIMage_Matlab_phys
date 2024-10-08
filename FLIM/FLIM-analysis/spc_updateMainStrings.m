function spc_updateMainStrings
global spc;
global gui;
%global spcs;

if isfield(gui, 'spc')
    if isfield(gui.spc, 'spc_main')
		handles = gui.spc.spc_main;
		range = round(spc.fit.range.*spc.datainfo.psPerUnit/100)/10;
		set(handles.spc_fitstart, 'String', num2str(range(1)));
		set(handles.spc_fitend, 'String', num2str(range(2)));
		set(handles.filename, 'String', spc.filename);
        try
            set(handles.spc_page, 'String', num2str(spc.switches.currentPage));
		    set(handles.slider1, 'Value', (spc.switches.currentPage-1)/100);
        end
%         try
% 		    set(handles.spcN, 'String', num2str(spcs.current));    
% 		    set(handles.slider2, 'Value', (spcs.current-1)/100);
%         end
        try
            %set(handles.slider1, 'max', size(spc.stack.images, 2)/100);
            set(handles.spc_page, 'String', num2str(spc.page));
            set(handles.slider1, 'Value', (spc.page-1)/100);
        end
        try
            [filepath, basename, filenumber, max] = spc_AnalyzeFilename(spc.filename);
            set(handles.File_N, 'String', num2str(filenumber));
        end
    end
    
    if isfield(gui.spc, 'lifetimerange')
        try
            hg = gui.spc.lifetimerange;
            set(hg.upper, 'String', num2str(spc.switches.lifetime_limit(2)));
            set(hg.lower, 'String', num2str(spc.switches.lifetime_limit(1)));
        catch
        end
        try %for the compatibility with old files.
            set(hg.spc_thresh, 'String', num2str(spc.switches.lutlim(2)));
            set(hg.spc_lowthresh, 'String', num2str(spc.switches.lutlim(1)));
        catch
            try
                set(hg.spc_thresh, 'String', num2str(spc.switches.threshold));
                set(hg.spc_lowthresh, 'String', '0');
            catch
            end
        end
    end
end

try
 spc_dispbeta;
catch
  %disp('Error in spc_dispbeta !! main strings are not updated'); 
end