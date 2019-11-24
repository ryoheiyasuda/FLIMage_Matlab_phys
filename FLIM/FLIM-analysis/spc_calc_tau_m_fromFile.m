function spc_calc_tau_m_fromFile
global gui spc



 for i=1:spc.scanHeader.acq.numberOfFrames
     spc_openCurves(spc.filename, i, 1);
     [data1.tau_m(i+1), data1.intensity(i+1)] = spc_calc_tau_m;
end
                
filename2 = [spc.filename(1:end-4), '_tauM.mat'];
save(filename2, 'data1');
figure; subplot(1,2,1); plot(data1.tau_m); subplot(1,2,2); plot(data1.intensity);