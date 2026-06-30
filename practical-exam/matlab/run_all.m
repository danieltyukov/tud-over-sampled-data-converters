% run_all.m
% regenerate every figure for the ET4278 fir-dac exam. each script is self
% contained (starts with clear; close all) and saves its png plots to results/.
% headless: matlab -nodisplay -batch run_all
% (flat sequence, not a loop, because each script calls clear)
FIRDSM_design;             close all;   % NTF (fig8), STF (fig9), F/E/H1
FIRDSM_sim;                close all;   % output PSD -4 dBFS (fig22)
FIRDSM_snr_vs_amp;         close all;   % SNR/SNDR vs amplitude (fig21)
FIRDSM_techniques_onoff;   close all;   % Q2.1 enable/disable
FIRDSM_metastability;      close all;   % first-tap-zero (fig4)
FIRDSM_jitter;             close all;   % white/fm jitter (figs 2,26,27)
FIRDSM_nonlin_integrator;  close all;   % weak cubic floor rise (fig3)
FIRDSM_thermal_decimation; close all;   % scaling, thermal, decimation
FIRDSM_nonideal;           close all;   % Q3.1/3.2/3.3 gain-bw, mismatch, eld
FIRDSM_isi_correction;     close all;   % Q7 isi + correction (figs 29,30)
disp('all scripts done. plots in results/');
