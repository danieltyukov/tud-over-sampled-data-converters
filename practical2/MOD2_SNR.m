clc;clear all; close all;

%%% [MOD] === Exercise 2.2: SNR of MOD2 with sinusoidal input ==============

% Input signal definition
fin = 2.003; % input frequency
amplitude = 0.7;
offset = 0.0;
fb  = 4;     % signal bandwidth
fs  = 1000;  % sampling frequency

% Define the sinusoid input signal applied to the input of the modulator
nr_periods = 100;
nr_points = ceil(nr_periods*fs/fin);
in = offset + amplitude*sin(2*pi*[1:nr_points]/(fs/fin));

% Locaate the bins related to the main tone, as well as the inband bins
fres = fs/nr_points;
maintone = round(fin/fres);
signal_bins = [maintone-7:maintone+7];
inband_bins = [1:round(fb/fres)];
noise_bins = setdiff(inband_bins,signal_bins);

% w2 is the second accumulator's output
% w1 is the first accumulator's output
% a is the stabilizing zero coefficient
% Pre-allocate and initialize array variables => faster code
y  = zeros(1,nr_points); y(1) = 1;
w1 = y;  w1(1) = 0;
w2 = y;  w2(1) = 0;
a = 1;

%************************************************************************
% The main loop simulating the second order loop (delay-free 1st accumulator)
for i = 2:nr_points,
    w2(i) = w2(i-1) + w1(i-1) - a*y(i-1);
    y(i) = 2*(w2(i)>=0)-1;
    w1(i) = w1(i-1) + in(i) - y(i);
end

