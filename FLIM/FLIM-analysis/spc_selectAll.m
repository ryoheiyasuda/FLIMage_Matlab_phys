function spc_selectAll
global spc
global gui
spc.size = size(spc.imageMod);
spc_roi = [1, 1, spc.SPCdata.scan_size_x*spc.SPCdata.line_compression, spc.SPCdata.scan_size_y*spc.SPCdata.line_compression];
set(gui.spc.figure.roi, 'Position', spc_roi);
set(gui.spc.figure.mapRoi, 'Position', spc_roi);
spc.roipoly = ones(spc.SPCdata.scan_size_x*spc.SPCdata.line_compression, spc.SPCdata.scan_size_y*spc.SPCdata.line_compression);
%spc_drawLifetime;
spc_redrawSetting(1,1);