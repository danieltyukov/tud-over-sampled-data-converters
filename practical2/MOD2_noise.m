clear all; close all;

%%% [MOD] === Exercise 2.6: Thermal noise added at each integrator/quantizer ==
%%% [MOD] Noise at 1st integrator input is shaped just like the input -> NTF
%%% [MOD] does NOT suppress it in-band. Noise at 2nd integrator gets 1st-order
%%% [MOD] shaping. Noise at the quantizer input gets full 2nd-order shaping.
%%% [MOD] We size each noise budget separately so that the resulting SNR = 90 dB.

% Input and sampling definitions
fin        = 1.003;  % input frequency (kHz)
fs         = 1000;   % sampling frequency (kHz)
fb         = 2;      % signal bandwidth (kHz)
nr_periods = 200;
N = round(nr_periods*fs/fin);

% Locate signal / inband / noise bins
fres = fs/N;
maintone    = round(fin/fres);
signal_bins = [maintone-7:maintone+7];
inband_bins = [1:round(fb/fres)];
noise_bins  = setdiff(inband_bins, signal_bins);

a = 1;    % stabilizing zero coefficient

%%% [MOD] --- Part (a): DC input, with and without 1st-integrator noise ----
offset     = 34.6e-3;
amplitude  = 0;
in_dc      = offset + amplitude*sin(2*pi*[1:N]/(fs/fin));

cases_dc = struct('label', {'no noise', 'noise_rms_1 = 100e-6'}, ...
                  'n1',    {0, 100e-6});

figure(1);
for k = 1:length(cases_dc)
    n1 = cases_dc(k).n1;
    y  = zeros(1,N); y(1) = 1; w1 = zeros(1,N); w2 = zeros(1,N);
    for i = 2:N
        w2(i) = w2(i-1) + w1(i-1) - a*y(i-1);
        y(i)  = 2*(w2(i)>=0) - 1;
        w1(i) = w1(i-1) + in_dc(i-1) - y(i) + n1*randn;
    end
    f = abs(fft(y' .* kaiser(N,20)));
    subplot(2,1,k);
    semilogx((1:N/2)*fres, 20*log10(f(1:N/2)), 'k', 'LineWidth', 1);
    grid on; xlabel('Frequency [kHz]'); ylabel('Amplitude [dB]');
    title(sprintf('DC = %.4f V, %s', offset, cases_dc(k).label));
end
saveas(gcf,'results/MOD2_noise_DC_compare.png');

%%% [MOD] --- Part (b): sinusoidal input, size noise for SNR = 90 dB --------
amplitude = 0.7;
offset    = 0;
in_sin    = offset + amplitude*sin(2*pi*[1:N]/(fs/fin));
target_SNR = 90;        % dB

% Helper: simulate MOD2 with optional noise at each summing node
sim = @(n1, n2, nq) mod2_with_noise(in_sin, a, N, n1, n2, nq);
snr_of = @(y) snr_inband(y, signal_bins, noise_bins);

%%% [MOD] (b1) Noise ONLY at 1st integrator -> 0 dB/dec in-band slope
n1_list = [0, 50e-6, 200e-6, 1e-3, 5e-3];
fprintf('\n[Noise at 1st integrator]\n');
fprintf('  n1_rms        SNR [dB]\n');
fprintf('-----------    ---------\n');
SNR_n1 = zeros(size(n1_list));
for k = 1:length(n1_list)
    yk = sim(n1_list(k), 0, 0);
    SNR_n1(k) = snr_of(yk);
    fprintf('  %10.3g    %8.2f\n', n1_list(k), SNR_n1(k));
end

%%% [MOD] (b2) Noise ONLY at 2nd integrator -> 20 dB/dec shaping
n2_list = [0, 1e-3, 1e-2, 3e-2, 1e-1];
fprintf('\n[Noise at 2nd integrator]\n');
fprintf('  n2_rms        SNR [dB]\n');
fprintf('-----------    ---------\n');
SNR_n2 = zeros(size(n2_list));
for k = 1:length(n2_list)
    yk = sim(0, n2_list(k), 0);
    SNR_n2(k) = snr_of(yk);
    fprintf('  %10.3g    %8.2f\n', n2_list(k), SNR_n2(k));
end

%%% [MOD] (b3) Noise ONLY at quantizer -> 40 dB/dec shaping, so we tolerate a lot
nq_list = [0, 0.1, 0.3, 0.6, 1.0];
fprintf('\n[Noise at quantizer input]\n');
fprintf('  nq_rms        SNR [dB]\n');
fprintf('-----------    ---------\n');
SNR_nq = zeros(size(nq_list));
for k = 1:length(nq_list)
    yk = sim(0, 0, nq_list(k));
    SNR_nq(k) = snr_of(yk);
    fprintf('  %10.3g    %8.2f\n', nq_list(k), SNR_nq(k));
end

%%% [MOD] --- Show spectra at the slide-37 "SNR = 90 dB" operating points ---
y_n1 = sim(200e-6, 0, 0);
y_n2 = sim(0, 30e-3, 0);
y_nq = sim(0, 0, 0.6);

f_n1 = abs(fft(y_n1' .* kaiser(N,20))); f_n1 = 20*log10(f_n1/max(f_n1)/sqrt(2));
f_n2 = abs(fft(y_n2' .* kaiser(N,20))); f_n2 = 20*log10(f_n2/max(f_n2)/sqrt(2));
f_nq = abs(fft(y_nq' .* kaiser(N,20))); f_nq = 20*log10(f_nq/max(f_nq)/sqrt(2));

figure(2);
subplot(3,1,1);
semilogx((1:N/2)*fres, f_n1(1:N/2), 'b', 'LineWidth', 1);
grid on; ylabel('Amp [dB]');
title(sprintf('Noise at 1st integrator (n1 = 200e-6), SNR = %.1f dB', snr_of(y_n1)));
subplot(3,1,2);
semilogx((1:N/2)*fres, f_n2(1:N/2), 'r', 'LineWidth', 1);
grid on; ylabel('Amp [dB]');
title(sprintf('Noise at 2nd integrator (n2 = 30e-3), SNR = %.1f dB', snr_of(y_n2)));
subplot(3,1,3);
semilogx((1:N/2)*fres, f_nq(1:N/2), 'k', 'LineWidth', 1);
grid on; ylabel('Amp [dB]'); xlabel('Frequency [kHz]');
title(sprintf('Noise at quantizer (nq = 0.6), SNR = %.1f dB', snr_of(y_nq)));
saveas(gcf,'results/MOD2_noise_three_nodes.png');

%%% [MOD] === Helpers =======================================================
function y = mod2_with_noise(in, a, N, n1, n2, nq)
    y  = zeros(1,N); y(1) = 1;
    w1 = zeros(1,N); w2 = zeros(1,N);
    for i = 2:N
        w2(i) = w2(i-1) + w1(i-1) - a*y(i-1) + n2*randn;
        y(i)  = 2*((w2(i) + nq*randn) >= 0) - 1;
        w1(i) = w1(i-1) + in(i-1) - y(i) + n1*randn;
    end
end

function SNR = snr_inband(y, signal_bins, noise_bins)
    f = abs(fft(y' .* kaiser(length(y),20)));
    sp = sum(f(signal_bins).^2);
    np = sum(f(noise_bins).^2);
    SNR = 10*log10(sp/np);
end
