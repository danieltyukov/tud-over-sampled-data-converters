% FIRDSM_thermal_decimation.m
% Q2.2 / Q2.3 / Q2.4 - voltage scaling (integrator swings), input-referred
% thermal noise sized for DR ~ 83 dB, and a sinc^(order+1) decimation filter
% with psd before/after + transient waveforms.
clear; close all; clc;
if ~exist('results','dir'), mkdir('results'); end
p = firdsm_params(); p.Nfft = 2^16; p.amp = 0.5;

% ---------- Q2.2 voltage scaling: per-integrator peak swing ----------
[y0,st0] = firdsm_run(p);
figure('Position',[100 100 800 520]);
bar(st0.mx, 'FaceColor',[.2 .4 .8]); grid on; hold on;
yline(0.45,'r--','LineWidth',1.5); hold off;
set(gca,'XTickLabel',{'I4 (in)','I3','I2','I1 (qnt)'});
ylabel('peak |state| (norm. to V_{ref})'); ylim([0 1.2]);
legend('peak swing','0.45 target','Location','northwest');
title('Integrator output swings (scaled so the first-order path saturates last)');
print(gcf, fullfile('results','FIRDSM_scaling'), '-dpng','-r110');
fprintf('peak integrator swings = [%.2f %.2f %.2f %.2f]\n', st0.mx);

% ---------- Q2.3 thermal noise -> DR ~ 83 dB ----------
noise_rms = 4.5e-4;
q = p; q.noise_rms = noise_rms;
[yt,stt] = firdsm_run(q); s = firdsm_spec(yt,q,stt.fin);
DR = s.SNR + (-20*log10(p.amp));     % extrapolate full-scale to snr=0
fprintf('thermal noise rms=%.1e -> SNR=%.1f dB, DR ~ %.0f dB (paper 83)\n', noise_rms, s.SNR, DR);
figure('Position',[100 100 950 620]);
ib=s.inband_bins; sb=s.signal_bins;
semilogx(s.faxis, s.fdB, 'Color',[.6 .6 .6],'LineWidth',1); hold on;
semilogx(s.faxis(ib), s.fdB(ib),'g','LineWidth',3);
semilogx(s.faxis(sb), s.fdB(sb),'r','LineWidth',3);
xline(p.fb,'b--','LineWidth',1.5); hold off; grid on;
xlim([1e6 p.fs/2]); ylim([-140 5]); xlabel('Frequency (Hz)'); ylabel('Amplitude (dBFS)');
legend('PSD','in-band','main tone','f_b','Location','southwest');
title(sprintf('Output PSD with input-referred thermal noise (SNR %.1f dB, DR ~ %.0f dB)', s.SNR, DR));
print(gcf, fullfile('results','FIRDSM_thermal'), '-dpng','-r110');

% ---------- Q2.4 sinc^(order+1) decimation ----------
D = 48;                              % decimation factor (~ OSR)
L = p.order + 1;                     % sinc^5 for a 4th-order modulator
h = 1; for i=1:L, h = conv(h, ones(1,D)); end; h = h/sum(h);   % cascaded boxcars
ydec_full = filter(h, 1, yt);
ydec = ydec_full(1:D:end);           % downsample
% psd before (bitstream) and after (decimated, lower rate)
Nb = numel(yt); fb_ax = (1:Nb/2)*(p.fs/Nb);
Yb = abs(fft(yt(:).*kaiser(Nb,20)))/(sum(kaiser(Nb,20))/2);
Nd = numel(ydec); fsd = p.fs/D; fd_ax = (1:Nd/2)*(fsd/Nd);
Yd = abs(fft(ydec(:).*kaiser(Nd,20)))/(sum(kaiser(Nd,20))/2);
figure('Position',[100 100 950 620]);
semilogx(fb_ax, 20*log10(Yb(1:Nb/2)+eps),'Color',[.6 .6 .6],'LineWidth',1); hold on;
semilogx(fd_ax, 20*log10(Yd(1:Nd/2)+eps),'b','LineWidth',1.2);
xline(p.fb,'g--','LineWidth',1.5); xline(fsd/2,'m--','LineWidth',1); hold off; grid on;
xlim([1e6 p.fs/2]); ylim([-140 5]); xlabel('Frequency (Hz)'); ylabel('Amplitude (dBFS)');
legend('bitstream (3.6 GS/s)','decimated','f_b','new f_s/2','Location','southwest');
title(sprintf('PSD before/after sinc^%d decimation (factor %d -> %.0f MS/s)', L, D, fsd/1e6));
print(gcf, fullfile('results','FIRDSM_decimation'), '-dpng','-r110');

% ---------- transient waveforms ----------
np = 2000;
figure('Position',[100 100 950 700]);
subplot(3,1,1); stairs(yt(1:np),'k'); ylim([-1.4 1.4]); grid on;
ylabel('bitstream v[n]'); title('Transient: 1-bit output');
subplot(3,1,2); plot(st0.fbwave(1:np),'b','LineWidth',1); grid on;
ylabel('FIR DAC v_1'); title('FIR DAC feedback (smooth multi-level)');
subplot(3,1,3);
tdec = (0:numel(ydec)-1)*D; tdr = tdec(tdec<np);
plot(1:np, p.amp*sin(2*pi*stt.fin/p.fs*(0:np-1)),'g','LineWidth',1.5); hold on;
stairs(tdr, ydec(1:numel(tdr)),'r','LineWidth',1.2); hold off; grid on;
xlabel('sample'); ylabel('signal'); legend('input','decimated out','Location','northeast');
title('Recovered output after decimation');
print(gcf, fullfile('results','FIRDSM_transient'), '-dpng','-r110');
fprintf('saved thermal, scaling, decimation, transient plots to results/\n');
