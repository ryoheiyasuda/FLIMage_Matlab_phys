function r_makemovie2(basename, numbers, montage, cLimit, cLimit2, movie);
%%%%%%%%%%%%%%
% Making montage for usual images
%%%%%%%%%%%%

if nargin == 3
    movie = 0;
end
%handles = gui.spc.lifetimerange;

if movie
    mov_name = ['anim-', basename, '.avi'];
    mov = avifile(mov_name, 'fps', 2);
end

try
j = 1;


if  findobj('Tag', 'RatioFig')
    fig_c = figure(findobj('Tag', 'RatioFig'));
else
   fig_c = figure;
   set(fig_c, 'Tag', 'RatioFig');
   set(gcf, 'PaperPositionMode', 'auto');
   set(gcf, 'PaperOrientation', 'landscape');
end

	for i=numbers
        str1 = '000';
        str2 = num2str(i);
        str1(end-length(str2)+1:end) = str2;
        filename1 = [basename, str1, 'max.tif'];
        filename2 = [basename, str1, '.tif'];
        if exist(filename1)
            [data,header]=genericOpenTif(filename1);
        elseif exist(filename2)
            [data,header]=genericOpenTif(filename2);
        else
            disp('No such file');
        end
        figure(fig_c);

            subplot(montage(1), montage(2), j);
            greenim = data(:,:,1);
            greenim = (greenim - cLimit(1))/(cLimit(2) - cLimit(1));

            redim = data(:,:,2);
            redim = (redim - cLimit2(1))/(cLimit2(2) - cLimit2(1));
            siz = size(greenim);
            colorim = zeros(siz(1), siz(2), 3);
            f = [1,1,1;1,1,1;1,1,1]/9;
            redim = filter2(f, redim);
            greenim = filter2(f, greenim);

            greenim(greenim > 1) = 1;
            greenim(greenim < 0) = 0;
            
            redim (redim >=1) = 1;
            redim (redim < 0) = 0;
            colorim(:, :, 1) = redim;
            colorim(:, :, 2) = greenim;
            image(colorim);
            set(gca, 'XTickLabel', '', 'YTickLabel', '');
        if movie
            F = getframe(gca);
            mov = addframe(mov,F);
        end
        j = j+1;
	end
catch
    disp(['Error at', num2str(i)]);
end
if movie
    mov = close(mov);
end
