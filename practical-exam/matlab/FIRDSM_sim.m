% FIRDSM_sim.m  Q2.6C: output psd at -4 dbfs, 10 mhz (fig 22). ideal + measured-like.
clear; close all; clc;
if ~exist('results','dir'), mkdir('results'); end

p = firdsm_params();
p.Nfft = 2^16;
p.amp  = 10^(-4/20);             % -4 dbfs input

% measured-like non-ideality budget (tuned to the paper's fig 22)
noise_rms = 4.5e-4;              % input-referred thermal noise -> snr ~ 76 db
isi_alpha = 7e-4;               % dac isi 2nd-order coeff -> hd2 ~ -73 db

% ideal run (quantisation-noise only)
[yi,sti] = firdsm_run(p); si = firdsm_spec(yi, p, sti.fin);
% measured-like run
q = p; q.noise_rms = noise_rms; q.isi_on = 1; q.isi_alpha = isi_alpha;
[ym,stm] = firdsm_run(q); sm = firdsm_spec(ym, q, stm.fin);

fprintf('ideal       : SNDR=%.1f SNR=%.1f HD2=%.1f HD3=%.1f dB\n', si.SNDR,si.SNR,si.HD2,si.HD3);
fprintf('measured-like: SNDR=%.1f SNR=%.1f HD2=%.1f HD3=%.1f dB\n', sm.SNDR,sm.SNR,sm.HD2,sm.HD3);
fprintf('paper fig 22 : SNDR=70.3 SNR=74.9 HD2=-73.5 HD3=-79.7 dB\n');

%% plot the measured-like psd (course signature style)
figure('Position',[100 100 950 620]);
ib = sm.inband_bins; sb = sm.signal_bins;
semilogx(sm.faxis/1e6, sm.fdB, '-', 'Color',[.6 .6 .6], 'LineWidth',1); hold on;
semilogx(sm.faxis(ib)/1e6, sm.fdB(ib), 'g', 'LineWidth',3);
semilogx(sm.faxis(sb)/1e6, sm.fdB(sb), 'r', 'LineWidth',3);
xline(p.fb/1e6,'b--','LineWidth',1.5);
hold off; grid on; xlim([1 p.fs/2e6]); ylim([-120 5]);   % match paper fig 22 axes
xlabel('Frequency (MHz)'); ylabel('Amplitude (dBFS)');
legend('PSD','in-band','main tone','f_b = 36 MHz','Location','southwest');
title(sprintf('Output PSD, -4 dBFS @ 10 MHz  (SNDR=%.1f, SNR=%.1f, HD2=%.1f, HD3=%.1f dB)',...
      sm.SNDR, sm.SNR, sm.HD2, sm.HD3));
print(gcf, fullfile('results','FIRDSM_sim_PSD'), '-dpng','-r110');

%% ideal vs measured-like overlay (shows the quant-noise floor)
figure('Position',[100 100 950 620]);
semilogx(si.faxis/1e6, si.fdB, 'b', 'LineWidth',1); hold on;
semilogx(sm.faxis/1e6, sm.fdB, 'r', 'LineWidth',1);
xline(p.fb/1e6,'k--','LineWidth',1.5); hold off; grid on;
xlim([1 p.fs/2e6]); ylim([-130 5]);
xlabel('Frequency (MHz)'); ylabel('Amplitude (dBFS)');
legend(sprintf('ideal (SQNR=%.0f dB)',si.SNDR), 'measured-like (thermal+ISI)','f_b','Location','southwest');
title('Output PSD: ideal quantisation noise vs measured-like (thermal + ISI)');
print(gcf, fullfile('results','FIRDSM_sim_PSD_ideal_vs_real'), '-dpng','-r110');
fprintf('saved psd plots to results/\n');
