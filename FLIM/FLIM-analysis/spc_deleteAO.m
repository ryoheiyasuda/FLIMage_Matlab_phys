function spc_deleteAO
global state;
spc_stopGrab;
spc_stopFocus;
delete(state.spc.init.spc_ao);
delete(state.spc.init.spc_aoF);
delete(state.spc.init.spc_line);