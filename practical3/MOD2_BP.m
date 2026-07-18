% Exercise 3.5 - 2nd order band-pass sigma delta modulator.
% Derived from the low-pass feedback modulator (Ex 2.3) with z^-1 -> -z^-2,
% which moves the NTF notch from DC to fs/4. The original SNR code measured
% a band at DC, which is wrong for a BP modulator: here the band is placed
% symmetrically around fs/4. A low-pass run is included for comparison.

clc; clear all; close all;

% Input / sampling
fs  = 1000;        % sampling frequency
fb  = 4;           % signal bandwidth
amplitude = 0.7;
offset = 0.0;
a = 2;             % stabilizing coefficient

nr_periods = 100;
nr_points  = ceil(nr_periods*fs/2);
fres = fs/nr_points;

%====================================================================
% Band-pass: signal sits at fs/4, noise band straddles fs/4
%====================================================================
fin_bp = 250.003;  % just off fs/4 so it lands inside the notch
in_bp  = offset + amplitude*sin(2*pi*(1:nr_points)/(fs/fin_bp));
y_bp   = bp_mod(in_bp, a);

% band of width fb centered on fs/4 (this is the fix vs the original code)
maintone_bp = round(fin_bp/fres);
signal_bins_bp = maintone_bp-7:maintone_bp+7;
inband_bp = round((fs/4 - fb/2)/fres) : round((fs/4 + fb/2)/fres);
noise_bins_bp = setdiff(inband_bp, signal_bins_bp);
SNR_bp = snr_calc(y_bp, signal_bins_bp, noise_bins_bp);

%====================================================================
% Low-pass reference: same prototype, notch at DC, band at DC
%====================================================================
fin_lp = 2.003;
in_lp  = offset + amplitude*sin(2*pi*(1:nr_points)/(fs/fin_lp));
y_lp   = lp_mod(in_lp, a);

maintone_lp = round(fin_lp/fres);
signal_bins_lp = maintone_lp-7:maintone_lp+7;
inband_lp = 1:round(fb/fres);
noise_bins_lp = setdiff(inband_lp, signal_bins_lp);
SNR_lp = snr_calc(y_lp, signal_bins_lp, noise_bins_lp);

fprintf('Band-pass (band around fs/4 = %g Hz):  SNR = %5.1f dB\n', fs/4, SNR_bp);
fprintf('Low-pass  (band around DC):            SNR = %5.1f dB\n', SNR_lp);
fprintf('Difference (LP - BP) = %4.1f dB\n', SNR_lp - SNR_bp);

%====================================================================
% Spectra
%====================================================================
f = (1:nr_points)*fres; half = 1:round(nr_points/2);

ffty_bp = abs(fft(y_bp'.*kaiser(nr_points,20)));
bp_dB = 20*log10(ffty_bp/max(ffty_bp));

% full BP spectrum (linear freq axis) showing the notch at fs/4
figure('Position',[100 100 1000 650]);
plot(f(half), bp_dB(half),'-b','LineWidth',1); grid on;
xlabel('Frequency [Hz]'); ylabel('Spectrum [dB]'); xlim([0 fs/2]);
xline(fs/4,'k--');
title('Output spectrum of the 2nd order band-pass modulator (notch at fs/4)');
legend('Full spectrum','fs/4','Location','south');
print(gcf, fullfile('results','MOD2_BP_spectrum.png'),'-dpng','-r110');

% zoom on the measurement band, showing signal and noise bins
figure('Position',[100 100 1000 650]);
plot(f, bp_dB,'-','Color',[0.5 0.5 0.5]); hold on;
plot(inband_bp*fres,    bp_dB(inband_bp),    'g','LineWidth',2);
plot(signal_bins_bp*fres,bp_dB(signal_bins_bp),'r','LineWidth',3);
hold off; grid on; xlim([fs/4-3*fb fs/4+3*fb]);
xlabel('Frequency [Hz]'); ylabel('Spectrum [dB]');
legend('Full spectrum','Measurement band','Main tone','Location','south');
title(sprintf('BP band around fs/4   (SNR = %.1f dB in %g Hz)',SNR_bp,fb));
print(gcf, fullfile('results','MOD2_BP_band_zoom.png'),'-dpng','-r110');

% LP vs BP spectra side by side (DC notch vs fs/4 notch)
ffty_lp = abs(fft(y_lp'.*kaiser(nr_points,20)));
lp_dB = 20*log10(ffty_lp/max(ffty_lp));
figure('Position',[100 100 1000 650]);
semilogx(f(half), lp_dB(half),'Color',[0.1 0.6 0.2]); hold on;
semilogx(f(half), bp_dB(half),'Color',[0.1 0.4 0.9]);
hold off; grid on; xlim([1 fs/2]);
xlabel('Frequency [Hz]'); ylabel('Spectrum [dB]');
legend(sprintf('Low-pass (notch at DC, SNR=%.1f dB)',SNR_lp), ...
       sprintf('Band-pass (notch at fs/4, SNR=%.1f dB)',SNR_bp),'Location','northwest');
title('Same 2nd order prototype: LP keeps the notch at DC, BP moves it to fs/4');
print(gcf, fullfile('results','MOD2_BP_vs_LP.png'),'-dpng','-r110');

%====================================================================
% Local functions
%====================================================================
function y = bp_mod(in, a)
% 2nd order band-pass (z^-1 -> -z^-2 transform of the LP feedback modulator)
N = numel(in); y = zeros(1,N); y(1)=1;
w1 = zeros(1,N); w2 = zeros(1,N);
for i = 3:N
    w2(i) = -w2(i-2) - (w1(i-2) - a*y(i-2));
    y(i)  = 2*(w2(i)>=0)-1;
    w1(i) = -w1(i-2) - (in(i-2) - y(i-2));
end
end

function y = lp_mod(in, a)
% Low-pass 2nd order feedback prototype (delay-free), the BP's origin
N = numel(in); y = zeros(1,N); y(1)=1;
w1 = zeros(1,N); w2 = zeros(1,N);
for i = 2:N
    w2(i) = w2(i-1) + w1(i-1) - a*y(i-1);
    y(i)  = 2*(w2(i)>=0)-1;
    w1(i) = w1(i-1) + in(i) - y(i);
end
end

function val = snr_calc(y, signal_bins, noise_bins)
ffty = fft(y(:).*kaiser(numel(y),20));
power = ffty.*conj(ffty);
val = 10*log10(sum(power(signal_bins))/sum(power(noise_bins)));
end
