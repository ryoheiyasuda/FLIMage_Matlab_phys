function ryohei(flag)
global gh;

try
    close(gh.openingGUI.figure1);
end
userfile = 'c:\ryohei\ryohei_auto.usr';
if nargin
    spc_quickStart(userfile);
else
    scanimage(userfile);
end
h=findobj('Tag', 'ROIFigure');
set(h, 'Menubar', 'none');
read_autoSetting;

flimimage;
state.init.syncToPhysiology = 0;
