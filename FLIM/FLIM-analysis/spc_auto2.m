function spc_auto (flag);

global spc;
global state;
global gui;

pos_max2 = 2.3438; %%%Offset for graph 'mean_tau' in nanoseconds.
spc_updateMainStrings;
name_start=findstr(spc.filename, '\');
name_start=name_start(end)+1;

if strfind(spc.filename, 'max')
    baseName_end=length(spc.filename)-11;
elseif strfind(spc.filename, 'glu')
    baseName_end=length(spc.filename)-11;
else
    baseName_end=length(spc.filename)-7;
end
baseName=spc.filename(name_start:baseName_end);
graph_savePath=spc.filename(1:name_start-5);
spc_savePath=spc.filename(1:name_start-1);

eval(['global  ', baseName]);

%spc_savePath = [state.files.savePath, 'spc\'];
cd (spc_savePath);

if exist([baseName, '.mat'])
    load([baseName, '.mat'], baseName);
else
    %disp('no such file');
    %button = questdlg('Do you want to make new files?');
    %return;
end

graphfile = [graph_savePath, baseName, '_tau_all.fig'];

 if isfield(gui.spc, 'online')
     if ishandle(gui.spc.online)
         if strcmp(get(gui.spc.online, 'Tag'), 'Online_fig')
            saveas(gui.spc.online, graphfile);
            close(gui.spc.online);
        end
    end
 end
        
if exist (graphfile)
    gui.spc.online=open(graphfile);
    set(gui.spc.online, 'Tag', 'Online_fig');
    %gcf
else  
    gui.spc.online = 111;
    set(gui.spc.online, 'Tag', 'Online_fig');
    %beep; return;
end

if nargin == 0
    flag = 0;
end

spc_fitwithdoubleexp;

p1 = spc.fit.beta0(1);
p2 = spc.fit.beta0(3);
tau1 = spc.fit.beta0(2)*spc.datainfo.psPerUnit/1000;
tau2 = spc.fit.beta0(4)*spc.datainfo.psPerUnit/1000;

f = p2/(p1+p2);

spc_dispbeta;
evalc(['a = ', baseName]);
% try
%     a.framecounter = [a.framecounter, state.files.fileCounter];
%     a.fraction = [a.fraction, f];
%     a.time = [a.time, rem(now, 1)*3600*24];
% catch
%     a.fraction = f;
%     a.time = rem(now, 1)*3600*24;
%     a.framecounter = state.files.fileCounter;
% end
    if flag == 0
        fc = state.files.fileCounter;
    else
        %fc = state.files.fileCounter - 1;
%         c1 = strfind(spc.filename, state.files.baseName) + length(state.files.baseName);
%         c = c1(end);
        fc = str2num(spc.filename(baseName_end+1:baseName_end+3));
    end
    if ~isfield(a, 'tau_m2')
        a.tau_m2(length(a.fraction)) = 0;
    end
    if isempty(a.tau_m2)
        a.tau_m2(length(a.fraction)) = 0;
    end
    a.fraction(fc) = f;
    a.tau1(fc) = tau1;
    a.tau2(fc) = tau2;
    %a.time(fc) = rem(now, 1)*3600*24;
    a.tau_m(fc) = sum(spc.lifetime)/max(spc.lifetime)*spc.datainfo.psPerUnit/1000;
    a.tau_m2(fc) = sum(spc.lifetime.*(1:spc.size(1)))/sum(spc.lifetime)*spc.datainfo.psPerUnit/1000 - pos_max2;
    
    
%spc_savePath = [state.files.savePath, 'spc\'];

for i=1:fc%state.files.fileCounter
    count = num2str(i);
    while length(count) < 3
        count = ['0', count];
    end
    filename = [baseName, count, '.tif'];
    filename = [spc_savePath, filename];
    if exist(filename) == 2
        fileinfo = imfinfo(filename);
        fdate = fileinfo(1).FileModDate;
        a.time(i) = datenum(fdate); % - floor(datenum(fdate));
    else
        filename = [baseName, count, '_glu.tif'];
        filename = [spc_savePath, filename];
        if exist(filename) == 2
            fileinfo = imfinfo(filename);
            fdate = fileinfo(1).FileModDate;
            a.time(i) = datenum(fdate); % - floor(datenum(fdate));
            mask_pos=get(state.init.eom.boxHandles(2), 'Position');
        else
            if i==1
                a.time(i) = datenum(now);
            elseif i <= fc
                a.time(i) = a.time(i-1);
            end
        end 
    end
end

a.fraction(a.fraction > 1) = 1;
a.fraction(a.fraction < -0.1) = -0.1;

if flag == 0
    a.time(state.files.fileCounter) = datenum(now);
end
%a.time = a.time - min (a.time);

if isfield(spc.scanHeader.motor, 'position')
    a.position(length(a.fraction)) = spc.scanHeader.motor.position;
else    
    a.position(length(a.fraction)) = state.motor.position;
    spc.scanHeader.motor.position = state.motor.position;
end

%try
%    get(state.spc.autoPlot, 'XData');
%    set(state.spc.autoPlot, 'XData', (a.time-min(a.time))*60*24, 'YData', a.fraction);
%catch

    figure (gui.spc.online);
    subplot(2,2,1);
    cstr = {'black', 'red', 'blue', 'green', 'magenta', 'cyan', 'black'};
    fl1 = 0;
    for pos = 0:max(a.position(:))
        ptime = (a.time(a.position == pos)- min(a.time))*60*24 ;
        pfrac = a.fraction(a.position == pos);
        if length(ptime) > 0
            pos = mod(pos, 7)+1;
            state.spc.autoPlot(pos+1) = plot(ptime, pfrac, '-o', 'Color', cstr{pos});
            if fl1 == 0; hold on; fl1 = 1; end
        end
    end
    hold off;
   ylabel('Fraction (tau2)'); 
   xlabel ('Time (min)');
    %figure (109);
    subplot(2,2,2);
    fl1 = 0;
    for pos = 0:max(a.position(:))
        ptime = (a.time(a.position == pos)- min(a.time))*60*24 ;
        ptau1 = a.tau1(a.position == pos);
        ptau2 = a.tau2(a.position == pos);
        pfrac = a.fraction(a.position == pos);
        ptau = ptau1.*(1-pfrac) + ptau2.*(pfrac);
        if length(ptime) > 0
            pos = mod(pos, 7)+1;
            state.spc.autoPlot_t(pos+1) = plot(ptime, ptau, '-o', 'Color', cstr{pos});
            if fl1 == 0; hold on; fl1 = 1; end
        end
    end
    hold off;
ylabel('<tau>');
xlabel ('Time (min)');
    %figure (110);
    subplot(2,2,3);
    fl1 = 0;
    for pos = 0:max(a.position(:))
        ptime = (a.time(a.position == pos)- min(a.time))*60*24 ;
        ptau = a.tau_m(a.position == pos);
        %ptau = ptau1.*(1-pfrac) + ptau2.*(pfrac);
        if length(ptime) > 0
            pos = mod(pos, 7)+1;
            state.spc.autoPlot_t(pos+1) = plot(ptime, ptau, '-o', 'Color', cstr{pos});
            if fl1 == 0; hold on; fl1 = 1; end
        end
    end
    hold off;
ylabel('Area / peak');
xlabel ('Time (min)');
%end
ylabel('<tau>');
xlabel ('Time (min)');
    %figure (110);
    subplot(2,2,4);
    fl1 = 0;
    for pos = 0:max(a.position(:))
        ptime = (a.time(a.position == pos)- min(a.time))*60*24 ;
        ptau = a.tau_m2(a.position == pos);
        %ptau = ptau1.*(1-pfrac) + ptau2.*(pfrac);
        if length(ptime) > 0
            pos = mod(pos, 7)+1;
            state.spc.autoPlot_t(pos+1) = plot(ptime, ptau, '-o', 'Color', cstr{pos});
            if fl1 == 0; hold on; fl1 = 1; end
        end
    end
    hold off;
ylabel('mean tau');
xlabel ('Time (min)');

if isfield(state, 'acq')
	if state.acq.linescan
		ydata_line1 = mean(state.acq.acquiredData{1}, 2);
        ydata_line2 = mean(state.acq.acquiredData{2}, 2);
        ydata_line1 = ydata_line1 - mean(ydata_line1(1:20));
        ydata_line2 = ydata_line2 - mean(ydata_line2(1:20));
        ydata_line3 = 100*spc_calcLinescan;
        xdata_line = 1:length(ydata_line1);
		try
            get(state.spc.autoPlot_line, 'XData');
            set(state.spc.autoPlot_line, 'XData', xdata_line, 'YData', ydata_line1, 'color', 'green');
            set(state.spc.autoPlot_line2, 'XData', xdata_line, 'YData', ydata_line2, 'color', 'red');
            set(state.spc.autoPlot_line3, 'XData', xdata_line, 'YData', ydata_line3, 'color', 'black');       
		catch
            figure(109);
            hold off;
            state.spc.autoPlot_line = plot(xdata_line, ydata_line1, 'color', 'green');
            hold on;
            state.spc.autoPlot_line2 = plot(xdata_line, ydata_line2, 'color', 'red');
            state.spc.autoPlot_line3 = plot(xdata_line, ydata_line3, 'color', 'black');
		end
        evalc([baseName, '_lines.a', num2str(state.files.fileCounter - 1), ' = ydata_line1']);
        evalc([baseName, '_lines.b', num2str(state.files.fileCounter - 1), ' = ydata_line2']);
        evalc([baseName, '_lines.c', num2str(state.files.fileCounter - 1), ' = ydata_line3']);      
        save([graph_savePath, baseName, '_lines.mat'], [baseName, '_lines']);
	end
end

if length(a.time) > length(a.fraction)
    a.time = a.time(1:end-1)
end

%ylim([0, 0.5])
eval([baseName, '= a;']);

save([spc_savePath, baseName, '.mat'], baseName);

try
    save_autoSetting;
catch
    disp('Error in saving Autosetting');
end