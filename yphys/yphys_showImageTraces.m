function yphys_showImageTraces(flag);
global state;
global yphys;
global gh;

if ~nargin
    flag = 1;
end

if ~isfield(gh, 'yphys')
    gh.yphys.calcium = figure('name', 'Yphys_Calcium');
end
if ~ishandle (gh.yphys.calcium)
    gh.yphys.calcium = figure('name', 'Yphys_Calcium');
else
    if ~strcmp(get(gh.yphys.calcium, 'name'), 'Yphys_Calcium')
        gh.yphys.calcium = figure('name', 'Yphys_Calcium');
    end
end

try
    if isfield(yphys.image, 'average')
        yphys.image.average.ratio = yphys.image.average.ratio* 0;
        if ~isfield(yphys.image, 'aveImage')
            yphys.image.aveImage = [];
        end
        for i=yphys.image.aveImage
            yphys.image.average.ratio = yphys.image.intensity{i}.ratio + yphys.image.average.ratio;
        end
        if length(yphys.image.aveImage) >= 1
            yphys.image.average.ratio =  yphys.image.average.ratio/length(yphys.image.aveImage);

        else
            yphys.image.average.ratio = 0;
        end
    else
        yphys.image.average.ratio = 0;
    end
catch
    yphys.image.average.ratio = 0;
end

nRoi = 0;
if isfield(yphys.image, 'intensity')
    if length(yphys.image.intensity) > 0 & yphys.image.currentImage <= length(yphys.image.intensity)
            a1=yphys.image.intensity{yphys.image.currentImage};
            if ~isempty(a1)
                tSize = size(a1.redMean);
                nRoi = tSize(2);
            end
    end
end


figure(gh.yphys.calcium); 
color_a = {'green', 'red', 'black', 'cyan', 'magenda'};
hold off;
for j = 1 :nRoi
    subplot(2,3,1);
    if j==1
        hold off
    end
    plot(a1.greenMean(:, j), '-', 'color', color_a{j});
    title('Green channel');
    hold on;
    subplot(2,3,2);
    
    if j == 1
        hold off
    end
    plot(a1.redMean(:, j), '-', 'color', color_a{j});
    title('Red channel');
    hold on;
        subplot(2,3,4);
        title('Ratio');
    if j == 1
        hold off
    end
    plot(a1.ratio(:, j), '-', 'color', color_a{j});
    hold on;
        subplot(2,3,5);
    if j == 1
        hold off
    end
    if length(yphys.image.average.ratio)>2
        plot(yphys.image.average.ratio(:, j), '-', 'color', color_a{j});
    end
    title('Averaged ratio');
    hold on;
end;


roiobj = findobj('Tag', 'ROI');
nRoi = length(roiobj);
spc_roi = [];
if ~isfield(gh.yphys, 'figure')
    gh.yphys.figure.roiCalcium = [];
else
    if ~isfield(gh.yphys.figure, 'roiCalcium')
        gh.yphys.figure.roiCalcium = [];
    end
end
for j = 1:length(gh.yphys.figure.roiCalcium)
    if ishandle(gh.yphys.figure.roiCalcium(j))
        spc_roi{j} = get(gh.yphys.figure.roiCalcium(j), 'Position');
    end
end
delete(roiobj);


pwdstr = yphys.image.pathstr(1:end-4);
numstr = '000';
numstr1 = num2str(yphys.image.currentImage);
numstr(end-length(numstr1)+1:end) = numstr1;

