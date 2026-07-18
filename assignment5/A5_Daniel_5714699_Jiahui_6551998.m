% Assignment 5 - 2-2 CT-MASH (two 2nd-order 1-bit feed-forward CT SDMs)
% Made by:
%   Jiahui Que,       6551998
%   Daniel Tyukov,    5714699
%
% Answers (run top to bottom; Question A sets fs, the FFT bins and g):
%
% Question A - design: both stages are the 2nd-order 1-bit CIFF CT loop from A3/A4
%   (b1=b2=1, c1=2, c2=1, NRZ DAC). Stage 2 digitizes the stage 1 quantization error
%   q1 = y1 - v1, scaled by g = 1/4 so it stays inside the stable 1-bit input range,
%   held NRZ over the next clock. Recombination y = H1*y1 - H2*y2 with H2 = NTF1/g =
%   4*(1-z^-1)^2 and H1 = STF2 = 2.475*z^-1 - 1.475*z^-2. The 0.475 comes from the
%   sub-step integration (int2 sees w1 mid-ramp); with a plain z^-1 for H1 the
%   cancellation leaks and the SQNR caps around 95 dB. Lowest OSR for 100 dB at
%   A = 0.7: OSR = 46 (fs = 1.84 MHz, SQNR = 101.7 dB, peak over amplitude also
%   101.7 dB at A = 0.65).
%
% Part 1 - final output FFT: 80 dB/dec slope, q1 is gone, only the doubly shaped
%   q2/g is left. y1 and y2 alone fall at 40 dB/dec like a single 2nd-order loop
%   (y1 SQNR = 64.3 dB), so the recombination buys the extra two orders.
%
% Part 2 - 1% gain error on H2: q1 no longer cancels, a 0.01*(1-z^-1)^2 shaped copy
%   of it leaks back in. SQNR drops 101.7 -> 98.3 dB. The leak is only 2nd-order
%   shaped (40 dB/dec), visible as the raised floor between 2 and 20 kHz, but it is
%   40 dB down so at this low OSR it costs just a few dB. At higher OSR (or bigger
%   error) the 40 dB/dec leak takes over and sets the converter, which is why MASH
%   needs tight analog/digital matching (high opamp gain, accurate coefficients)
%   in stage 1.
%
% Part 3 - thermal noise for 90 dB SNR: at the stage 1 input the noise adds like
%   the signal (STF ~ 1, no shaping), needs sigma1 = 475 uVrms (SNR = 89.7 dB). At
%   the stage 2 input the same SNR allows sigma2 = 56.9 mVrms (SNR = 90.0 dB),
%   120x or 41.6 dB more. Reason: stage 2 noise only reaches the output through
%   H2*STF2 ~ 4*(1-z^-1)^2, so the recombination 2nd-order shapes it (in-band
%   suppression pi^4/(5*OSR^4), minus the 12 dB from 1/g). Stage 1 noise is never
%   cancelled, it IS the input.
%
% Part 4 - 20% risetime: on DAC1 the pulse error sits at the stage 1 input and
%   passes like the signal, unshaped: DC offset (+0.06) plus a -41 dB 2nd harmonic
%   and a flat raised floor, SQNR crashes to 16.2 dB (same failure as A3). On DAC2
%   the same error is differentiated twice by the recombination, so it stays
%   shaped and the SQNR only drops to 77.5 dB, about 61 dB better. So the 1st
%   stage DAC must be as clean as the whole converter while the 2nd stage DAC
%   error is largely shaped away.
%
% Part 5 - stage 1 sets everything the user sees: its input noise, DAC linearity
%   and DAC timing hit the output unshaped, so it gets the low-noise input stage,
%   the clean DAC, high opamp DC gain (for the cancellation match) and most of the
%   power. Stage 2 only digitizes the small residue g*q1 and its errors (noise,
%   DAC, risetime) are 2nd-order shaped by H2, so it can use smaller caps, less
%   bias current and a sloppier DAC.