% Calculate bitstream FFT, signal and noise powers, and SNR
ffty = (fft(y'.*(kaiser(length(y),20)))); % window output and compute FFT

% To increase speed determine ONLY the power in the INBAND bins
inband_power = ffty(inband_bins).*conj(ffty(inband_bins));
signal_power = sum(inband_power(signal_bins)); % sum signal power
noise_power  = sum(inband_power(noise_bins));  % sum noise power

disp('Baseline (delay-free, a = 1) signal-to-noise ratio:');
SNR  = 10*log10(signal_power/noise_power) % calculate SNR in dB

%************************************************************************
% Display the output spectrum of the modulator
%************************************************************************
ffty_magn = abs(ffty);
ffty_dB = 20*log10(ffty_magn/max(ffty_magn)); % Scale the spectrum

figure(1); semilogx((1:nr_points/2)*fres,ffty_dB(1:nr_points/2),'-k','LineWidth',1.5);
xlabel('Frequency'); ylabel('Amplitude [dB]'); grid on;
title('Output spectrum of the 2nd order sigma delta modulator');
saveas(gcf,'results/MOD2_SNR_spectrum.png');

figure(2); semilogx((1:nr_points/2)*fres,ffty_dB(1:nr_points/2));
hold on;
plot(inband_bins*fres,ffty_dB(inband_bins),'g','LineWidth',3);
plot(signal_bins*fres,ffty_dB(signal_bins),'r','LineWidth',3);
hold off;
legend('Full spectrum','Inband Bins','Main tone','Location','southeast');
xlabel('frequency'); ylabel('Amplitude'); grid on;
saveas(gcf,'results/MOD2_SNR_bands.png');

%%% [MOD] === Part (a): SNR vs stabilizing coefficient (delay-free) ========
%%% [MOD] As a moves away from 1, the NTF zeros leave z = 1 so the in-band
%%% [MOD] noise floor rises and SNR degrades. Reproduces slide 12.
a_list_df = logspace(-1, 1, 31);
SNR_df = zeros(size(a_list_df));
for k = 1:length(a_list_df)
    SNR_df(k) = mod2_snr(in, a_list_df(k), 'delayfree', ...
                         signal_bins, inband_bins, noise_bins);
end

figure(3);
semilogx(a_list_df, SNR_df, 'b-o', 'LineWidth', 1.2);
grid on; xlabel('a [-]'); ylabel('SNR [dB]');
title('SNR vs stabilizing coefficient -- delay-free 1st acc.');
saveas(gcf,'results/MOD2_SNR_vs_a_delayfree.png');

%%% [MOD] Spectrum overlay at a few representative values
a_show = [1.0, 0.5, 0.1];
figure(4);
colors = {'k','b','r'};
for k = 1:length(a_show)
    yk = mod2_run(in, a_show(k), 'delayfree');
    fk = fft(yk' .* kaiser(length(yk),20));
    fk_dB = 20*log10(abs(fk)/max(abs(fk)));
    semilogx((1:nr_points/2)*fres, fk_dB(1:nr_points/2), colors{k}, ...
             'LineWidth', 1.0, 'DisplayName', sprintf('a = %g', a_show(k)));
    hold on;
end
hold off; grid on; legend('show');
xlabel('Frequency'); ylabel('Amplitude [dB]');
title('Output spectrum vs a (delay-free 1st acc.)');
saveas(gcf,'results/MOD2_SNR_spectrum_vs_a.png');

%%% [MOD] === Part (b): Delayed 1st accumulator ============================
%%% [MOD] w1 update becomes: w1(i) = w1(i-1) + in(i-1) - y(i-1)
%%% [MOD] Theory: a* = 2 reproduces NTF = (1 - z^-1)^2 (same noise shaping).
a_list_d = logspace(-1, 1, 31);
SNR_d = zeros(size(a_list_d));
for k = 1:length(a_list_d)
    SNR_d(k) = mod2_snr(in, a_list_d(k), 'delayed', ...
                        signal_bins, inband_bins, noise_bins);
end
[SNR_max_d, k_max] = max(SNR_d);
a_star = a_list_d(k_max);
fprintf('\n[Delayed sweep] best a* = %.3f -> SNR = %.2f dB\n', ...
        a_star, SNR_max_d);

figure(5);
semilogx(a_list_df, SNR_df, 'b-o', a_list_d, SNR_d, 'r-s', 'LineWidth', 1.2);
grid on; xlabel('a [-]'); ylabel('SNR [dB]');
legend('delay-free','delayed', 'Location','south');
title('SNR vs a -- delay-free vs delayed 1st accumulator');
saveas(gcf,'results/MOD2_SNR_delayed_vs_delayfree.png');

%%% [MOD] Spectrum comparison: delay-free a = 1 vs delayed a* = 2
y_df = mod2_run(in, 1.0, 'delayfree');
y_d2 = mod2_run(in, 2.0, 'delayed');
fdf = fft(y_df' .* kaiser(length(y_df),20));
fd2 = fft(y_d2' .* kaiser(length(y_d2),20));
fdf_dB = 20*log10(abs(fdf)/max(abs(fdf)));
fd2_dB = 20*log10(abs(fd2)/max(abs(fd2)));

figure(6);
semilogx((1:nr_points/2)*fres, fdf_dB(1:nr_points/2), 'b', ...
         (1:nr_points/2)*fres, fd2_dB(1:nr_points/2), 'r', ...
         'LineWidth', 1.0);
grid on; xlabel('Frequency'); ylabel('Amplitude [dB]');
legend('delay-free a = 1','delayed a* = 2','Location','southeast');
title('Spectrum: delay-free a=1 vs delayed a*=2');
saveas(gcf,'results/MOD2_SNR_spectrum_a1_vs_a2.png');

SNR_df_at1 = mod2_snr(in, 1.0, 'delayfree', signal_bins, inband_bins, noise_bins);
SNR_d_at2  = mod2_snr(in, 2.0, 'delayed',   signal_bins, inband_bins, noise_bins);
fprintf('\n[Final comparison]\n');
fprintf('  delay-free  a  = 1   ->  SNR = %.2f dB\n', SNR_df_at1);
fprintf('  delayed     a* = 2   ->  SNR = %.2f dB\n', SNR_d_at2);

%%% [MOD] === Helpers ======================================================
function y = mod2_run(in, a, kind)
    N  = length(in);
    y  = zeros(1,N); y(1) = 1;
    w1 = zeros(1,N);
    w2 = zeros(1,N);
    if strcmp(kind, 'delayfree')
        for i = 2:N
            w2(i) = w2(i-1) + w1(i-1) - a*y(i-1);
            y(i)  = 2*(w2(i)>=0) - 1;
            w1(i) = w1(i-1) + in(i)   - y(i);
        end
    else  % 'delayed'
        for i = 2:N
            w2(i) = w2(i-1) + w1(i-1) - a*y(i-1);
            y(i)  = 2*(w2(i)>=0) - 1;
            w1(i) = w1(i-1) + in(i-1) - y(i-1);
        end
    end
end

function SNR = mod2_snr(in, a, kind, sig_bins, inband_bins, noise_bins)
    y = mod2_run(in, a, kind);
    f = fft(y' .* kaiser(length(y),20));
    p = f(inband_bins) .* conj(f(inband_bins));
    SNR = 10*log10(sum(p(sig_bins)) / sum(p(noise_bins)));
end
