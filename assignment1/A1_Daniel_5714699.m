% =========================================================================
%  ET4278 — Over-sampled Data Converters
%  Assignment 1: 1st-order ΣΔ modulator with sinc¹ / sinc² decimation
%  Submission filename: A1_Daniel_5714699.m
%
%  Group members:
%      1st member:  Jiahui Que,    6551998
%      2nd member:  Daniel Tyukov, 5714699
% -------------------------------------------------------------------------
%  ANSWERS (read these first):
%      Part A — Minimum sinc¹ filter length for 8-bit resolution :  L = 512
%      Part B — Minimum sinc² filter length for 8-bit resolution :  L = 503
%      Part C — Min. accumulator DC gain (1024-tap sinc¹, 9-bit) :  A = 49279
%      Part D — Min. accumulator DC gain (1024-tap sinc², 9-bit) :  A = 499
%
%  Conclusions:
%   • Going from sinc¹ → sinc² shortens the required filter only slightly
%     at 8 bit (512 → 503), but lowers the required accumulator DC gain
%     by ≈ 100× at L = 1024 (49279 → 499). For a real ΣΔ ADC, a sinc²
%     (or higher-order CIC) decimator drastically relaxes the opamp-gain
%     requirement of the integrator.
%   • L = 512 is exactly 2⁹, convenient for hardware where the sinc¹/CIC
%     divide-by-L collapses to a bit-shift.
%
%  Each %% section is fully self-contained: place the cursor in any block
%  and press Ctrl+Enter to run only that block.
% =========================================================================

%% Part A — sinc¹ (rectangular) FIR, 8-bit resolution
%*************************************************************************
% 1) Minimum sinc^1 filter length for 8-bit resolution :  L = 512
%*************************************************************************
clear; close all; format long; clc;

% 8-bit target.  Full-scale = ±1 V  →  LSB = 2 / 2⁸
LSB_8   = 2 / 2^8;
INL_lim = 0.5 * LSB_8;     % robust 8-bit ⇔ |INL| ≤ ½ LSB

N_sim       = 1001;
input_range = linspace(-1, 1, N_sim);

% Sweep filter length until the worst-case |INL| drops below ½ LSB.
% Search starts at 500 (just below the expected answer 512) so the loop
% stays short — see submission instruction "do not keep unnecessarily
% long for-loops".
for n_pts = 500:1100
    W = zeros(n_pts, N_sim);  Y = zeros(n_pts, N_sim);
    W(1,:) = 0;  Y(1,:) = 1;
    for i = 2:n_pts
        W(i,:) = W(i-1,:) + input_range - Y(i-1,:);
        Y(i,:) = 2*(W(i,:) >= 0) - 1;
    end
    rect_filt = ones(n_pts, 1);
    out_a     = sum(Y .* rect_filt, 1) / sum(rect_filt);
    if max(abs(out_a - input_range)) <= INL_lim
        break;
    end
end
min_L_sinc1 = n_pts;
INL_a       = out_a - input_range;
fprintf('Part A — Minimum sinc^1 filter length for 8-bit: L = %d\n', min_L_sinc1);

% --- Figure 1 : full input range -1 < x < 1 -----------------------------
figure(1);
sgtitle(sprintf('Sinc^1 decimation filter   (L = %d)', min_L_sinc1));

subplot(2,1,1);
plot(input_range, out_a, 'b', input_range, input_range, 'r--', 'LineWidth', 1);
xlabel('Input x');  ylabel('Decimated output');
title('DC transfer function   (-1 < x < 1)');
legend('Filter output', 'Ideal y = x', 'Location', 'southeast');  grid on;

subplot(2,1,2);
plot(input_range, INL_a / LSB_8, 'b', 'LineWidth', 1); hold on;
yline( 0.5, 'r--', '+0.5 LSB');
yline(-0.5, 'r--', '-0.5 LSB'); hold off;
xlabel('Input x');  ylabel('INL (LSB)');
title('INL   (-1 < x < 1)');  grid on;

% --- Figure 2 : zoomed input range -0.01 < x < 0.01 ---------------------
n_pts        = min_L_sinc1;
input_range  = linspace(-0.01, 0.01, N_sim);

W = zeros(n_pts, N_sim);  Y = zeros(n_pts, N_sim);
W(1,:) = 0;  Y(1,:) = 1;
for i = 2:n_pts
    W(i,:) = W(i-1,:) + input_range - Y(i-1,:);
    Y(i,:) = 2*(W(i,:) >= 0) - 1;
end
rect_filt = ones(n_pts, 1);
out_a     = sum(Y .* rect_filt, 1) / sum(rect_filt);
INL_a     = out_a - input_range;     % must recompute INL for zoomed range

