function spc_drawInit;

global state;
global spc;
global spcs;
global gui;
global gh;

    try
        fig1_pos = gui.spc.figure.positions.fig1;
        fig2_pos = gui.spc.figure.positions.fig2;
        fig3_pos = gui.spc.figure.positions.fig3;
    catch
        fig1_pos = [884    59   360   300];
        fig2_pos = [884   389   359   236];
        fig3_pos = [884   701   360   300];
    end
 %Fig1.
    gui.spc.figure.project = figure;
    set(gui.spc.figure.project, 'MenuBar', 'none');
    set(gui.spc.figure.project, 'Position', fig1_pos, 'name', 'Projection');
    %menubar if you want ??
    %f = uimenu('Label','User');
    %uimenu(f, 'Label', 'makeNewRoi', 'Callback', 'spc_makeRoi');
    %uimenu(f, 'Label', 'binning', 'Callback', 'spc_binning');
    roi_context = uicontextmenu;
	gui.spc.figure.projectImage = image(zeros(128,128), 'CDataMapping', 'scaled', 'UIContextMenu', roi_context);
	item1 = uimenu(roi_context, 'Label', 'make new roi', 'Callback', 'spc_makeRoi');
    item2 = uimenu(roi_context, 'Label', 'select all', 'Callback', 'spc_selectAll');    
	item3 = uimenu(roi_context, 'Label', 'binning 2x2', 'Callback', 'spc_binning');
    item4 = uimenu(roi_context, 'Label', 'smoothing 2x2', 'Callback', 'spc_smooth(2)');
    item5 = uimenu(roi_context, 'Label', 'smoothing 3x3', 'Callback', 'spc_smooth(3)');
    item6 = uimenu(roi_context, 'Label', 'smoothing 4x4', 'Callback', 'spc_smooth(4)');    
    item7 = uimenu(roi_context, 'Label', 'undo', 'Callback', 'spc_undo');
    item8 = uimenu(roi_context, 'Label', 'restrict in roi', 'Callback', 'spc_selectRoi');
	item9 = uimenu(roi_context, 'Label', 'log-scale', 'Callback', 'spc_logscale');

    %set axes properties.
    gui.spc.figure.projectAxes = gca;
    set(gui.spc.figure.projectAxes, 'XTick', [], 'YTick', []);
    %set(gui.spc.figure.projectAxes, 'CLim', [1,spc.switches.threshold]);
    %draw default roi in Fig1.
    roi_pos = [1,1,1,1];
    gui.spc.figure.roi = rectangle('position', roi_pos, 'ButtonDownFcn', 'spc_dragRoi', 'EdgeColor', [1,1,1]);
    gui.spc.figure.ptojectColorbar = colorbar;

%Fig2.
    gui.spc.figure.lifetime = figure;
    set(gui.spc.figure.lifetime, 'Position', fig2_pos, 'name', 'Lifetime');
    gui.spc.figure.lifetimeAxes = axes;
    set(gui.spc.figure.lifetimeAxes, 'Position', [0.15, 0.37, 0.8, 0.57], 'XTick', []);
    gui.spc.figure.lifetimePlot = plot(1:64, zeros(64,1));
    hold on;
    gui.spc.figure.fitPlot = plot(1:64, zeros(64, 1));
    xlabel('');
    ylabel('Photon');
    gui.spc.figure.residual = axes;
    set(gui.spc.figure.residual, 'position', [0.15, 0.15, 0.8, 0.18]);
    gui.spc.figure.residualPlot = plot(1:64, zeros(64, 1));
    xlabel('Lifetime (ns)');
    ylabel('Residuals');
    set(gui.spc.figure.residual, 'XLimMode', 'auto');
    set(gui.spc.figure.residual, 'YLimMode', 'auto');

