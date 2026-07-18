clear y w time_ma b Pffty scPfy
close all;
format long;
clc;

%%% [MOD] === Exercise 1.7: SNR computation for a sinusoidal input ==========
%%% [MOD] Signal: single tone at sig_freq, sampled at fs.
%%% [MOD] Bandwidth of interest fb is "10x sig_freq" (slide 33: BW=20).
%%% [MOD] SNR = (sum of energy in signal bins) / (sum of energy in
%%% [MOD]       in-band noise bins, excluding signal bins).

%Input signal definition
%Sinusoidal input
sig_freq    = 2.003;
fs          = 1000;
nr_periods  = 10;
nr_bits     = 1;
amplitude   = 0.7;
offset      = 0.0;

nr_points   = round(nr_periods*fs/sig_freq);
in          = offset + amplitude*sin(2*pi*[1:nr_points]/(fs/sig_freq));

% Pre-allocates and initializes the variables
w = zeros(1,nr_points);
y = zeros(1,nr_points);
w(1) = 0.2;
y(1) = 1;

% The main loop simulating the accumulator and the quantizer
%************************************************************************
for a = 2:nr_points
    w(a) = w(a-1) + in(a-1) - y(a-1);
    y(a) = sign(w(a));
end
%************************************************************************

% Calculating and plotting the modulator output in frequency domain
% Also finding the bins related to the main tone, and the inband bins
%************************************************************************
N    = nr_points;
fres = fs/nr_points;
fin  = sig_freq;
fb   = fin*10;

ffty = (20*log10(abs(fft(y'.*(kaiser(length(y),20))))));
ffty = ffty - max(ffty);  % Scale the spectrum so peak = 0 dB

figure(1); semilogx((1:N/2)*fres, ffty(1:N/2));

maintone     = round(fin/fres);
signal_bins  = [maintone-7:maintone+7];
inband_bins  = [1:fb/fres];
noise_bins   = setdiff(inband_bins, signal_bins);

hold on;
semilogx(inband_bins*fres, ffty(inband_bins),'g','LineWidth',3);
semilogx(signal_bins*fres, ffty(signal_bins),'r','LineWidth',3);
legend('fs/2','Inband Bins','Main tone'); xlabel('frequency');
ylabel('Amplitude'); grid on;
saveas(gcf,'results/MOD1_SNR_spectrum.png');     %%% [MOD] save figure

%**********************************************************************
% Calculating the signal and noise power
%**********************************************************************
ffy = fft(y'.*kaiser(length(y),20));
s   = ffy.*conj(ffy);

signal_power = 10*log10(sum(s(signal_bins)));
noise_power  = 10*log10(sum(s(noise_bins)));

SNR = signal_power - noise_power

%%% [MOD] Sweep input amplitude to characterize peak SNR vs A
%%% [MOD] Useful for the assignment 1 follow-up: shows ΣΔ "dynamic range"
amp_list = [0.1, 0.3, 0.5, 0.7, 0.85, 0.95];
fprintf('\n  amplitude     signal_power[dB]   noise_power[dB]    SNR[dB]\n');
fprintf(' -----------   -----------------  ----------------   ----------\n');
for k = 1:length(amp_list)
    A = amp_list(k);
    in_k = A*sin(2*pi*[1:nr_points]/(fs/sig_freq));
    w_k = zeros(1,nr_points); y_k = zeros(1,nr_points); w_k(1)=0.2; y_k(1)=1;
    for a = 2:nr_points
        w_k(a) = w_k(a-1) + in_k(a-1) - y_k(a-1);
        y_k(a) = sign(w_k(a));
    end
    ffy_k = fft(y_k'.*kaiser(length(y_k),20));
    s_k   = ffy_k.*conj(ffy_k);
    sp = 10*log10(sum(s_k(signal_bins)));
    np = 10*log10(sum(s_k(noise_bins)));
    fprintf('   %5.2f         %+8.2f          %+8.2f         %+7.2f\n', ...
            A, sp, np, sp - np);
end
