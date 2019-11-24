function spc_drawLifetimeMap (flag, fast)
global spc;
global gui;

if spc.switches.imagemode == 0 
    return;
end;

calcPop = get(gui.spc.figure.drawPopulation, 'Value');

range(1) = str2num(get(gui.spc.figure.lifetimeUpperlimit, 'String'));
range(2) = str2num(get(gui.spc.figure.lifetimeLowerlimit, 'String'));
LUTrange(1) = str2num(get(gui.spc.figure.LutUpperlimit, 'String'));
LUTrange(2) = str2num(get(gui.spc.figure.LutLowerlimit, 'String'));
if (LUTrange(1) >= 0 && LUTrange(2) >= 0) && LUTrange(2) > LUTrange(1)
    spc.switches.lutlim = LUTrange;
else
    set(gui.spc.figure.LutUpperlimit, 'String', num2str(spc.switches.lutlim(1)));
    set(gui.spc.figure.LutLowerlimit, 'String', num2str(spc.switches.lutlim(2)));
end
    
if calcPop
    if range(1) <= 1 && range(2) <= 1
        popLimit = range;
    else
        popLimit = [1,0];
    end
    if get(gui.spc.spc_main.fixtau1, 'Value') && get(gui.spc.spc_main.fixtau2, 'Value')
        spc.rgbLifetime = spc_drawPopulation (popLimit);
    else
        errordlg ('Fix tau1 and tau2, and then press Auto!');
        set(gui.spc.spc_main.pop_check, 'Value', 0);
        return;
    end
else
    if range(1) > 1 || range(2) > 1
        spc.switches.lifetime_limit = range;
    end    
    if flag == 1 || nargin == 0
        spc_calcLifetimeMap;
    end
    spc_makeRGBLifetimeMap;
end
    
if ~fast

    spc_roi = get(gui.spc.figure.roi, 'Position');
    axes(gui.spc.figure.lifetimeMapAxes);
	lifetimeMap_context = uicontextmenu;
	gui.spc.figure.lifetimeMapImage = image(spc.rgbLifetime, 'UIContextMenu', lifetimeMap_context);
	set(gui.spc.figure.lifetimeMapAxes, 'XTick', [], 'YTick', []);
	%item1 = uimenu(lifetimeMap_context, 'Label', 'Range...', 'Callback', 'spc_rangeDlog');
	item2 = uimenu(lifetimeMap_context, 'Label', 'Restrict in roi', 'Callback', 'spc_selectRoi');
	
	%Roi!
	gui.spc.figure.mapRoi = rectangle('position', spc_roi, 'ButtonDownFcn', 'spc_dragRoi', 'EdgeColor', [1,1,1]);
else
    set(gui.spc.figure.lifetimeMapImage, 'CData', spc.rgbLifetime);
end


%redraw colormap.
axes(gui.spc.figure.lifetimeMapColorbar);
scale = 56:-1:9;
image(scale(:));
colormap(jet);
set(gui.spc.figure.lifetimeMapColorbar, 'XTickLabel', []);
set(gui.spc.figure.lifetimeMapColorbar, 'YTickLabel', []);
if calcPop
    range = popLimit;
else
    range = spc.switches.lifetime_limit;
end
%set(gui.spc.figure.lifetimeMapColorbar, 'YAxisLocation', 'right', 'YTick', [1,48], 'YTickLabel', [range(1), range(2)]);
 set(gui.spc.figure.lifetimeUpperlimit, 'String', num2str(range(1)));
 set(gui.spc.figure.lifetimeLowerlimit, 'String', num2str(range(2)));


