function spc_redrawSetting (flag, fast)

global spc;
global gui;

if ~nargin
    flag = 1;
    fast = 0;
end
if nargin < 2
    fast = 0;
end
% 
if spc.switches.imagemode == 0
%     figure(gui.spc.figure.lifetime);
%     set(gui.spc.figure.lifetime, 'name', 'Lifetime');
%     eval('axes(gui.spc.figure.lifetimeaxes);', 'gui.spc.figure.lifetimeaxes = axes;');
%     set(gui.spc.figure.lifetimeaxes, 'Position', [0.15, 0.37, 0.8, 0.57], 'xtick', []);
%     ylabel('Photon');
%     eval('axes(gui.spc.figure.residual);', 'gui.spc.figure.residual = axes;');
%     set(gui.spc.figure.residual, 'position', [0.15, 0.15, 0.8, 0.18]);
% 
% %%%%%%%%%%%%%%
else
    try 
        roi_pos = get(gui.spc.figure.roi, 'Position');
    catch
        roi_pos = [1, 1, spc.size(3)-1, spc.size(2)-1];
    end

    if flag
        spc.project = reshape(sum(spc.imageMod, 1), spc.SPCdata.scan_size_y, spc.SPCdata.scan_size_x);
        if spc.SPCdata.line_compression > 1
            aa = 1/spc.SPCdata.line_compression;
            [yi, xi] = meshgrid(aa:aa:spc.SPCdata.scan_size_x, aa:aa:spc.SPCdata.scan_size_y);
            spc.project = interp2(spc.project, yi, xi)*aa*aa;
            spc.size(2) = spc.SPCdata.scan_size_x /aa;
            spc.size(3) = spc.SPCdata.scan_size_y /aa;   
            spc.project(isnan(spc.project)) = 0;
        end
    end
        if ~fast
            axes(gui.spc.figure.projectAxes);
            roi_context = uicontextmenu;
            gui.spc.figure.projectImage = image(spc.project, 'CDataMapping', 'scaled', 'UIContextMenu', roi_context);
            item1 = uimenu(roi_context, 'Label', 'make new roi', 'Callback', 'spc_makeRoi');
            item2 = uimenu(roi_context, 'Label', 'select all', 'Callback', 'spc_selectAll');    
            %item3 = uimenu(roi_context, 'Label', 'binning 2x2', 'Callback', 'spc_binning');
            item4 = uimenu(roi_context, 'Label', 'smoothing 2x2', 'Callback', 'spc_smooth(2)');
            item5 = uimenu(roi_context, 'Label', 'smoothing 3x3', 'Callback', 'spc_smooth(3)');
            item6 = uimenu(roi_context, 'Label', 'smoothing 4x4', 'Callback', 'spc_smooth(4)');    
            item7 = uimenu(roi_context, 'Label', 'undo', 'Callback', 'spc_undo');
            item8 = uimenu(roi_context, 'Label', 'restrict in roi', 'Callback', 'spc_selectRoi');
            item9 = uimenu(roi_context, 'Label', 'log-scale', 'Callback', 'spc_logscale');

            set(gui.spc.figure.projectAxes, 'XTick', [], 'YTick', []);
            %draw default roi in Fig1.
            gui.spc.figure.roi = rectangle ('position', roi_pos, 'ButtonDownFcn', 'spc_dragRoi', 'EdgeColor', [1,1,1]);

            colorbar;
        else
            set(gui.spc.figure.projectImage, 'CData', spc.project);
            set(gca, 'xlim', [0.5, size(spc.project, 1)]);
            set(gca, 'ylim', [0.5, size(spc.project, 2)]);
        end
        
end


 spc_drawAll(flag, fast); %flag = calculation of lifetimeMap


try
    for i = 1:length(spc.fit.spc_roi)
        rectstr = ['RoiA', num2str(i)];
        textstr = ['TextA', num2str(i)];
        Rois = findobj('Tag', rectstr);
        Texts = findobj('Tag', textstr);
        for j = 1:length(Rois)
            delete(Rois(j));
        end
        for j = 1:length(Rois)
            delete(Texts(j));
        end

        try
            figure(gui.spc.figure.project);
            gui.spc.figure.roiA(i) = rectangle('Position', spc.fit.spc_roi{i}, 'Tag', rectstr, 'EdgeColor', 'cyan', 'ButtonDownFcn', 'spc_dragRoiA');
            gui.spc.figure.textA(i) = text(spc.fit.spc_roi{i}(1), spc.fit.spc_roi{i}(2), num2str(i), 'color', 'red', 'Tag', textstr, 'ButtonDownFcn', 'spc_deleteRoiA');
            %spc_drawLifetime;

            figure(gui.spc.figure.lifetimeMap);

            gui.spc.figure.roiB(i) = rectangle('Position', spc.fit.spc_roi{i}, 'Tag', rectstr, 'EdgeColor', 'cyan', 'ButtonDownFcn', 'spc_dragRoiA');
            gui.spc.figure.textB(i) = text(spc.fit.spc_roi{i}(1), spc.fit.spc_roi{i}(2), num2str(i), 'color', 'red', 'Tag', textstr, 'ButtonDownFcn', 'spc_deleteRoiA');
        end
    end
end

%spc_spcsUpdate;