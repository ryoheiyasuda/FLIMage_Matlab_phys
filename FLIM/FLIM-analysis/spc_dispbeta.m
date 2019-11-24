function spc_dispbeta
global gui;
global spc;

if isfield(spc.fit, 'beta0')
    
	handles = gui.spc.spc_main;
	betahat = spc.fit.beta0;
	
	tau = betahat(2)*spc.datainfo.psPerUnit/1000;
	tau2 = betahat(4)*spc.datainfo.psPerUnit/1000;
	peaktime = (betahat(5)+range(1))*spc.datainfo.psPerUnit/1000;
    if length(betahat) >= 6
        tau_g = betahat(6)*spc.datainfo.psPerUnit/1000;
    end
    
    fix1 = get(gui.spc.spc_main.fixtau1, 'value');
    fix2 = get(gui.spc.spc_main.fixtau2, 'value');
    fix_g = get(gui.spc.spc_main.fix_g, 'value');
    fix_d = get(gui.spc.spc_main.fix_delta, 'value');

    set(handles.beta1, 'String', num2str(betahat(1)));
    if ~fix1
    	set(handles.beta2, 'String', num2str(tau));
    else
        tau = str2double(get(handles.beta2, 'String'));
        spc.fit.beta0(2) = tau*1000/spc.datainfo.psPerUnit;
    end
    
	set(handles.beta3, 'String', num2str(betahat(3)));
    
    if ~fix2
    	set(handles.beta4, 'String', num2str(tau2));
    else
        tau2 = str2double(get(handles.beta4, 'String'));
        spc.fit.beta0(4) = tau2*1000/spc.datainfo.psPerUnit;
    end
    if ~fix_d
    	set(handles.beta5, 'String', num2str(peaktime));
    else
        spc.fit.beta0(5) = str2double(get(handles.beta5, 'String'))*1000/spc.datainfo.psPerUnit;
    end
    if ~fix_g
        set(handles.beta6, 'String', num2str(tau_g));
    else
        spc.fit.beta0(6) = str2double(get(handles.beta6, 'String'))*1000/spc.datainfo.psPerUnit;
    end
	
	pop1 = betahat(1)/(betahat(3)+betahat(1));
	pop2 = betahat(3)/(betahat(3)+betahat(1));
	set(handles.pop1, 'String', num2str(pop1));
	set(handles.pop2, 'String', num2str(pop2));
    mean_tau = (tau*tau*pop1+tau2*tau2*pop2)/(tau*pop1 + tau2*pop2);
	set(handles.average, 'String', num2str(mean_tau));
    
%     if isfield(spc.fit, 'fixtau1')
% 		set(handles.fixtau1, 'Value', spc.fit.fixtau1);
% 		set(handles.fixtau2, 'Value', spc.fit.fixtau2);
%     end
%     if isfield(spc.fit, 'fix_g')
%         set(handles.fix_g, 'Value', spc.fit.fix_g);
%     end
end

if isfield(spc.fit, 'range')
        range1 = round(spc.fit.range.*spc.datainfo.psPerUnit/100)/10;
        set(handles.spc_fitstart, 'String', num2str(range1(1)));
        set(handles.spc_fitend, 'String', num2str(range1(2)));
end