%% Question A + Part 1 - lowest OSR for 100 dB peak SQNR, FFT of the MASH output
clear all; close all; clc;
if ~exist('results','dir'), mkdir('results'); end

fin       = 1.003; % input frequency (kHz)
fb        = 20;    % bandwidth (kHz)
fres      = 0.05;  % FFT resolution (kHz)
amplitude = 0.7;   % MSA of the 1-bit 2nd-order loop (from A3)
offset    = 0.00;
nr_steps  = 20;    % CT sub-steps per clock period
g         = 1/4;   % interstage scaling on q1 so stage 2 is not overloaded

for OSR = 30:2:60
    fs = 2*fb*OSR;  % sampling frequency (kHz)
    N  = ceil(fs/fres);
    nr_periods = ceil(fin/fres);

    %******************************************************************
    % Locate the bins related to the main tone, as well as the inband bins
    %******************************************************************
    maintone    = nr_periods + 1;
    signal_bins = [maintone-7 : maintone+7];
    inband_bins = 1:round(20/fres);
    noise_bins  = setdiff(inband_bins, signal_bins);

    in = offset + amplitude*sin(2*pi*(fin/fs)*[1:N*nr_steps]/nr_steps);
    [y1, y2, q1, v1pk, v2pk] = mash22(in, N, nr_steps, g, 0, 0, 0, 0);
    y = recombine(y1, y2, g, nr_steps, 1);

    [SNR, ffty_dB] = spect_snr(y, amplitude, N, inband_bins, signal_bins, noise_bins);
    if (SNR > 100) break;
    end
end
fprintf('Oversampling ratio: %d (SQNR = %.2f dB, fs = %.2f MHz)\n', OSR, SNR, fs/1e3);
fprintf('max|v1| = %.2f, max|g*q1| = %.2f, max|v2| = %.2f (stage 2 stays stable)\n', ...
        v1pk, max(abs(g*q1)), v2pk);

% Stage spectra vs recombined output: stages fall at 40 dB/dec, y at 80 dB/dec
[SNR1, ffty1_dB] = spect_snr(y1, amplitude, N, inband_bins, signal_bins, noise_bins);
[~,    ffty2_dB] = spect_snr(y2, amplitude, N, inband_bins, signal_bins, noise_bins);
fprintf('Stage 1 alone: SQNR = %.2f dB (y2 carries only g*q1, no signal)\n', SNR1);

fHz  = (1:round(N/2))*fres*1e3;
half = 1:round(N/2);
figure(1);
semilogx(fHz, ffty2_dB(half), 'Color', [0.1 0.4 0.9]); hold on;
semilogx(fHz, ffty1_dB(half), 'Color', [0.1 0.7 0.2]);
semilogx(fHz, ffty_dB(half),  'Color', [0.85 0.2 0.1]);
xline(fb*1e3, 'k--'); hold off; grid on;
xlabel('Frequency (Hz)'); ylabel('Amplitude (dB)');
legend('y2 (stage 2, 2nd order)', 'y1 (stage 1, 2nd order)', ...
       'y (MASH, 4th order)', 'BW edge', 'Location', 'northwest');
title('2-2 MASH: stage outputs vs recombined output');
print(gcf, fullfile('results','A5_part1_Y_Y1_Y2.png'), '-dpng', '-r110');

plot_spec(2, ffty_dB, fres, N, inband_bins, signal_bins, ...
          sprintf('2-2 CT-MASH output spectrum (OSR = %d, SQNR = %.1f dB)', OSR, SNR));
print(gcf, fullfile('results','A5_part1_spectrum.png'), '-dpng', '-r110');

