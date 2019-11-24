function spc_putIntoSPCS;

global state;
if isfield(state, 'spc') | isfield(state, 'acq')
else
    global spcs;
	eval('spcs.nImages = spcs.nImages + 1;', 'spcs.nImages = 1;');
	eval(['spcs.spc', num2str(spcs.nImages), '.size=spc.size;'], ''); 
	eval(['spcs.spc', num2str(spcs.nImages), '.datainfo=spc.datainfo;'], ''); 
	eval(['spcs.spc', num2str(spcs.nImages), '.switches=spc.switches;'], '');
	eval(['spcs.spc', num2str(spcs.nImages), '.filename=spc.filename;'], '');
	eval(['spcs.spc', num2str(spcs.nImages), '.project=spc.project;'], ''); 
	eval(['spcs.spc', num2str(spcs.nImages), '.lifetime=spc.lifetime;'], '');
	eval(['spcs.spc', num2str(spcs.nImages), '.lifetimeMap=spc.lifetimeMap;'], ''); 
	eval(['spcs.spc', num2str(spcs.nImages), '.rgbLifetime=spc.rgbLifetime;'], ''); 
	evalc(['spcs.spc', num2str(spcs.nImages), '.imageMod = sparse(reshape(full(spc.image), spc.size(1), spc.size(2)*spc.size(3)))']);
	spcs.current = spcs.nImages;
end

spc_updateMainStrings;
