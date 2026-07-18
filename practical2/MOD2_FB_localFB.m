% 2nd order sigma-delta with feedback loop filter and local feedback (resonator)

clear all; close all;

%%% [MOD] === Exercise 2.5: scaled FB MOD2 with local feedback (resonator) ==

% Input and sampling definitions
fin        = 1.003;  % input frequency (kHz)
fs         = 5600;   % sampling frequency (kHz)
amplitude  = 0.5;
offset     = 0.00;
nr_periods = 200;

% system bandwidth
fb = 20;

N = round(nr_periods*fs/fin);

in = offset + amplitude*sin(2*pi*[1:N]/(fs/fin));

% Locate the bins related to the main tone, as well as the inband bins
fres = fs/N;
maintone = round(fin/fres);
signal_bins = [maintone-7:maintone+7];
inband_bins = [1:round(fb/fres)];
noise_bins = setdiff(inband_bins,signal_bins);

% Pre-allocation of vectors
y = zeros(1,N); w1 = y; w2 = y;  y(1) = 1;

% Feedback filter coefficients (unscaled)
b1 = 1; b2 = 1;
a1 = 1; a2 = 2;
d  = 0.00017;

% Main Modulator Loop (unscaled, baseline d value)
for a = 2:N
    w2(a) = w2(a-1) + b2*(w1(a-1)-a2*y(a-1));
    y(a) = 2*(w2(a)>=0)-1;
    w1(a) = w1(a-1) + b1*(in(a-1)-a1*y(a-1)-d*w2(a-1));
end

%************************************************************************
% Time domain output (unscaled)
%************************************************************************