% Peak SQNR check: sweep the input amplitude at this OSR
amps    = 0.4:0.05:0.9;
snr_amp = zeros(size(amps));
for k = 1:length(amps)
    ina = offset + amps(k)*sin(2*pi*(fin/fs)*[1:N*nr_steps]/nr_steps);
    [y1a, y2a] = mash22(ina, N, nr_steps, g, 0, 0, 0, 0);
    ya = recombine(y1a, y2a, g, nr_steps, 1);
    snr_amp(k) = spect_snr(ya, amps(k), N, inband_bins, signal_bins, noise_bins);
end
[snr_pk, kpk] = max(snr_amp);
fprintf('Peak SQNR %.1f dB at A = %.2f\n', snr_pk, amps(kpk));

figure(3);
plot(amps, snr_amp, 'ko-', 'LineWidth', 1.5);
xlabel('Input amplitude'); ylabel('SQNR (dB)'); grid on;
title('2-2 MASH SQNR vs input amplitude');
print(gcf, fullfile('results','A5_questionA_snr_vs_amp.png'), '-dpng', '-r110');


%% Part 2 - 1% gain error on a reconstruction filter
% Same two bitstreams as Question A, only the digital H2 path is scaled by 1.01.
y_err = recombine(y1, y2, g, nr_steps, 1.01);
[SNR_err, ffty_err_dB] = spect_snr(y_err, amplitude, N, inband_bins, signal_bins, noise_bins);
fprintf('1%% gain error on H2: SQNR %.2f -> %.2f dB\n', SNR, SNR_err);

figure(4);
semilogx(fHz, ffty_err_dB(half), 'Color', [0.85 0.2 0.1]); hold on;
semilogx(fHz, ffty_dB(half),     'Color', [0.3 0.3 0.3]);
xline(fb*1e3, 'k--'); hold off; grid on;
xlabel('Frequency (Hz)'); ylabel('Amplitude (dB)');
legend(sprintf('H2 * 1.01 (SQNR = %.1f dB)', SNR_err), ...
       sprintf('ideal (SQNR = %.1f dB)', SNR), 'BW edge', 'Location', 'northwest');
title('1% gain error on H2: leaked q1 fills the low end at 40 dB/dec');
print(gcf, fullfile('results','A5_part2_gain_error.png'), '-dpng', '-r110');


%% Part 3 - thermal noise for 90 dB SNR, stage 1 input vs stage 2 input
% Stage 1: same formula as A3, the noise adds at the input node so it passes
% with STF ~ 1 and directly sets the SNR.
noise1_rms = amplitude*sqrt(fs*nr_steps/4/fb/10^(90/10));
[y1n, y2n] = mash22(in, N, nr_steps, g, noise1_rms, 0, 0, 0);
yn1 = recombine(y1n, y2n, g, nr_steps, 1);
[SNR_n1, ffty_n1_dB] = spect_snr(yn1, amplitude, N, inband_bins, signal_bins, noise_bins);

% Stage 2: that noise only reaches y through H2*STF2 ~ (1/g)*(1-z^-1)^2, in-band
% suppression pi^4/(5*OSR^4), so the allowed rms grows by g*sqrt(5)*(OSR/pi)^2.
noise2_rms = noise1_rms * g * sqrt(5) * (OSR/pi)^2;
[y1n2, y2n2] = mash22(in, N, nr_steps, g, 0, noise2_rms, 0, 0);
yn2 = recombine(y1n2, y2n2, g, nr_steps, 1);
[SNR_n2, ffty_n2_dB] = spect_snr(yn2, amplitude, N, inband_bins, signal_bins, noise_bins);

fprintf('Stage 1 noise: %8.1f uVrms -> SNR = %.2f dB\n', noise1_rms*1e6, SNR_n1);
fprintf('Stage 2 noise: %8.1f uVrms -> SNR = %.2f dB (%.0fx more, %.1f dB relaxed)\n', ...
        noise2_rms*1e6, SNR_n2, noise2_rms/noise1_rms, 20*log10(noise2_rms/noise1_rms));

