% 2nd order sigma-delta with feed-forward loop filter

clear all; close all;

%%% [MOD] === Exercise 2.4: FF MOD2 -- 1st acc shape, scaling, delay-less ===

% Input and sampling definitions
fin        = 1.003;  % input frequency (kHz)
fs         = 1000;   % sampling frequency (kHz)
amplitude  = 0.7;
offset     = 0.00;
nr_periods = 200;

N = round(nr_periods*fs/fin);

in = offset + amplitude*sin(2*pi*[1:N]/(fs/fin));

% Pre-allocation of vectors
y = zeros(1,N); w1 = y; w2 = y; w12 = y; y(1) = 1;

% Feed Forward filter coefficients (unscaled baseline)
b1 = 1; b2 = 1;
c1 = 2; c2 = 1;

% Main modulator Loop
for a = 2:N
    w2(a)  = w2(a-1) + b2*w1(a-1);
    w1(a)  = w1(a-1)  + b1*(in(a-1) - y(a-1));
    w12(a) = c1*w1(a) + c2*w2(a);
    y(a)   = 2*(w12(a)>=0)-1;
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
sgtitle(sprintf('Unscaled FF MOD2 -- max|w1|=%.2f, max|w2|=%.2f', ...
                max(abs(w1)), max(abs(w2))));
saveas(gcf,'results/MOD2_FF_unscaled_time.png');

%************************************************************************
% Frequency domain output (unscaled)
%************************************************************************

fres = fs/N;

ffty = abs(fft(y'.*(kaiser(length(y),20))));
ffty = 20*log10(ffty/max(ffty)/sqrt(2));

figure(2);
semilogx((1:N/2)*fres,ffty(1:N/2),'-r','LineWidth',1);
grid on; xlabel('Frequency'); ylabel('Amplitude [dB]');
title('Output spectrum of the 2nd order feed forward sigma delta modulator');
saveas(gcf,'results/MOD2_FF_unscaled_spectrum.png');

%%% [MOD] Report unscaled swings to size the b1, b2 coefficients
maxw1_orig = max(abs(w1));
maxw2_orig = max(abs(w2));
fprintf('\n[Unscaled FF] max|w1| = %.3f V, max|w2| = %.3f V\n', maxw1_orig, maxw2_orig);

%%% [MOD] === Scaling to keep |w1|, |w2| < 0.2 V at A = 0.7 V ===============
%%% [MOD] Slide 22: c* = c*b2 keeps H(z) = b1*b2*H_orig(z), so a 1-bit Q
%%% [MOD] preserves NTF and STF after scaling.
target = 0.2;
b1_s = target / maxw1_orig;
b2_s = target / (b1_s * maxw2_orig);
c1_s = c1 * b2_s;            % rescale FF path so loop transfer is unchanged
c2_s = c2;
fprintf('[Scaled FF]   b1* = %.4f, b2* = %.4f, c1* = %.4f, c2* = %g\n', ...
        b1_s, b2_s, c1_s, c2_s);

%%% [MOD] Re-simulate with scaled coefficients
y_s  = zeros(1,N); y_s(1) = 1;
w1_s = zeros(1,N); w2_s = zeros(1,N); w12_s = zeros(1,N);
for a = 2:N
    w2_s(a)  = w2_s(a-1)  + b2_s*w1_s(a-1);
    w1_s(a)  = w1_s(a-1)  + b1_s*(in(a-1) - y_s(a-1));
    w12_s(a) = c1_s*w1_s(a) + c2_s*w2_s(a);
    y_s(a)   = 2*(w12_s(a)>=0)-1;
end
fprintf('[Scaled FF]   max|w1| = %.3f V, max|w2| = %.3f V\n', ...
        max(abs(w1_s)), max(abs(w2_s)));

figure(3);
subplot(3,1,1); plot(w1_s,'k','LineWidth',1.0);
xlabel('Samples'); ylabel('w1 [V]'); grid on; ylim([-0.3 0.3]);
subplot(3,1,2); plot(w2_s,'k','LineWidth',1.0);
xlabel('Samples'); ylabel('w2 [V]'); grid on; ylim([-0.3 0.3]);
subplot(3,1,3); plot(y_s,'k','LineWidth',1.0);
xlabel('Samples'); ylabel('y'); grid on;
sgtitle(sprintf('Scaled FF MOD2 -- max|w1|=%.3f, max|w2|=%.3f', ...
                max(abs(w1_s)), max(abs(w2_s))));
saveas(gcf,'results/MOD2_FF_scaled_time.png');

ffty_s = abs(fft(y_s' .* kaiser(length(y_s),20)));
ffty_s = 20*log10(ffty_s/max(ffty_s)/sqrt(2));

figure(4);
semilogx((1:N/2)*fres, ffty(1:N/2),  'r', 'LineWidth', 1.0); hold on;
semilogx((1:N/2)*fres, ffty_s(1:N/2),'b', 'LineWidth', 1.0); hold off;
grid on; xlabel('Frequency'); ylabel('Amplitude [dB]');
legend('unscaled','scaled', 'Location','southeast');
title('FF MOD2: spectrum unscaled vs scaled (STF + NTF check)');
saveas(gcf,'results/MOD2_FF_spectrum_compare.png');

%%% [MOD] === Delay-less 2nd accumulator =================================
%%% [MOD] Delay-less means w2 sees w1 of the CURRENT sample. To keep the
%%% [MOD] loop stable the FF gain c* must be reduced (here halved is fine).
y_dl  = zeros(1,N); y_dl(1) = 1;
w1_dl = zeros(1,N); w2_dl = zeros(1,N); w12_dl = zeros(1,N);
c1_dl = c1_s/2;     % rescale c* for delay-less 2nd integrator
for a = 2:N
    w1_dl(a)  = w1_dl(a-1) + b1_s*(in(a-1) - y_dl(a-1));
    w2_dl(a)  = w2_dl(a-1) + b2_s*w1_dl(a);          % delay-less: uses w1_dl(a)
    w12_dl(a) = c1_dl*w1_dl(a) + c2_s*w2_dl(a);
    y_dl(a)   = 2*(w12_dl(a)>=0)-1;
end
fprintf('[Delay-less FF, c1*/2]  max|w1| = %.3f V, max|w2| = %.3f V\n', ...
        max(abs(w1_dl)), max(abs(w2_dl)));

ffty_dl = abs(fft(y_dl' .* kaiser(length(y_dl),20)));
ffty_dl = 20*log10(ffty_dl/max(ffty_dl)/sqrt(2));

figure(5);
semilogx((1:N/2)*fres, ffty_s(1:N/2), 'b', 'LineWidth', 1.0); hold on;
semilogx((1:N/2)*fres, ffty_dl(1:N/2),'g', 'LineWidth', 1.0); hold off;
grid on; xlabel('Frequency'); ylabel('Amplitude [dB]');
legend('delayed 2nd acc','delay-less 2nd acc','Location','southeast');
title('FF MOD2: delayed vs delay-less 2nd accumulator');
saveas(gcf,'results/MOD2_FF_delayless.png');
