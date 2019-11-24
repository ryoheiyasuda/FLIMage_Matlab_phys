function spc_makeRoiA(i);
global spc
global gui

figure(gui.spc.figure.project);
waitforbuttonpress;
figure(gcf);
point1 = get(gca,'CurrentPoint');    % button down detected
finalRect = rbbox;                   % return figure units
point2 = get(gca,'CurrentPoint');    % button up detected
point1 = point1(1,1:2);              % extract x and y
point2 = point2(1,1:2);
p1 = min(point1,point2);             % calculate locations
offset = abs(point1-point2);         % and dimensions
%rectangle('Position', [p1, offset]);
spc_roi = round([p1, offset]);

%set(gui.spc.figure.roiA(i), 'Position', spc_roi);
rectstr = ['RoiA', num2str(i)];
textstr = ['TextA', num2str(i)];
Rois = findobj('Tag', rectstr);
Texts = findobj('Tag', textstr);

for j = 1:length(Rois)
    delete(Rois(j));
end
for j = 1:length(Rois)
    delete(Texts(j));
end

figure(gui.spc.figure.project);
gui.spc.figure.roiA(i) = rectangle('Position', spc_roi, 'Tag', rectstr, 'EdgeColor', 'cyan', 'ButtonDownFcn', 'spc_dragRoiA');
gui.spc.figure.textA(i) = text(p1(1), p1(2), num2str(i), 'color', 'red', 'Tag', textstr, 'ButtonDownFcn', 'spc_deleteRoiA');
%spc_drawLifetime;

figure(gui.spc.figure.lifetimeMap);

gui.spc.figure.roiB(i) = rectangle('Position', spc_roi, 'Tag', rectstr, 'EdgeColor', 'cyan', 'ButtonDownFcn', 'spc_dragRoiA');
gui.spc.figure.textB(i) = text(p1(1), p1(2), num2str(i), 'color', 'red', 'Tag', textstr, 'ButtonDownFcn', 'spc_deleteRoiA');

spc.fit.spc_roi{j} = get(gui.spc.figure.roiA(i), 'Position');