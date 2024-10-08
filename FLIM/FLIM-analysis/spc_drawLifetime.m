function spc_drawLifetime (fast)
global spc;
global gui;

if ~nargin
    fast = 1;
end
range = spc.fit.range;

if (spc.switches.imagemode == 1)
    spc_roi=round(get(gui.spc.figure.roi, 'Position'));
%     if spc_roi(3) > spc.size(3) | spc_roi(4) > spc.size(2)
%         spc_selectAll;
%     end
%     if isfield(spc, 'roipoly')
%         if size(spc.roipoly) ~= spc.size(2:3)
%             spc_selectAll;
%         end
%     end

   try
        if spc.SPCdata.line_compression >= 2
            ss = spc.SPCdata.line_compression;
            index = (spc.project >= spc.switches.lutlim(1));
            [yi, xi] = meshgrid(ss:ss:spc.SPCdata.scan_size_x*ss, ss:ss:spc.SPCdata.scan_size_y*ss);
            index = interp2(index, yi, xi, 'nearest');          
        else
            index = (spc.project >= spc.switches.lutlim(1));
        end
        siz = size(index);
        %bw = (spc.lifetimeMap > 1);
        %index =index.*bw;        siz = size(index);	
		index = repmat (index(:), [1,spc.size(1)]);
		index = reshape(index, siz(1), siz(2), spc.size(1));
		index = permute(index, [3,1,2]);

        imageMod = index .*  spc.imageMod; % reshape((spc.imageMod), spc.size(1), spc.SPCdata.scan_size_y, spc.SPCdata.scan_size_x);
        %spc.imageMod = image;
    catch
        %image = reshape(full(spc.imageMod), spc.size(1), spc.size(2), spc.size(3));
        imageMod = spc.imageMod;
        disp('spc_drawlifetime: LUT error');
    end
    
    if isfield(spc, 'roipoly')
        index = spc.roipoly;
        if spc.SPCdata.line_compression > 1 %Skip anyway)
            aa = spc.SPCdata.line_compression;
            [xi, yi] = meshgrid(aa:aa:spc.SPCdata.scan_size_x*aa, aa:aa:spc.SPCdata.scan_size_y*aa);
            index = interp2(index, xi, yi, 'nearest');          
        else
            siz = size(index);
            index = repmat (index(:), [1,spc.size(1)]);
            index = reshape(index, siz(1), siz(2), spc.size(1));
            index = permute(index, [3,1,2]);
            try
                imageMod = reshape((index(:) .*  imageMod(:)), spc.size(1), spc.SPCdata.scan_size_y, spc.SPCdata.scan_size_x);
            catch
                imageMod = spc.imageMod;
            end
        end
    else
        imageMod = imageMod;
    end
    if spc.SPCdata.line_compression > 1
        spc_roi1 = round((spc_roi+spc.SPCdata.line_compression) / spc.SPCdata.line_compression);
    else
        spc_roi1 = spc_roi;
    end
    try
        cropped = imageMod(:, spc_roi1(2):spc_roi1(2)+spc_roi1(4)-1, spc_roi1(1):spc_roi1(1)+spc_roi1(3)-1);
    catch
        %disp('Cropping problem?');
        %spc_roi = [1, 1, spc.size(2), spc.size(3)];
        spc.size = size(spc.imageMod);

        if spc.SPCdata.line_compression > 1
            spc_roi = [spc.SPCdata.line_compression, spc.SPCdata.line_compression, spc.SPCdata.scan_size_x*spc.SPCdata.line_compression, ...
                spc.SPCdata.scan_size_y*spc.SPCdata.line_compression]-spc.SPCdata.line_compression;
            spc_roi1 = round(spc_roi / spc.SPCdata.line_compression)-1;
        else
            spc_roi = [1,1,spc.SPCdata.scan_size_x, spc.SPCdata.scan_size_y];
            spc_roi1 = spc_roi;
        end
        spc_roi1(spc_roi1<1) = 1;
		set(gui.spc.figure.roi, 'Position', spc_roi);
        set(gui.spc.figure.mapRoi, 'position', spc_roi, 'EdgeColor', [1,1,1]);
        cropped = imageMod(:, spc_roi1(2):spc_roi1(2)+spc_roi1(4)-1, spc_roi1(1):spc_roi1(1)+spc_roi1(3)-1);
    end
    spc.lifetime = reshape(sum(sum(cropped, 2),3), 1, spc.size(1));
end;

lifetime = spc.lifetime(range(1):1:range(2));
lifetime = lifetime(:);
t = [range(1):1:range(2)];
t = t*spc.datainfo.psPerUnit/1000;

if ~ishandle(gui.spc.figure.lifetimePlot)
    try
        close(gui.spc.figure.lifetime);
    end
    figure(gui.spc.figure.lifetime);
    set(gui.spc.figure.lifetime, 'name', 'Lifetime');
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

end

set(gui.spc.figure.lifetimePlot, 'XData', t, 'YData', lifetime);
set(gui.spc.figure.fitPlot, 'XData', t, 'YData', lifetime);
set(gui.spc.figure.fitPlot, 'Color', 'Black');
set(gui.spc.figure.residualPlot, 'Xdata', t, 'Ydata', zeros(length(lifetime), 1));
set(gui.spc.figure.lifetimeAxes, 'XTick', []);
if (spc.switches.logscale == 0)
    set(gui.spc.figure.lifetimeAxes, 'YScale', 'linear');
else
    set(gui.spc.figure.lifetimeAxes, 'YScale', 'log');
end

set(gui.spc.figure.lifetimeAxes, 'XLimMode', 'auto');
set(gui.spc.figure.lifetimeAxes, 'YLimMode', 'auto');
set(gui.spc.figure.residual, 'XLimMode', 'auto');
set(gui.spc.figure.residual, 'YLimMode', 'auto');

if ~fast
    figure(gui.spc.figure.lifetime);
end