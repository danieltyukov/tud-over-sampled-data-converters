% Assignment 1 - 1st-order modulator with sinc / sinc^2 decimation
% Made by:
%   Jiahui Que,       6551998
%   Daniel Tyukov,    5714699
%
% Filename: A1_Daniel_Jiahui_5714699.m

% Question A  -  Minimum sinc1 filter length for 8-bit: L = 512
%
% Question B  -  Minimum sinc2 filter length for 8-bit: L = 503
%
% Question C  -  Minimum gain with 1024-tap sinc1 for 9-bit: gain = 49279
%
% Question D  -  Minimum gain with 1024-tap sinc2 for 9-bit: gain = 499

% From the minimum filter lengths and gain required, it can be noticed that
% the minimum filter length only decreases slightly when using a sinc2
% filter, whereas the accumulator gain decreases significantly when using a
% sinc2 filter. Thus the sinc2 filter is much better compared to the sinc
% filter. Furthermore it can be noticed that the length required for
% Question A is a exactly a power of two.

%% Question A
%************************************************************************
% 1) Minimum sinc1 filter length for 8-bit: L = 512
%************************************************************************
clear
close all;
format long;
clc;

% 8-bit resolution target
LSB_8   = 2 / 2^8;      % LSB for 8-bit and full-scale range = 2 (from -1 to 1)
INL_lim = 0.5 * LSB_8;  % Max allowed |INL| = 0.5 LSB

% Loop over filter lengths until 8-bit INL is achieved
% Simulation length = filter length = npts
for n_pts = 500:1100          % simulation length = filter length
    N_sim = 1001;           % number of DC input values to sweep
    input_range = linspace(-1, 1, N_sim);
     
    % W and Y are (n_pts x N_sim): each column = one DC input, each row = one time step
    W = zeros(n_pts, N_sim);
    Y = zeros(n_pts, N_sim);
    W(1,:) = 0;
    Y(1,:) = 1;                       
    
    for i = 2:n_pts
        W(i,:) = W(i-1,:) + input_range - Y(i-1,:);  % input_range constant per column
        Y(i,:) = 2*(W(i,:) >= 0) - 1;
    end
    
    rect_filt = ones(1,n_pts)';                          
    out_a     = sum(Y .* rect_filt, 1) / sum(rect_filt); 

    if max(abs(out_a - input_range)) <= INL_lim
        break;
    end
end


min_L_sinc1 = n_pts;   % filter length at which 8-bit INL was first satisfied

fprintf('Question A  -  Minimum sinc1 filter length for 8-bit: L = %d\n', min_L_sinc1);
fprintf('           (8-bit INL limit = %.5f = 0.5 LSB)\n\n', INL_lim);

% out_a already holds the filter output for the minimum L; compute INL
INL_a = out_a - input_range;

% --- Figure 1: Full range  -1 < x < 1 ---
figure(1);
sgtitle(sprintf('Sinc decimation filter  (L = %d)', min_L_sinc1));

subplot(2,1,1);
plot(input_range, out_a, 'b', input_range, input_range, 'r--', 'LineWidth', 1);
xlabel('Input x');  ylabel('Decimated output');
title('DC Transfer Function   (-1 < x < 1)');
legend('Filter output', 'Ideal (y = x)');
grid on;

subplot(2,1,2);
plot(input_range, INL_a / LSB_8, 'b', 'LineWidth', 1);
hold on;
yline( 0.5, 'r--', '+0.5 LSB');
yline(-0.5, 'r--', '-0.5 LSB');
hold off;
xlabel('Input x');  ylabel('INL (LSB)');
title('INL   (-1 < x < 1)');
grid on;

% --- Figure 2: Zoomed range  -0.01 < x < 0.01 ---
n_pts = min_L_sinc1;
N_sim = 1001;           % number of DC input values to sweep
input_range = linspace(-0.01, 0.01, N_sim);  % (1 x N_sim)

% W and Y are (n_pts x N_sim): each column = one DC input, each row = one time step
W = zeros(n_pts, N_sim);
Y = zeros(n_pts, N_sim);
W(1,:) = 0;
Y(1,:) = 1;                         % Initial quantiser output: Q(0) = +1

for i = 2:n_pts
    W(i,:) = W(i-1,:) + input_range - Y(i-1,:);  % input_range constant per column
    Y(i,:) = 2*(W(i,:) >= 0) - 1;
end

% Apply sinc1 (rectangular) filter: sum(y .* h) / sum(h), summing over rows
rect_filt = ones(n_pts, 1);                          % (n_pts x 1) column vector
out_a     = sum(Y .* rect_filt, 1) / sum(rect_filt); % (1 x N_sim) filter output
INL_a     = out_a - input_range;                     % recompute INL for the zoomed range

figure(2);
sgtitle(sprintf('Sinc decimation filter  (L = %d,  -0.01 < x < 0.01)', min_L_sinc1));