if flag
    filename1 = [pwdstr, '\', yphys.image.baseName, numstr, '.tif'];
    if exist(filename1) == 2
        [data, header] = genericOpenTif(filename1);
        yphys.image.imageData = data;
        yphys.image.imageHeader =header;
        yphys.image.pathstr = [pwdstr, '\spc'];
        %filename1
    else
        yphys.image.currentImage = str2num(get(gh.yphys.figure.currentImageText, 'String'));
        return;
    end
end

data = yphys.image.imageData;
header = yphys.image.imageHeader;


siz = size(data);
if isfield(yphys.image, 'currentSlice')
    if yphys.image.currentSlice > siz(3)/2;
        yphys.image.currentSlice = siz(3)/2;
    elseif yphys.image.currentSlice < 1
        yphys.image.currentSlice = 1;
    end
else
    yphys.image.currentSlice = siz(3)/2;
end
slice = yphys.image.currentSlice;
figure(gh.yphys.calcium); 
subplot(2,3,3);
roi_context = uicontextmenu;
image(data(:,:,2*(slice-1)+1), 'CDataMapping','scaled', 'UIContextMenu', roi_context);
set(gca,'XTickLabel', '');
set(gca, 'YTickLabel', '');
colormap(gray);

if yphys.image.imageHeader.acq.linescan
    for j=1:length(yphys.linescan.prange)
        lineRoi = [yphys.linescan.prange{j}(1), 10, yphys.linescan.prange{j}(2)-yphys.linescan.prange{j}(1), 50];
        gh.yphys.figure.roiCalcium(j) = rectangle('Position', lineRoi, 'EdgeColor', color_a{j}, 'Tag', 'ROI');
    end
else
    for j=1:length(spc_roi)
        gh.yphys.figure.roiCalcium(j) = rectangle('Position', spc_roi{j}, 'EdgeColor', color_a{j}, 'ButtonDownFcn', 'r_dragRoi', 'Tag', 'ROI', 'Curvature', [1 1]);
    end
end

subplot(2,3,6);
siz = size(data);
redAve = reshape(mean(data(:,:,2:2:end), 3), siz(1), siz(2));
imagesc(redAve, 'UIContextMenu', roi_context);
set(gca,'XTickLabel', '');
set(gca, 'YTickLabel', '');
item1 = uimenu(roi_context, 'Label', 'make new roi', 'Callback', 'r_makeRoi');
item2 = uimenu(roi_context, 'Label', 'Analyze current image', 'Callback', 'yphys_calcium_offLine');
item3 = uimenu(roi_context, 'Label', 'DeleteRois', 'Callback', 'delete(findobj(''Tag'', ''ROI''))');

if yphys.image.imageHeader.acq.linescan
    for j=1:length(yphys.linescan.prange)
        lineRoi = [yphys.linescan.prange{j}(1), 10, yphys.linescan.prange{j}(2)-yphys.linescan.prange{j}(1), 50];
        gh.yphys.figure.roiCalcium(j) = rectangle('Position', lineRoi, 'EdgeColor', color_a{j}, 'Tag', 'ROI');
    end
else
    for j=1:length(spc_roi)
        gh.yphys.figure.roiCalcium(j) = rectangle('Position', spc_roi{j}, 'EdgeColor', color_a{j}, 'ButtonDownFcn', 'r_dragRoi', 'Tag', 'ROI', 'Curvature', [1 1]);
    end
end

obj1 = findobj('Tag', 'Fig402Button');
if isempty(obj1)
	gh.yphys.figure.preButtonb1 = uicontrol('Style','pushbutton','Units','normalized', 'Position',[.0 .07 .05 .05], 'String','<', 'Tag', 'Fig402Button', 'CallBack', 'yphys_moveToImage(1)');
	gh.yphys.figure.postButtonb2 = uicontrol('Style','pushbutton','Units','normalized', 'Position',[.05 .07 .05 .05], 'String', '>', 'Tag', 'Fig402Button', 'CallBack', 'yphys_moveToImage(2)');
    gh.yphys.figure.preButtonb3 = uicontrol('Style','pushbutton','Units','normalized', 'Position',[0.85 0.95 .035 .035], 'String','<', 'Tag', 'Fig402Button', 'CallBack', 'yphys_moveToImage(5)');
	gh.yphys.figure.postButtonb4 = uicontrol('Style','pushbutton','Units','normalized', 'Position',[0.95 0.95 .035 .035], 'String', '>', 'Tag', 'Fig402Button', 'CallBack', 'yphys_moveToImage(6)');
end
obj2 = findobj('Tag', 'Fig402Text');
if isempty(obj2)
    uicontrol('Style','text','Units','normalized', 'Position',[.775 .95 .05 0.035], 'String','Slice', 'Tag', 'Fig402Text');
end

try
    delete(gh.yphys.figure.currentImageText);
    delete(gh.yphys.figure.averageInFigure, gh.yphys.figure.epochPulse);
    delete(gh.yphys.figure.slice);
end
if ~isfield (state.yphys, 'aveImage')
    state.yphys.aveImage = [];
end

gh.yphys.figure.currentImageText = uicontrol('style', 'edit', 'Units','normalized', 'Position',[.0175 .005 .075 .05], 'String', num2str(yphys.image.currentImage), ...
    'CallBack', 'yphys_moveToImage(3)');
gh.yphys.figure.averageInFigure = uicontrol('style', 'edit', 'Units','normalized', 'Position',[.225 .005 .45 0.05], 'String', num2str(yphys.image.aveImage), ...
    'CallBack', 'yphys_moveToImage(4)');
try
    gh.yphys.figure.epochPulse = uicontrol('style', 'text', 'Units','normalized', 'Position',[.1 .005 .1 0.05], 'String', ['e', num2str(state.yphys.acq.epochN), 'p', num2str(state.yphys.acq.pulseN), '_int']);
catch
    gh.yphys.figure.epochPulse = uicontrol('style', 'text', 'Units','normalized', 'Position',[.1 .005 .1 0.05], 'String', 'Intensity');
end
gh.yphys.figure.slice = uicontrol('style', 'text', 'Units','normalized', 'Position',[.8925 .95 .05 0.035], 'String', num2str(yphys.image.currentSlice));

if yphys.image.imageHeader.acq.linescan
    if ~isfield (gh.yphys, 'profile')
        gh.yphys.profile = figure;
    elseif ~ishandle(gh.yphys.profile)
        gh.yphys.profile = figure;
    end
    figure (gh.yphys.profile);
    plot(yphys.linescan.profile);
    hold on;
    for j=1:length(yphys.linescan.prange)
        plot(yphys.linescan.prange{j}, yphys.linescan.profile(yphys.linescan.prange{j}), 'color', 'red');
    end
    hold off
end