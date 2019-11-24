function spc_colorbar (a);

axes('Position', [0.95,0.1,0.02,0.4]);
scale = 56:-1:9; image(scale(:));
b = a(1:2);
if a(2) < a(1)
    b(1) = a(2);
    b(2) = a(1);
end
set(gca,'XTickLabel', [], 'YTick', [1,48], 'YTickLabel', b);

set(gcf, 'PaperPositionMode', 'auto');
set(gcf, 'PaperOrientation', 'landscape');