function beta0 = spc_initialValue_double
global spc;
global gui;

handles = gui.spc.spc_main;
try
	beta0(1)=str2double(get(handles.beta1, 'String'));
	beta0(2)=str2double(get(handles.beta2, 'String'));
	beta0(3)=str2double(get(handles.beta3, 'String'));
	beta0(4)=str2double(get(handles.beta4, 'String'));
	beta0(5)=str2double(get(handles.beta5, 'String'));
    beta0(6)=str2double(get(handles.beta6, 'String'));
	beta0(2) = beta0(2)*1000/spc.datainfo.psPerUnit;
	beta0(4) = beta0(4)*1000/spc.datainfo.psPerUnit;
	beta0(5) = beta0(5)*1000/spc.datainfo.psPerUnit;
    beta0(6) = beta0(6)*1000/spc.datainfo.psPerUnit;
catch
end

range = spc.fit.range;

if beta0(1) == 0 || beta0(2) <= 0.1*1000/spc.datainfo.psPerUnit || beta0(2) >=10*1000/spc.datainfo.psPerUnit ...
        || beta0(6) <= 0*1000/spc.datainfo.psPerUnit || beta0(6) >= 1*1000/spc.datainfo.psPerUnit ...
        ||beta0(3) == 0 ...
        || beta0(4) <= 0.1*1000/spc.datainfo.psPerUnit || beta0(4) >=10*1000/spc.datainfo.psPerUnit
    b1 = max(spc.lifetime(range(1):1:range(2)));
    b2 = sum(spc.lifetime(range(1):1:range(2)))/b1;
    beta0(1) = b1*0.5;
    beta0(3) = b1*0.5;
    beta0(2) = b2*1.2;
    beta0(4) = b2*0.3;
    beta0(6) = 0.10533*1000/spc.datainfo.psPerUnit;
%     set(handles.fixtau1, 'Value', 0);
%     set(handles.fixtau2, 'Value', 0);
end

if beta0(5) <= -1*1000/spc.datainfo.psPerUnit || beta0(5) >= 5*1000/spc.datainfo.psPerUnit 
    beta0(5) = 1000/spc.datainfo.psPerUnit;
end


