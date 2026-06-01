% Exercise 3.3 - 1-1 MASH (cascaded 1st + 1st order) built from a 1st order modulator.
% Two 1st order loops: the second one digitizes the quantization error of the
% first, then a digital filter cancels it. The leftover is 2nd order shaped.
%
%   Y(z) = z^-2 X(z) - (1-z^-1)^2 Q2(z)
%
% This script:
%   - shows Y, Y1, Y2 spectra (2nd order shaping for Y, 1st order for the stages)
%   - sizes the loop for SQNR ~ 100 dB and SNR ~ 90 dB over a 20 kHz BW
%   - sweeps the input amplitude to find the SNR optimum
%   - compares against a single-loop 2nd order modulator
%   - shows what integrator leakage (alpha < 1) does to the cancellation

close all; clear; clc;

% Input and sampling
fin = 1.003e3;     % input frequency [Hz]
fb  = 20e3;        % signal bandwidth [Hz]
fbl = 20;          % low edge of the noise band [Hz]
OSR = 200;
fs  = 2*fb*OSR;    % sampling frequency [Hz]
offset = 0.00;
nr_periods = 50;
nr_points  = round(nr_periods*fs/fin);

% FFT bins
fres = fs/nr_points;
maintone    = round(fin/fres);
signal_bins = [maintone-7:maintone+8];
inband_bins = [max([1 round(fbl/fres)]):round(fb/fres)];
noise_bins  = setdiff(inband_bins,signal_bins);

% Thermal noise sized for ~90 dB SNR at full scale (A = 0.9).
% white over the whole band, so total rms = inband rms * sqrt(OSR)
A_design = 0.9;
noise_rms = A_design/sqrt(2)/10^(90/20)*sqrt(OSR);

%====================================================================
% 1) SQNR run (no thermal noise) at A = 0.7, plus Y/Y1/Y2 spectra
%====================================================================
A = 0.7;
in = offset + A*sin(2*pi*(1:nr_points)/(fs/fin));
[y, y1, y2] = mash11(in, 1.0, 0);

SQNR = snr_calc(y, signal_bins, noise_bins);
fprintf('MASH  A=%.1f  OSR=%d  SQNR (no noise)   = %5.1f dB\n', A, OSR, SQNR);