subplot(2,1,1);
plot(input_range, out_a, 'b.-', input_range, input_range, 'r--', 'LineWidth', 1);
xlabel('Input x');  ylabel('Decimated output');
title('DC Transfer Function   (-0.01 < x < 0.01)');
legend('Filter output', 'Ideal (y = x)');
grid on;

subplot(2,1,2);
plot(input_range, INL_a / LSB_8, 'b.-', 'LineWidth', 1);
hold on;
yline( 0.5, 'r--', '+0.5 LSB');
yline(-0.5, 'r--', '-0.5 LSB');
hold off;
xlabel('Input x');  ylabel('INL (LSB)');
title('INL   (-0.01 < x < 0.01)');
grid on;

%% Question B
%************************************************************************
% 1) Minimum sinc2 filter length for 8-bit: L = 503
%************************************************************************
clear
close all;
format long;
clc;

% 8-bit resolution target
LSB_8   = 2 / 2^8;      % LSB for 8-bit and full-scale range = 2 (from -1 to 1)
INL_lim = 0.5 * LSB_8;  % Max allowed |INL| = 0.5 LSB

for n_pts = 400:600          % simulation length = filter length
    N_sim = 3001;           % number of DC input values to sweep
    input_range = linspace(-1, 1, N_sim);
    
    W = zeros(n_pts, N_sim);
    Y = zeros(n_pts, N_sim);
    W(1,:) = 0;
    Y(1,:) = 1;                       
    
    for i = 2:n_pts
        W(i,:) = W(i-1,:) + input_range - Y(i-1,:);  
        Y(i,:) = 2*(W(i,:) >= 0) - 1;
    end
    
    sinc2_filt = window(@triang,n_pts);                          
    out_b     = sum(Y .* sinc2_filt, 1) / sum(sinc2_filt); 

    if max(abs(out_b - input_range)) <= INL_lim
        break;
    end
end


min_L_sinc2 = n_pts;   % filter length at which 8-bit INL was first satisfied

fprintf('Question B  -  Minimum sinc2 filter length for 8-bit: L = %d\n', min_L_sinc2);
fprintf('           (8-bit INL limit = %.5f = 0.5 LSB)\n\n', INL_lim);

INL_b = out_b - input_range;

% --- Figure 3: Full range  -1 < x < 1 ---
figure(3);
sgtitle(sprintf('Sinc^2 decimation filter  (L = %d)', min_L_sinc2));

subplot(2,1,1);
plot(input_range, out_b, 'b', input_range, input_range, 'r--', 'LineWidth', 1);
xlabel('Input x');  ylabel('Decimated output');
title('DC Transfer Function   (-1 < x < 1)');
% legend('Filter output', 'Ideal (y = x)');
grid on;

subplot(2,1,2);
plot(input_range, INL_b / LSB_8, 'b', 'LineWidth', 1);
hold on;
yline( 0.5, 'r--', '+0.5 LSB');
yline(-0.5, 'r--', '-0.5 LSB');
hold off;
xlabel('Input x');  ylabel('INL (LSB)');
title('INL   (-1 < x < 1)');
grid on;

% --- Figure 4: Zoomed range  -0.01 < x < 0.01 ---
n_pts = min_L_sinc2;
N_sim = 3001;           % number of DC input values to sweep
input_range = linspace(-0.01, 0.01, N_sim);
    
W = zeros(n_pts, N_sim);
Y = zeros(n_pts, N_sim);
W(1,:) = 0;
Y(1,:) = 1;                         % Initial quantiser output: Q(0) = +1

for i = 2:n_pts
    W(i,:) = W(i-1,:) + input_range - Y(i-1,:);  % input_range constant per column
    Y(i,:) = 2*(W(i,:) >= 0) - 1;
end

sinc2_filt = window(@triang,n_pts);
out_b     = sum(Y .* sinc2_filt, 1) / sum(sinc2_filt);
INL_b     = out_b - input_range;     % recompute INL for the zoomed range

figure(4);
sgtitle(sprintf('Sinc^2 decimation filter  (L = %d,  -0.01 < x < 0.01)', min_L_sinc2));

subplot(2,1,1);
plot(input_range, out_b, 'b.-', input_range, input_range, 'r--', 'LineWidth', 1);
xlabel('Input x');  ylabel('Decimated output');
title('DC Transfer Function   (-0.01 < x < 0.01)');
legend('Filter output', 'Ideal (y = x)');
grid on;

subplot(2,1,2);
plot(input_range, INL_b / LSB_8, 'b.-', 'LineWidth', 1);
hold on;
yline( 0.5, 'r--', '+0.5 LSB');
yline(-0.5, 'r--', '-0.5 LSB');
hold off;
xlabel('Input x');  ylabel('INL (LSB)');
title('INL   (-0.01 < x < 0.01)');
grid on;

%% Question C
%************************************************************************
% 1) Minimum gain with 1024-tap sinc1 for 9-bit: gain = 49279
%************************************************************************
clear
close all;
format long;
clc;