figure(5);
semilogx(fHz, ffty_n2_dB(half), 'Color', [0.1 0.4 0.9]); hold on;
semilogx(fHz, ffty_n1_dB(half), 'Color', [0.85 0.2 0.1]);
xline(fb*1e3, 'k--'); hold off; grid on;
xlabel('Frequency (Hz)'); ylabel('Amplitude (dB)');
legend(sprintf('noise at stage 2 in (%.1f mVrms)', noise2_rms*1e3), ...
       sprintf('noise at stage 1 in (%.0f uVrms)', noise1_rms*1e6), ...
       'BW edge', 'Location', 'northwest');
title('Same 90 dB SNR, noise at stage 1 vs stage 2 input');
print(gcf, fullfile('results','A5_part3_thermal_noise.png'), '-dpng', '-r110');


%% Part 4 - 20% DAC risetime, stage 1 DAC vs stage 2 DAC
% Slow rise (20% of Tclk, instant fall) on DAC1, DAC2 ideal
[y1r, y2r] = mash22(in, N, nr_steps, g, 0, 0, 0.2, 0);
yr1 = recombine(y1r, y2r, g, nr_steps, 1);
[SNR_r1, ffty_r1_dB] = spect_snr(yr1, amplitude, N, inband_bins, signal_bins, noise_bins);

% Same risetime on DAC2, DAC1 ideal
[y1s, y2s] = mash22(in, N, nr_steps, g, 0, 0, 0, 0.2);
yr2 = recombine(y1s, y2s, g, nr_steps, 1);
[SNR_r2, ffty_r2_dB] = spect_snr(yr2, amplitude, N, inband_bins, signal_bins, noise_bins);

% Asymmetric DAC1 error: look for a DC offset and even harmonics, as in A3
dc1 = mean(yr1(2:N+1));
h2bin = 2*(maintone-1) + 1;
fprintf('DAC1 20%% risetime: SQNR = %.2f dB (DC offset = %+.4f, HD2 bin = %.1f dB)\n', ...
        SNR_r1, dc1, ffty_r1_dB(h2bin));
fprintf('DAC2 20%% risetime: SQNR = %.2f dB\n', SNR_r2);

plot_spec(6, ffty_r1_dB, fres, N, inband_bins, signal_bins, ...
          sprintf('1st stage DAC with 20%% risetime (SQNR = %.1f dB)', SNR_r1));
print(gcf, fullfile('results','A5_part4_rise_stage1.png'), '-dpng', '-r110');

plot_spec(7, ffty_r2_dB, fres, N, inband_bins, signal_bins, ...
          sprintf('2nd stage DAC with 20%% risetime (SQNR = %.1f dB)', SNR_r2));
print(gcf, fullfile('results','A5_part4_rise_stage2.png'), '-dpng', '-r110');


%% functions used

function [y1, y2, q1, v1pk, v2pk] = mash22(in, N, nr_steps, g, noise1_rms, noise2_rms, rise1_frac, rise2_frac)
% 2-2 CT-MASH, both stages the 2nd-order 1-bit CIFF CT loop from A3/A4.
% Stage 2 input is g*q1 (q1 = y1 - v1), held NRZ over the next clock period.
% rise*_frac > 0 gives that stage a slow DAC rise with an instant fall, as in A3.

om1 = 1/nr_steps; om2 = 1/nr_steps;
b1 = 1; b2 = 1;
c1 = 2*b2; c2 = 1;

w1 = zeros(1, N*nr_steps+1); w2 = w1; v = w1;   % stage 1 states
x1 = zeros(1, N*nr_steps+1); x2 = x1; u = x1;   % stage 2 states
y1 = zeros(1, N+1); y2 = zeros(1, N+1);
q1 = zeros(1, N+1); u2 = zeros(1, N+1);         % stage 2 held input

rise1_steps = round(rise1_frac*nr_steps);
rise2_steps = round(rise2_frac*nr_steps);
prev1 = -1; prev2 = -1;
ix = 1;