figure(1);
subplot(3,1,1); plot(w1,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('w1 (1st Accumulator)');  grid on;
subplot(3,1,2); plot(w2,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('w2 (2nd Accumulator)');  grid on;
subplot(3,1,3); plot(y,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('y (Bitstream)');  grid on;
sgtitle(sprintf('Unscaled localFB MOD2 -- d=%.5g, max|w1|=%.2f, max|w2|=%.2f', ...
                d, max(abs(w1)), max(abs(w2))));
saveas(gcf,'results/MOD2_localFB_unscaled_time.png');

%************************************************************************
% Frequency domain output (unscaled)
%************************************************************************

ffty = abs(fft(y'.*(kaiser(length(y),20))));

figure(2);
semilogx((1:N/2)*fres,20*log10(ffty(1:N/2)),...
         signal_bins*fres,20*log10(ffty(signal_bins)),'r',...
         noise_bins*fres,20*log10(ffty(noise_bins)),'g','LineWidth',1);
grid on; xlabel('Frequency'); ylabel('Amplitude [dB]');
title('Output spectrum of the 2nd order FB modulator with local feedback');
saveas(gcf,'results/MOD2_localFB_unscaled_spectrum.png');

% SNR at the baseline d
signal_power = sum(ffty(signal_bins).^2);
noise_power  = sum(ffty(noise_bins).^2);
SNR_baseline = 10*log10(signal_power/noise_power);
fprintf('\n[Baseline localFB, d = %.5g]  SNR = %.2f dB\n', d, SNR_baseline);

%%% [MOD] === Sweep d: find the value that maximizes SNR ===================
%%% [MOD] d shifts the NTF zeros off DC into the band -> a notch appears.
%%% [MOD] Schreier rule of thumb: optimum f_notch = fb/sqrt(3) for MOD2.
d_list = [0, 5e-5, 1e-4, 1.5e-4, 1.7e-4, 2e-4, 3e-4, 5e-4];
SNR_d  = zeros(size(d_list));

fprintf('\n[d sweep]   d              SNR [dB]\n');
fprintf(           '-----------    ----------\n');
for k = 1:length(d_list)
    dk = d_list(k);
    yk = zeros(1,N); yk(1) = 1; w1k = zeros(1,N); w2k = zeros(1,N);
    for a = 2:N
        w2k(a) = w2k(a-1) + b2*(w1k(a-1) - a2*yk(a-1));
        yk(a)  = 2*(w2k(a)>=0)-1;
        w1k(a) = w1k(a-1) + b1*(in(a-1) - a1*yk(a-1) - dk*w2k(a-1));
    end
    fk = abs(fft(yk' .* kaiser(N,20)));
    sp = sum(fk(signal_bins).^2);
    np = sum(fk(noise_bins).^2);
    SNR_d(k) = 10*log10(sp/np);
    fprintf('  %10.5g    %8.2f\n', dk, SNR_d(k));
end

figure(3);
plot(d_list, SNR_d, 'b-o', 'LineWidth', 1.2);
grid on; xlabel('d [-]'); ylabel('SNR [dB]');
title('SNR vs local-feedback coefficient d');
saveas(gcf,'results/MOD2_localFB_SNR_vs_d.png');

% Pick the d that maximizes SNR (or stick with 0.00017 if sweep agrees)
[~, idx_best] = max(SNR_d);
d_best = d_list(idx_best);
fprintf('[d sweep]   best d = %.5g  ->  SNR = %.2f dB\n', d_best, SNR_d(idx_best));

%%% [MOD] === Compare d = 0 vs d = d_best in one spectrum overlay ==========
y0 = zeros(1,N); y0(1) = 1; w10 = zeros(1,N); w20 = zeros(1,N);
yB = zeros(1,N); yB(1) = 1; w1B = zeros(1,N); w2B = zeros(1,N);
for a = 2:N
    w20(a) = w20(a-1) + b2*(w10(a-1) - a2*y0(a-1));
    y0(a)  = 2*(w20(a)>=0)-1;
    w10(a) = w10(a-1) + b1*(in(a-1) - a1*y0(a-1) - 0*w20(a-1));

    w2B(a) = w2B(a-1) + b2*(w1B(a-1) - a2*yB(a-1));
    yB(a)  = 2*(w2B(a)>=0)-1;
    w1B(a) = w1B(a-1) + b1*(in(a-1) - a1*yB(a-1) - d_best*w2B(a-1));
end
f0 = abs(fft(y0' .* kaiser(N,20))); f0 = 20*log10(f0/max(f0)/sqrt(2));
fB = abs(fft(yB' .* kaiser(N,20))); fB = 20*log10(fB/max(fB)/sqrt(2));

figure(4);
semilogx((1:N/2)*fres, f0(1:N/2), 'b', 'LineWidth', 1.0); hold on;
semilogx((1:N/2)*fres, fB(1:N/2), 'g', 'LineWidth', 1.0); hold off;
grid on; xlabel('Frequency'); ylabel('Amplitude [dB]');
legend(sprintf('d = 0'), sprintf('d = %.5g', d_best), 'Location','southeast');
title('Local feedback: NTF notch at d > 0');
saveas(gcf,'results/MOD2_localFB_spectrum_d0_vs_dbest.png');

%%% [MOD] === Scale coefficients so |w1|, |w2| < 0.2 V at A = 0.5 V ========
%%% [MOD] After scaling, the loop transfer is preserved if:
%%% [MOD]   b1* = 0.06, b2* = 0.5, a2* = 2*b1*, d* = d/(b1*b2)
target = 0.2;
b1_s = target / max(abs(w1));            % ~ 0.06
b2_s = target / (b1_s * max(abs(w2)));   % ~ 0.5
a2_s = a2 * b1_s;
d_s  = d_best / (b1_s * b2_s);
fprintf('[Scaled localFB]  b1*=%.4f, b2*=%.4f, a2*=%.4f, d*=%.5g\n', ...
        b1_s, b2_s, a2_s, d_s);

y_s = zeros(1,N); y_s(1) = 1; w1_s = zeros(1,N); w2_s = zeros(1,N);
for a = 2:N
    w2_s(a) = w2_s(a-1) + b2_s*(w1_s(a-1) - a2_s*y_s(a-1));
    y_s(a)  = 2*(w2_s(a)>=0)-1;
    w1_s(a) = w1_s(a-1) + b1_s*(in(a-1) - a1*y_s(a-1) - d_s*w2_s(a-1));
end
fprintf('[Scaled localFB]  max|w1| = %.3f V, max|w2| = %.3f V\n', ...
        max(abs(w1_s)), max(abs(w2_s)));

figure(5);
subplot(3,1,1); plot(w1_s,'k','LineWidth',1.0);
xlabel('Samples'); ylabel('w1 [V]'); grid on; ylim([-0.3 0.3]);
subplot(3,1,2); plot(w2_s,'k','LineWidth',1.0);
xlabel('Samples'); ylabel('w2 [V]'); grid on; ylim([-0.3 0.3]);
subplot(3,1,3); plot(y_s,'k','LineWidth',1.0);
xlabel('Samples'); ylabel('y'); grid on;
sgtitle(sprintf('Scaled localFB MOD2 -- max|w1|=%.3f, max|w2|=%.3f', ...
                max(abs(w1_s)), max(abs(w2_s))));
saveas(gcf,'results/MOD2_localFB_scaled_time.png');

ff_s = abs(fft(y_s' .* kaiser(N,20)));
sp = sum(ff_s(signal_bins).^2); np = sum(ff_s(noise_bins).^2);
SNR_scaled = 10*log10(sp/np);
fprintf('[Scaled localFB]  SNR = %.2f dB\n', SNR_scaled);