% 9-bit resolution target
LSB_9   = 2 / 2^9;      % LSB for 9-bit and full-scale range = 2 (from -1 to 1)
INL_lim = 0.5 * LSB_9;  % Max allowed |INL| = 0.5 LSB

for gain = 49270:1:200000
    p = 1 - 1/gain;            % Loss factor
    n_pts = 1024;           % simulation length = filter length
    N_sim = 10001;           % number of DC input values to sweep
    input_range = linspace(-1, 1, N_sim);
    
    W = zeros(n_pts, N_sim);
    Y = zeros(n_pts, N_sim);
    W(1,:) = 0;
    Y(1,:) = 1;                       
    
    for i = 2:n_pts
        W(i,:) = p*W(i-1,:) + input_range - Y(i-1,:);  % input_range constant per column
        Y(i,:) = 2*(W(i,:) >= 0) - 1;
    end
    
    rect_filt = ones(n_pts, 1);                          
    out_c     = sum(Y .* rect_filt, 1) / sum(rect_filt); 

    if max(abs(out_c - input_range)) <= INL_lim
        break;
    end
end


min_gain_sinc1 = gain;  

fprintf('Question C  -  Minimum gain with 1024-tap sinc1 for 9-bit: gain = %d\n', min_gain_sinc1);
fprintf('           (9-bit INL limit = %.5f = 0.5 LSB)\n\n', INL_lim);

% out_a already holds the filter output for the minimum L; compute INL
INL_c = out_c - input_range;

% --- Figure 5: Full range  -1 < x < 1 ---
figure(5);
sgtitle(sprintf('Sinc decimation filter  (A = %d)', min_gain_sinc1));

subplot(2,1,1);
plot(input_range, out_c, 'b', input_range, input_range, 'r--', 'LineWidth', 1);
xlabel('Input x');  ylabel('Decimated output');
title('DC Transfer Function   (-1 < x < 1)');
% legend('Filter output', 'Ideal (y = x)');
grid on;

subplot(2,1,2);
plot(input_range, INL_c / LSB_9, 'b', 'LineWidth', 1);
hold on;
yline( 0.5, 'r--', '+0.5 LSB');
yline(-0.5, 'r--', '-0.5 LSB');
hold off;
xlabel('Input x');  ylabel('INL (LSB)');
title('INL   (-1 < x < 1)');
grid on;

%% Question D
%************************************************************************
% 1) Minimum gain with 1024-tap sinc2 for 9-bit: gain = 499
%************************************************************************
clear
close all;
format long;
clc;

% 9-bit resolution target
LSB_9   = 2 / 2^9;      % LSB for 9-bit and full-scale range = 2 (from -1 to 1)
INL_lim = 0.5 * LSB_9;  % Max allowed |INL| = 0.5 LSB

for gain = 450:1:100000
    p = 1 - 1/gain;            % Loss factor
    n_pts = 1024;           % simulation length = filter length
    N_sim = 3001;           % number of DC input values to sweep
    input_range = linspace(-1, 1, N_sim);
    
    % W and Y are (n_pts x N_sim): each column = one DC input, each row = one time step
    W = zeros(n_pts, N_sim);
    Y = zeros(n_pts, N_sim);
    W(1,:) = 0;
    Y(1,:) = 1;                       
    
    for i = 2:n_pts
        W(i,:) = p*W(i-1,:) + input_range - Y(i-1,:);  % input_range constant per column
        Y(i,:) = 2*(W(i,:) >= 0) - 1;
    end
    
    sinc2_filt = window(@triang,n_pts);                          
    out_d     = sum(Y .* sinc2_filt, 1) / sum(sinc2_filt);

    if max(abs(out_d - input_range)) <= INL_lim
        break;
    end
end


min_gain_sinc2 = gain;   % accumulator gain at which 9-bit INL was first satisfied

fprintf('Question D  -  Minimum gain with 1024-tap sinc2 for 9-bit: gain = %d\n', min_gain_sinc2);
fprintf('           (9-bit INL limit = %.5f = 0.5 LSB)\n\n', INL_lim);

INL_d = out_d - input_range;

% --- Figure 6: Full range  -1 < x < 1 ---
figure(6);
sgtitle(sprintf('Sinc^2 decimation filter  (A = %d)', min_gain_sinc2));

subplot(2,1,1);
plot(input_range, out_d, 'b', input_range, input_range, 'r--', 'LineWidth', 1);
xlabel('Input x');  ylabel('Decimated output');
title('DC Transfer Function   (-1 < x < 1)');
% legend('Filter output', 'Ideal (y = x)');
grid on;

subplot(2,1,2);
plot(input_range, INL_d / LSB_9, 'b', 'LineWidth', 1);
hold on;
yline( 0.5, 'r--', '+0.5 LSB');
yline(-0.5, 'r--', '-0.5 LSB');
hold off;
xlabel('Input x');  ylabel('INL (LSB)');
title('INL   (-1 < x < 1)');
grid on;

