function spc = spc_openCurves(fname, page, fast)
global spc;
global gui;

if nargin < 2
    page = 1;
end
if nargin < 3
    fast = 0;
end

no_limit = 0;
try
    save_limit = spc.switches.lifetime_limit;
    save_limit_lut = spc.switches.lutlim;
catch
    no_limit = 1;
end

no_fit = 0;
try
    save_fit = spc.fit;
catch
    no_fit = 1;
    %disp('error')
end
roiP = get(gui.spc.figure.mapRoi, 'position');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp (['Reading ', fname, ', page: ', num2str(page)]);
if findstr(fname, '.sdt')
    spc_readdata(fname);
elseif findstr(fname, '.mat')
    load (fname);
elseif findstr(fname, '.tif')
    error = spc_loadTiff (fname, page, fast);
    if error
        return;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~no_limit
    spc.switches.lifetime_limit = save_limit;
    spc.switches.lutlim = save_limit_lut;
end
% 
if ~no_fit
    spc.fit = save_fit;
end


set(gui.spc.figure.mapRoi, 'position', roiP);

if roiP(3)<=1 || roiP(4) <= 1
    spc_selectAll;
end

spc_redrawSetting;


%spc_selectAll;
% global spcs;
% eval('spcs.nImages = spcs.nImages + 1;', 'spcs.nImages = 1;');
% eval(['spcs.spc', num2str(spcs.nImages), '.size=spc.size;'], ''); 
% eval(['spcs.spc', num2str(spcs.nImages), '.datainfo=spc.datainfo;'], ''); 
% eval(['spcs.spc', num2str(spcs.nImages), '.switches=spc.switches;'], '');
% eval(['spcs.spc', num2str(spcs.nImages), '.filename=spc.filename;'], '');
% eval(['spcs.spc', num2str(spcs.nImages), '.project=spc.project;'], ''); 
% eval(['spcs.spc', num2str(spcs.nImages), '.lifetime=spc.lifetime;'], '');
% eval(['spcs.spc', num2str(spcs.nImages), '.lifetimeMap=spc.lifetimeMap;'], ''); 
% eval(['spcs.spc', num2str(spcs.nImages), '.rgbLifetime=spc.rgbLifetime;'], ''); 
% evalc(['spcs.spc', num2str(spcs.nImages), '.imageMod = sparse(reshape(full(spc.image), spc.size(1), spc.size(2)*spc.size(3)))']);
% spcs.current = spcs.nImages;



