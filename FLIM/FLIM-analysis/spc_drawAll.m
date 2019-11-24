function spc_drawAll(flag, fast);
global spc;
global gui;

%Fig2 = lifetime in ROI.

%set(gui.spc.figure.projectImage, 'CData', spc.project);



if (spc.switches.imagemode == 1);
%Fig3 = Lifetime map.
    spc_drawLifetimeMap(flag, fast);
end;

spc_drawLifetime (fast);