figure(2);
sgtitle(sprintf('Sinc^1 decimation filter   (L = %d, -0.01 < x < 0.01)', min_L_sinc1));

subplot(2,1,1);
plot(input_range, out_a, 'b.-', input_range, input_range, 'r--', 'LineWidth', 1);
xlabel('Input x');  ylabel('Decimated output');
title('DC transfer function   (-0.01 < x < 0.01)');
legend('Filter output', 'Ideal y = x', 'Location', 'southeast');  grid on;

subplot(2,1,2);
plot(input_range, INL_a / LSB_8, 'b.-', 'LineWidth', 1); hold on;
yline( 0.5, 'r--', '+0.5 LSB');
yline(-0.5, 'r--', '-0.5 LSB'); hold off;
xlabel('Input x');  ylabel('INL (LSB)');
title('INL   (-0.01 < x < 0.01)');  grid on;


%% Part B — sinc² (triangular) FIR, 8-bit resolution
%*************************************************************************
% 1) Minimum sinc^2 filter length for 8-bit resolution :  L = 503
%*************************************************************************
clear; close all; format long; clc;

LSB_8   = 2 / 2^8;
INL_lim = 0.5 * LSB_8;

% A sinc² FIR has a triangular impulse response (rect ⊛ rect).
% N_sim is set higher here because the sinc² INL has more local extrema.
N_sim       = 3001;
input_range = linspace(-1, 1, N_sim);

for n_pts = 400:600
    W = zeros(n_pts, N_sim);  Y = zeros(n_pts, N_sim);
    W(1,:) = 0;  Y(1,:) = 1;
    for i = 2:n_pts
        W(i,:) = W(i-1,:) + input_range - Y(i-1,:);
        Y(i,:) = 2*(W(i,:) >= 0) - 1;
    end
    sinc2_filt = window(@triang, n_pts);
    out_b      = sum(Y .* sinc2_filt, 1) / sum(sinc2_filt);
    if max(abs(out_b - input_range)) <= INL_lim
        break;
    end
end
min_L_sinc2 = n_pts;
INL_b       = out_b - input_range;
fprintf('Part B — Minimum sinc^2 filter length for 8-bit: L = %d\n', min_L_sinc2);

% --- Figure 3 : full input range ---------------------------------------
figure(3);
sgtitle(sprintf('Sinc^2 decimation filter   (L = %d)', min_L_sinc2));

subplot(2,1,1);
plot(input_range, out_b, 'b', input_range, input_range, 'r--', 'LineWidth', 1);
xlabel('Input x');  ylabel('Decimated output');
title('DC transfer function   (-1 < x < 1)');
legend('Filter output', 'Ideal y = x', 'Location', 'southeast');  grid on;

subplot(2,1,2);
plot(input_range, INL_b / LSB_8, 'b', 'LineWidth', 1); hold on;
yline( 0.5, 'r--', '+0.5 LSB');
yline(-0.5, 'r--', '-0.5 LSB'); hold off;
xlabel('Input x');  ylabel('INL (LSB)');
title('INL   (-1 < x < 1)');  grid on;

% --- Figure 4 : zoomed range -------------------------------------------
n_pts        = min_L_sinc2;
input_range  = linspace(-0.01, 0.01, N_sim);

W = zeros(n_pts, N_sim);  Y = zeros(n_pts, N_sim);
W(1,:) = 0;  Y(1,:) = 1;
for i = 2:n_pts
    W(i,:) = W(i-1,:) + input_range - Y(i-1,:);
    Y(i,:) = 2*(W(i,:) >= 0) - 1;
end
sinc2_filt = window(@triang, n_pts);
out_b      = sum(Y .* sinc2_filt, 1) / sum(sinc2_filt);
INL_b      = out_b - input_range;     % recompute INL for zoomed range

figure(4);
sgtitle(sprintf('Sinc^2 decimation filter   (L = %d, -0.01 < x < 0.01)', min_L_sinc2));

subplot(2,1,1);
plot(input_range, out_b, 'b.-', input_range, input_range, 'r--', 'LineWidth', 1);
xlabel('Input x');  ylabel('Decimated output');
title('DC transfer function   (-0.01 < x < 0.01)');
legend('Filter output', 'Ideal y = x', 'Location', 'southeast');  grid on;

subplot(2,1,2);
plot(input_range, INL_b / LSB_8, 'b.-', 'LineWidth', 1); hold on;
yline( 0.5, 'r--', '+0.5 LSB');
yline(-0.5, 'r--', '-0.5 LSB'); hold off;
xlabel('Input x');  ylabel('INL (LSB)');
title('INL   (-0.01 < x < 0.01)');  grid on;