%Fig3.
    gui.spc.figure.lifetimeMap = figure;
    set(gui.spc.figure.lifetimeMap, 'MenuBar', 'none');
    set(gui.spc.figure.lifetimeMap, 'Position', fig3_pos, 'name', 'LifetimeMap');
    gui.spc.figure.lifetimeMapAxes = axes('Position', [0.1300    0.1100    0.6626    0.8150]);
    lifetimeMap_context = uicontextmenu;
    gui.spc.figure.lifetimeMapImage = image(zeros(128,128,3), 'CDataMapping', 'scaled', 'UIContextMenu', lifetimeMap_context);
    %item1 = uimenu(lifetimeMap_context, 'Label', 'Range...', 'Callback', 'spc_rangeDlog');
    item2 = uimenu(lifetimeMap_context, 'Label', 'Restrict in roi', 'Callback', 'spc_selectRoi');
    set(gui.spc.figure.lifetimeMapAxes, 'XTick', [], 'YTick', []);
    gui.spc.figure.mapRoi=rectangle('position', roi_pos, 'EdgeColor', [1,1,1], 'ButtonDownFcn', 'spc_dragRoi');
    gui.spc.figure.lifetimeMapColorbar = axes('Position', [0.82, 0.11, 0.05, 0.8150]);
    scale = 56:-1:9;
    image(scale(:));
    colormap(jet);
    set(gui.spc.figure.lifetimeMapColorbar, 'XTickLabel', []);
    set(gui.spc.figure.lifetimeMapColorbar, 'YAxisLocation', 'right', 'YTickLabel', []);
    gui.spc.figure.lifetimeUpperlimit = uicontrol('Style', 'edit', 'String', '1', ...
                'Unit', 'normalized', 'Position', [0.88, 0.9, 0.1, 0.05], 'Callback', 'spc_redrawSetting');
    gui.spc.figure.lifetimeLowerlimit = uicontrol('Style', 'edit', 'String', '0', ...
                'Unit', 'normalized', 'Position', [0.88, 0.1, 0.1, 0.05], 'Callback', 'spc_redrawSetting');
    gui.spc.figure.LUTtext = uicontrol('Style', 'text', 'String', 'LUT', ...
                'Unit', 'normalized', 'Position', [0.88, 0.6, 0.1, 0.05], 'BackgroundColor', [0.8,0.8,0.8]);
    gui.spc.figure.LutUpperlimit = uicontrol('Style', 'edit', 'String', '0', ...
                'Unit', 'normalized', 'Position', [0.88, 0.5, 0.1, 0.05], 'Callback', 'spc_redrawSetting');
    gui.spc.figure.LutLowerlimit = uicontrol('Style', 'edit', 'String', '0', ...
                'Unit', 'normalized', 'Position', [0.88, 0.55, 0.1, 0.05], 'Callback', 'spc_redrawSetting');
    gui.spc.figure.drawPopulation = uicontrol ('Style', 'checkbox', 'Unit', 'normalized', ...
                'Position', [0.05, 0.02, 0.3, 0.05], 'String', 'Draw population', 'Callback', ...
                'spc_redrawSetting', 'BackgroundColor', [0.8,0.8,0.8]);
spc_main;
 


%backupfiles.
try
load('spc_backup.mat');
if exist(spc_filename) == 2
    spc_openCurves(spc_filename);
end
end

try
    spc_updateMainStrings;
catch ME
%    for i=1:length(ME.stack)
%        error(ME.stack(i).file);
%        error(ME.stack(i).name);
%        error(ME.stack(i).line);
%    end
    disp('Error: Strings in spc_main is not updated (function spc_drawInit)');
end

if isfield(gui.spc, 'FLIMimage')
	try
        pos1 = gui.spc.figure.positions.FLIMimage;
	catch
        pos1 = [100, 30, 45.6, 18];
	end
	set(gui.spc.FLIMimage.figure1, 'Position', pos1);
end;

try
    pos1 = gui.spc.figure.positions.spc_main;    
catch
    pos1 = [143.4000   45.5385   83.6000   26.1538];
end
set(gui.spc.spc_main.spc_main, 'Position', pos1);

if isfield(spc, 'imageMod')
    try
	    spc_redrawSetting;
    catch
        disp('Error: no images produced (function spc_drawInit)');
    end
end

try
	if length(spc.lifetime) > 3
          spc_prfdefault;
          spc.fit.fixtau1 = 1; 
          spc.fit.fixtau2 = 1;
          spc_dispbeta;
          set(gui.spc.spc_main.beta2, 'String', '2.59');
          set(gui.spc.spc_main.beta4, 'String', '1.4');
          set(gui.spc.spc_main.beta1, 'String', '1000');
          set(gui.spc.spc_main.beta3, 'String', '1000');
          spc_fitWithDoubleExp;
          spc_dispbeta;
	end
end
try
    spc_selectAll;
end