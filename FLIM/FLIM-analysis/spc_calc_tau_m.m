function [tau_m, intensity] = spc_calc_tau_m

global gui spc

pos_max2 = str2num(get(gui.spc.spc_main.F_offset, 'String'));
if pos_max2 == 0 || isnan (pos_max2)
    pos_max2 = 1.0;
end

range = spc.fit.range;
t1 = (1:range(2)-range(1)+1); t1 = t1(:);
lifetime = spc.lifetime(range(1):range(2)); lifetime = lifetime(:);
if sum(lifetime(:)) <= 0
    return;
end
tau_m = sum(lifetime.*t1)/sum(lifetime)*spc.datainfo.psPerUnit/1000 - pos_max2;
intensity = sum(lifetime);