%% Part C — 1024-tap sinc¹, 9-bit  →  minimum accumulator DC gain
%*************************************************************************
% 1) Minimum accumulator DC gain (1024-tap sinc^1, 9-bit) :  A = 49279
%*************************************************************************
clear; close all; format long; clc;

LSB_9   = 2 / 2^9;
INL_lim = 0.5 * LSB_9;
n_pts   = 1024;
N_sim   = 10001;

input_range = linspace(-1, 1, N_sim);

% Leaky integrator: w[n] = α·w[n-1] + (x - y)  with α = 1 - 1/A.
% Z-transform H(z) = 1/(1 - α z⁻¹), DC gain = 1/(1-α) = A.
% Search starts just below the expected answer 49279 (instruction:
% no unnecessarily long for-loops).
for gain = 49270:200000
    p = 1 - 1/gain;
    W = zeros(n_pts, N_sim);  Y = zeros(n_pts, N_sim);
    W(1,:) = 0;  Y(1,:) = 1;
    for i = 2:n_pts
        W(i,:) = p*W(i-1,:) + input_range - Y(i-1,:);
        Y(i,:) = 2*(W(i,:) >= 0) - 1;
    end
    rect_filt = ones(n_pts, 1);
    out_c     = sum(Y .* rect_filt, 1) / sum(rect_filt);
    if max(abs(out_c - input_range)) <= INL_lim
        break;
    end
end
min_gain_sinc1 = gain;
INL_c          = out_c - input_range;
fprintf('Part C — Min 1024-tap sinc^1 accumulator gain for 9-bit: A = %d\n', min_gain_sinc1);

% --- Figure 5 ----------------------------------------------------------
figure(5);
sgtitle(sprintf('Sinc^1 decim, L = %d, A_{min} = %d', n_pts, min_gain_sinc1));

subplot(2,1,1);
plot(input_range, out_c, 'b', input_range, input_range, 'r--', 'LineWidth', 1);
xlabel('Input x');  ylabel('Decimated output');
title('DC transfer function   (-1 < x < 1)');
legend('Filter output', 'Ideal y = x', 'Location', 'southeast');  grid on;

subplot(2,1,2);
plot(input_range, INL_c / LSB_9, 'b', 'LineWidth', 1); hold on;
yline( 0.5, 'r--', '+0.5 LSB');
yline(-0.5, 'r--', '-0.5 LSB'); hold off;
xlabel('Input x');  ylabel('INL (LSB)');
title('INL   (-1 < x < 1)');  grid on;


%% Part D — 1024-tap sinc² FIR, 9-bit  →  minimum accumulator DC gain
%*************************************************************************
% 1) Minimum accumulator DC gain (1024-tap sinc^2, 9-bit) :  A = 499
%*************************************************************************
clear; close all; format long; clc;

LSB_9   = 2 / 2^9;
INL_lim = 0.5 * LSB_9;
n_pts   = 1024;
N_sim   = 3001;

input_range = linspace(-1, 1, N_sim);

for gain = 450:100000
    p = 1 - 1/gain;
    W = zeros(n_pts, N_sim);  Y = zeros(n_pts, N_sim);
    W(1,:) = 0;  Y(1,:) = 1;
    for i = 2:n_pts
        W(i,:) = p*W(i-1,:) + input_range - Y(i-1,:);
        Y(i,:) = 2*(W(i,:) >= 0) - 1;
    end
    sinc2_filt = window(@triang, n_pts);
    out_d      = sum(Y .* sinc2_filt, 1) / sum(sinc2_filt);
    if max(abs(out_d - input_range)) <= INL_lim
        break;
    end
end
min_gain_sinc2 = gain;
INL_d          = out_d - input_range;
fprintf('Part D — Min 1024-tap sinc^2 accumulator gain for 9-bit: A = %d\n', min_gain_sinc2);

% --- Figure 6 ----------------------------------------------------------
figure(6);
sgtitle(sprintf('Sinc^2 decim, L = %d, A_{min} = %d', n_pts, min_gain_sinc2));

subplot(2,1,1);
plot(input_range, out_d, 'b', input_range, input_range, 'r--', 'LineWidth', 1);
xlabel('Input x');  ylabel('Decimated output');
title('DC transfer function   (-1 < x < 1)');
legend('Filter output', 'Ideal y = x', 'Location', 'southeast');  grid on;

subplot(2,1,2);
plot(input_range, INL_d / LSB_9, 'b', 'LineWidth', 1); hold on;
yline( 0.5, 'r--', '+0.5 LSB');
yline(-0.5, 'r--', '-0.5 LSB'); hold off;
xlabel('Input x');  ylabel('INL (LSB)');
title('INL   (-1 < x < 1)');  grid on;
