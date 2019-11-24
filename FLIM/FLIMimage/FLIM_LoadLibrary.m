function FLIM_LoadLibrary
global state

addpath('C:\Program Files (x86)\BH\SPCM\DLL');
%
if (~libisloaded(state.spc.init.dllname))
    loadlibrary(state.spc.init.dllname,'Spcm_def.h', 'includepath', 'C:\Program Files (x86)\BH\SPCM\DLL');
end
