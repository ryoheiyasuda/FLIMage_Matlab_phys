function spc_saveSPCSetting
global gui;
global spc;
global gh;
%global state;

error1 = 0;
try
	gui.spc.figure.positions.fig1 = get(gui.spc.figure.project, 'Position');
	gui.spc.figure.positions.fig2 = get(gui.spc.figure.lifetime, 'Position');
	gui.spc.figure.positions.fig3 = get(gui.spc.figure.lifetimeMap, 'Position');
    gui.spc.figure.positions.spc_main = get(gui.spc.spc_main.spc_main, 'Position');
    gui.spc.figure.positions.lifetimerange = get(gui.spc.lifetimerange.twodialog, 'Position');
	gui.spc.figure.positions.FLIMimage = get(gh.spc.FLIMimage.figure1, 'Position');
    gui.spc.figure.positions.online = get(gui.spc.online, 'Position');
catch
    disp('error during saving setting ...');
    error1 = 1;
end

fid = fopen('spcm.ini');
[fileName,permission, machineormat] = fopen(fid);
[pathstr,name,ext,versn] = fileparts(fileName);

fclose(fid);
    
if ~error1
	positions = gui.spc.figure.positions;
	save([pathstr, '\flim_gui.mat'], 'positions');
end

if isfield(spc, 'imageMod')
    spc_filename = spc.filename;
    save([pathstr, '\spc_backup.mat'], 'spc_filename');
end