for a = 2:N+1
    dac1 = dacwave(y1(a-1), prev1, nr_steps, rise1_steps); prev1 = y1(a-1);
    dac2 = dacwave(y2(a-1), prev2, nr_steps, rise2_steps); prev2 = y2(a-1);
    for b = 1:nr_steps
        ix = ix + 1;
        % stage 1
        w2(ix) = w2(ix-1) + om2*b2*w1(ix-1);
        w1(ix) = w1(ix-1) + om1*b1*(in(ix-1) - dac1(b) + noise1_rms*randn);
        v(ix)  = c1*w1(ix) + c2*w2(ix);
        % stage 2
        x2(ix) = x2(ix-1) + om2*b2*x1(ix-1);
        x1(ix) = x1(ix-1) + om1*b1*(u2(a-1) - dac2(b) + noise2_rms*randn);
        u(ix)  = c1*x1(ix) + c2*x2(ix);
    end
    y1(a) = 2*(v(ix) >= 0) - 1;
    q1(a) = y1(a) - v(ix);          % stage 1 quantization error
    u2(a) = g*q1(a);                % goes to stage 2 next clock
    y2(a) = 2*(u(ix) >= 0) - 1;
end
v1pk = max(abs(v));
v2pk = max(abs(u));
end

function wave = dacwave(curr, prev, nr_steps, rise_steps)
% NRZ DAC waveform over one clock period. Slow rise on a -1 to +1 transition
% (linear ramp over rise_steps sub-steps), instant fall, same model as A3.
if rise_steps > 0 && prev == -1 && curr == +1
    wave = -1 + 2*min((0:nr_steps-1), rise_steps)/rise_steps;
else
    wave = curr*ones(1, nr_steps);
end
end

function y = recombine(y1, y2, g, nr_steps, h2_gain)
% Digital cancellation: y = H1*y1 - H2*y2 with H1 = STF2, H2 = NTF1/g.
% The DT equivalent of this sub-stepped CT loop is
%   NTF = (1-z^-1)^2 / D,   STF = z^-1*((2+kap) - (1+kap)*z^-1) / D
% with kap = (nr_steps-1)/(2*nr_steps): int2 integrates w1 while it ramps, so
% it picks up kap of the new w1 value. The common D drops out of
% H1*NTF1 - H2*g*STF2, so two small FIR filters cancel q1 exactly.
kap = (nr_steps-1)/(2*nr_steps);
y = filter([0 2+kap -(1+kap)], 1, y1) - h2_gain*(1/g)*filter([1 -2 1], 1, y2);
end

function [SNR, ffty_dB] = spect_snr(y, amplitude, N, inband_bins, signal_bins, noise_bins)
% Kaiser-windowed FFT, SNR over the 20 kHz band, same convention as A3/A4
ffty = fft(y(2:N+1)'.*kaiser(N,20));
inband_power = ffty(inband_bins).*conj(ffty(inband_bins));
SNR = 10*log10(sum(inband_power(signal_bins))/sum(inband_power(noise_bins)));
ffty_dB = 20*log10(abs(ffty)/(amplitude*N/2));
end

function plot_spec(fignr, ffty_dB, fres, N, inband_bins, signal_bins, ttl)
% Output spectrum plot, same style as A3/A4
figure(fignr);
semilogx((1:round(N/2))*fres*1e3, ffty_dB(1:round(N/2)));
hold on;
semilogx(inband_bins*fres*1e3, ffty_dB(inband_bins), 'g', 'LineWidth', 3);
semilogx(signal_bins*fres*1e3, ffty_dB(signal_bins), 'r', 'LineWidth', 3);
hold off;
legend('fs/2', 'Inband Bins', 'Main tone');
xlabel('Frequency (Hz)'); ylabel('Amplitude (dB)'); grid on;
title(ttl);
end