% spectra of the three signals
YdB  = 20*log10(abs(fft(y' .*kaiser(nr_points,20))));
Y1dB = 20*log10(abs(fft(y1'.*kaiser(nr_points,20))));
Y2dB = 20*log10(abs(fft(y2'.*kaiser(nr_points,20))));
f = (1:nr_points)*fres;
half = 1:round(nr_points/2);

figure('Position',[100 100 1000 650]);
semilogx(f(half),Y2dB(half),'Color',[0.1 0.4 0.9]); hold on;
semilogx(f(half),Y1dB(half),'Color',[0.1 0.7 0.2]);
semilogx(f(half),YdB(half), 'Color',[0.85 0.2 0.1]);
xline(fb,'k--'); hold off; grid on; xlim([1e2 fs/2]);
xlabel('Frequency [Hz]'); ylabel('Spectrum [dB]');
legend('Y2 (stage 2, 1st order)','Y1 (stage 1, 1st order)','Y (MASH, 2nd order)','BW edge','Location','northwest');
title('MASH output spectra: stages are 1st order, recombined Y is 2nd order');
print(gcf, fullfile('results','MASH_Y_Y1_Y2.png'),'-dpng','-r110');

% main output spectrum with the inband / signal bins marked
ffty = fft(y'.*kaiser(nr_points,20));
ydB  = 20*log10(abs(ffty)/(A*nr_points/2));
figure('Position',[100 100 1000 650]);
semilogx(f(half),ydB(half),'Color',[0.3 0.3 0.3]); hold on;
semilogx(inband_bins*fres,ydB(inband_bins),'g','LineWidth',2);
semilogx(signal_bins*fres,ydB(signal_bins),'r','LineWidth',3);
hold off; grid on; xlim([1e2 fs/2]);
xlabel('Frequency [Hz]'); ylabel('Spectrum [dB]');
legend('Full spectrum','Inband bins','Main tone','Location','northwest');
title(sprintf('MASH output spectrum  (A=%.1f, OSR=%d, SQNR=%.1f dB)',A,OSR,SQNR));
print(gcf, fullfile('results','MASH_output_spectrum.png'),'-dpng','-r110');

%====================================================================
% 2) SNR run with thermal noise at A = 0.9
%====================================================================
A = 0.9;
in = offset + A*sin(2*pi*(1:nr_points)/(fs/fin));
[yn,~,~] = mash11(in, 1.0, noise_rms);
SNRn = snr_calc(yn, signal_bins, noise_bins);
fprintf('MASH  A=%.1f  with thermal noise  SNR   = %5.1f dB\n', A, SNRn);

%====================================================================
% 3) Compare to a single-loop 2nd order modulator (same OSR, A=0.7, no noise)
%====================================================================
A = 0.7;
in = offset + A*sin(2*pi*(1:nr_points)/(fs/fin));
ys = mod2_single(in);
SQNR_single = snr_calc(ys, signal_bins, noise_bins);
fprintf('Single-loop MOD2  A=%.1f  SQNR (no noise) = %5.1f dB\n', A, SQNR_single);
fprintf('MASH output levels: %s\n', mat2str(unique(round(y))));

%====================================================================
% 4) Input amplitude sweep for the SNR optimum (thermal noise on)
%====================================================================
amp_vec = logspace(-1,log10(0.95),20);
SNR_sweep = zeros(size(amp_vec));
for k = 1:numel(amp_vec)
    in = offset + amp_vec(k)*sin(2*pi*(1:nr_points)/(fs/fin));
    [yk,~,~] = mash11(in, 1.0, noise_rms);
    SNR_sweep(k) = snr_calc(yk, signal_bins, noise_bins);
end
[SNR_max, imax] = max(SNR_sweep);
fprintf('SNR sweep peak: %5.1f dB at A = %.3f V\n', SNR_max, amp_vec(imax));

figure('Position',[100 100 900 600]);
semilogx(amp_vec, SNR_sweep,'-o','LineWidth',2,'Color',[0.1 0.4 0.9]); grid on;
xlabel('Signal amplitude [V]'); ylabel('SNR [dB]');
title('MASH SNR vs input amplitude (thermal noise on)');
print(gcf, fullfile('results','MASH_SNR_vs_amplitude.png'),'-dpng','-r110');

%====================================================================
% 5) Integrator leakage: alpha = 1 vs alpha = 0.99 (no thermal noise)
%====================================================================
A = 0.9;
in = offset + A*sin(2*pi*(1:nr_points)/(fs/fin));
[ya,~,~] = mash11(in, 1.00, 0);
[yl,~,~] = mash11(in, 0.99, 0);
SQNR_a1  = snr_calc(ya, signal_bins, noise_bins);
SQNR_lk  = snr_calc(yl, signal_bins, noise_bins);
fprintf('Leakage:  alpha=1.00 SQNR=%.1f dB   alpha=0.99 SQNR=%.1f dB\n', SQNR_a1, SQNR_lk);

YadB = 20*log10(abs(fft(ya'.*kaiser(nr_points,20))));
YldB = 20*log10(abs(fft(yl'.*kaiser(nr_points,20))));
figure('Position',[100 100 1000 650]);
semilogx(f(half),YadB(half),'Color',[0.1 0.7 0.2]); hold on;
semilogx(f(half),YldB(half),'Color',[0.1 0.4 0.9]);
xline(fb,'k--'); hold off; grid on; xlim([1e2 fs/2]);
xlabel('Frequency [Hz]'); ylabel('Spectrum [dB]');
legend(sprintf('alpha=1 (SQNR=%.1f dB)',SQNR_a1), ...
       sprintf('alpha=0.99 (SQNR=%.1f dB)',SQNR_lk),'BW edge','Location','northwest');
title('MASH integrator leakage: alpha<1 breaks the q1 cancellation');
print(gcf, fullfile('results','MASH_leakage.png'),'-dpng','-r110');

%====================================================================
% Local functions
%====================================================================
function [y, y1, y2] = mash11(in, alpha, noise_rms)
% 1-1 MASH. Stage 2 modulates the quantization error of stage 1, then a
% digital filter recombines: y(i) = y1(i-1) - (y2(i) - y2(i-1)).
N  = numel(in);
w1 = zeros(1,N); y1 = zeros(1,N);
w2 = zeros(1,N); y2 = zeros(1,N); q1 = zeros(1,N);
y  = zeros(1,N);
for i = 2:N
    w1(i) = alpha*w1(i-1) + in(i-1) - y1(i-1) + noise_rms*randn;
    y1(i) = 2*(w1(i)>=0)-1;
    q1(i) = y1(i) - w1(i);                 % stage 1 quantization error
    w2(i) = alpha*w2(i-1) + q1(i-1) - y2(i-1);
    y2(i) = 2*(w2(i)>=0)-1;
    y(i)  = y1(i-1) - (y2(i) - y2(i-1));   % digital cancellation filter
end
end

function y = mod2_single(in)
% Single-loop 2nd order (delay-free 1st accumulator), 1-bit, a = 2.
N = numel(in); a = 2;
y  = zeros(1,N); y(1)=1;
w1 = zeros(1,N); w2 = zeros(1,N);
for i = 2:N
    w2(i) = w2(i-1) + w1(i-1) - a*y(i-1);
    y(i)  = 2*(w2(i)>=0)-1;
    w1(i) = w1(i-1) + in(i-1) - y(i);
end
end

function val = snr_calc(y, signal_bins, noise_bins)
ffty = fft(y(:).*kaiser(numel(y),20));
power = ffty.*conj(ffty);
val = 10*log10(sum(power(signal_bins))/sum(power(noise_bins)));
end
