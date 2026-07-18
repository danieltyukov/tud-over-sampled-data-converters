% 2nd order sigma-delta with feed back loop filter

clear all; close all;

%%% [MOD] === Exercise 2.3: scale FB MOD2 so |w1|, |w2| <= 0.2 V ===========

% Input and sampling definitions
fin        = 1.003;  % input frequency (kHz)
fs         = 1000;   % sampling frequency (kHz)
amplitude  = 0.7;
offset     = 0.00;
nr_periods = 200;

N = round(nr_periods*fs/fin);

in = offset + amplitude*sin(2*pi*[1:N]/(fs/fin));

% Pre-allocation of vectors
y = zeros(1,N); w1 = y; w2 = y;  y(1) = 1;

% Feedback filter coefficients (unscaled)
b1 = 1; b2 = 1;
a1 = 1; a2 = 2;

% Main Modulator Loop
for a = 2:N,
    w2(a) = w2(a-1) + b2*(w1(a-1)-a2*y(a-1));
    y(a) = 2*(w2(a)>=0)-1;
    w1(a) = w1(a-1) + b1*(in(a-1)-a1*y(a-1));
end

%************************************************************************
% Display the 'time domain' output values
%************************************************************************

figure(1);
subplot(3,1,1); plot(w1,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('w1 (1st Accumulator)');  grid on;
subplot(3,1,2); plot(w2,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('w2 (2nd Accumulator)');  grid on;
subplot(3,1,3); plot(y,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('y (Bitstream)');  grid on;
sgtitle(sprintf('Unscaled FB MOD2 -- max|w1|=%.2f, max|w2|=%.2f', ...
                max(abs(w1)), max(abs(w2))));
saveas(gcf,'results/MOD2_FB_unscaled_time.png');

%************************************************************************
% Display the 'frequency domain' output values
%************************************************************************

fres = fs/N;

ffty = abs(fft(y'.*(kaiser(length(y),20)))); % compute magnitude spectrum

ffty = 20*log10(ffty/max(ffty)/sqrt(2)); % Scale the spectrum

figure(2);
semilogx((1:N/2)*fres,ffty(1:N/2),'-r','LineWidth',1);
grid on; xlabel('Frequency'); ylabel('Amplitude [dB]');
title('Output spectrum of the 2nd order feed-back sigma delta modulator');
saveas(gcf,'results/MOD2_FB_unscaled_spectrum.png');

%%% [MOD] === Report the unscaled swings ===================================
maxw1_orig = max(abs(w1));
maxw2_orig = max(abs(w2));
fprintf('\n[Unscaled] max|w1| = %.3f V, max|w2| = %.3f V\n', ...
        maxw1_orig, maxw2_orig);

%%% [MOD] === Compute scaled coefficients ==================================
%%% [MOD] Linear model: w1_s ~ b1*w1, w2_s ~ b1*b2*w2.
%%% [MOD] Pick b1 to bring max|w1| to 0.2 V; pick b2 to bring max|w2| to 0.2 V.
%%% [MOD] Slide-17 rule a* = a*b1 keeps the loop transfer shape intact, so
%%% [MOD] NTF and STF magnitudes are essentially unchanged with a 1-bit Q.
target = 0.2;
b1_s = target / maxw1_orig;
a2_s = a2 * b1_s;            % preserve H(z) shape
b2_s = target / (b1_s * maxw2_orig);
fprintf('[Scaled]   b1* = %.4f, b2* = %.4f, a2* = %.4f (a1 stays = 1)\n', ...
        b1_s, b2_s, a2_s);

%%% [MOD] Re-simulate with scaled coefficients
y_s  = zeros(1,N); y_s(1) = 1;
w1_s = zeros(1,N);
w2_s = zeros(1,N);
for a = 2:N
    w2_s(a) = w2_s(a-1) + b2_s*(w1_s(a-1) - a2_s*y_s(a-1));
    y_s(a)  = 2*(w2_s(a)>=0) - 1;
    w1_s(a) = w1_s(a-1) + b1_s*(in(a-1) - a1*y_s(a-1));
end
fprintf('[Scaled]   max|w1| = %.3f V, max|w2| = %.3f V\n', ...
        max(abs(w1_s)), max(abs(w2_s)));

%%% [MOD] Stability sanity check: re-run for 4x longer and confirm bounds
N_long = 4*N;
in_long = offset + amplitude*sin(2*pi*[1:N_long]/(fs/fin));
y_l  = zeros(1,N_long); y_l(1) = 1;
w1_l = zeros(1,N_long);
w2_l = zeros(1,N_long);
for a = 2:N_long
    w2_l(a) = w2_l(a-1) + b2_s*(w1_l(a-1) - a2_s*y_l(a-1));
    y_l(a)  = 2*(w2_l(a)>=0) - 1;
    w1_l(a) = w1_l(a-1) + b1_s*(in_long(a-1) - a1*y_l(a-1));
end
fprintf('[Stability check, 4x longer run]   max|w1| = %.3f V, max|w2| = %.3f V\n', ...
        max(abs(w1_l)), max(abs(w2_l)));

%%% [MOD] Time-domain plot of scaled modulator
figure(3);
subplot(3,1,1); plot(w1_s,'k','LineWidth',1.0);
xlabel('Samples'); ylabel('w1 [V]'); grid on; ylim([-0.3 0.3]);
subplot(3,1,2); plot(w2_s,'k','LineWidth',1.0);
xlabel('Samples'); ylabel('w2 [V]'); grid on; ylim([-0.3 0.3]);
subplot(3,1,3); plot(y_s,'k','LineWidth',1.0);
xlabel('Samples'); ylabel('y'); grid on;
sgtitle(sprintf('Scaled FB MOD2 -- max|w1|=%.3f, max|w2|=%.3f', ...
                max(abs(w1_s)), max(abs(w2_s))));
saveas(gcf,'results/MOD2_FB_scaled_time.png');

%%% [MOD] Spectrum of scaled modulator and overlay vs unscaled (STF check)
ffty_s = abs(fft(y_s' .* kaiser(length(y_s),20)));
ffty_s = 20*log10(ffty_s/max(ffty_s)/sqrt(2));

figure(4);
semilogx((1:N/2)*fres, ffty(1:N/2),  'r', 'LineWidth', 1.0); hold on;
semilogx((1:N/2)*fres, ffty_s(1:N/2),'b', 'LineWidth', 1.0); hold off;
grid on; xlabel('Frequency'); ylabel('Amplitude [dB]');
legend('unscaled','scaled', 'Location','southeast');
title('FB MOD2: spectrum unscaled vs scaled (STF + NTF check)');
saveas(gcf,'results/MOD2_FB_spectrum_compare.png');

%%% [MOD] Quantify in-band SNR before vs after scaling
fb_band     = 4;                              % signal bandwidth [kHz]
fres_lin    = fs/N;
maintone    = round(fin/fres_lin);
signal_bins = maintone-7:maintone+7;
inband_bins = 1:round(fb_band/fres_lin);
noise_bins  = setdiff(inband_bins, signal_bins);

ff_u = fft(y'    .* kaiser(N,20));   % unscaled bitstream
ff_s = fft(y_s'  .* kaiser(N,20));   % scaled bitstream
SNR_u = 10*log10(sum(abs(ff_u(signal_bins)).^2) / sum(abs(ff_u(noise_bins)).^2));
SNR_s = 10*log10(sum(abs(ff_s(signal_bins)).^2) / sum(abs(ff_s(noise_bins)).^2));
fprintf('[In-band SNR over %.1f kHz]  unscaled = %.2f dB, scaled = %.2f dB\n', ...
        fb_band, SNR_u, SNR_s);
