clear
close all;
clc;
format long;

%%% [MOD] === Exercise 2: FIR filtering of the bitstream ====================
%%% [MOD] We sweep (a) filter length, (b) input offset, and report the
%%% [MOD] quantization error  q_err = filtered_avg - true_offset  per filter.

%%% [MOD] (a) First: a single representative run with a fixed offset and
%%% [MOD]     window_size, exactly matching the original script structure,
%%% [MOD]     plus an added quantization-error line.

% Input signal definition
nr_points = 4096;                 %%% [MOD] longer run -> more bits to filter
offset    = 34.6e-3
in        = offset*(ones(1,nr_points));

% Pre-allocates and initializes array variables
w=zeros(1,nr_points);
y=zeros(1,nr_points);
w(1)=0.5;
y(1)=1;

% The main loop simulating the accumulator and the quantizer
%************************************************************************
for a = 2:nr_points
    w(a) = w(a-1) + in(a-1) - y(a-1);
    y(a) = sign(w(a));
end
%************************************************************************

% Displays the output values
%************************************************************************
    figure(1);
    subplot(2,1,1); plot(w,'k','LineWidth',1);
    xlabel('Samples'); ylabel('W (Accumulator)'); grid;
    subplot(2,1,2); plot(y,'k','LineWidth',1);
    xlabel('Samples'); ylabel('Y (Bitstream)'); grid;
%************************************************************************

% Filter definitions
%************************************************************************
% The length of the filter
window_size = nr_points

% Rectangular filter
rect_filt = ones(1,window_size)';
% Triangular filter
tr_filt = window(@triang,window_size);
% Blackman filter
bl_filt = window(@blackman,window_size);
% Hann filter
han_filt = window(@hann,window_size);
% Kaiser filter
kai_filt = window(@kaiser,window_size,20);

% Plot the time-domain value of the filters
%************************************************************************
figure(2);
subplot(5,1,1);plot(rect_filt,'k');ylabel('rect');
subplot(5,1,2);plot(tr_filt,'k');ylabel('tr');
subplot(5,1,3);plot(bl_filt,'k');ylabel('bl');
subplot(5,1,4);plot(han_filt,'k');ylabel('han');
subplot(5,1,5);plot(kai_filt,'k');ylabel('kai');

% Applying the filter to the modulator output
%************************************************************************
y_rect_filt = y'.*rect_filt;
y_tr_filt   = y'.*tr_filt;
y_bl_filt   = y'.*bl_filt;
y_han_filt  = y'.*han_filt;
y_kai_filt  = y'.*kai_filt;

% Plot the time-domain filtered signal
%************************************************************************
figure(3);
subplot(5,1,1);plot(y_rect_filt,'k');ylabel('Y-rect');
subplot(5,1,2);plot(y_tr_filt,'k');ylabel('Y-tr');
subplot(5,1,3);plot(y_bl_filt,'k');ylabel('Y-bl');
subplot(5,1,4);plot(y_han_filt,'k');ylabel('Y-han');
subplot(5,1,5);plot(y_kai_filt,'k');ylabel('Y-kai');

% Calculate the average value after filtering
disp('The average value of the input signal after filtering:');
disp('------------------------------------------------------');
disp('Rectangular filter:');
y_avg_rect = sum(y_rect_filt)/sum(rect_filt)
disp('Triangular (Sinc^2) filter:');
y_avg_tr   = sum(y_tr_filt)/sum(tr_filt)
disp('Blackman filter:');
y_avg_bl   = sum(y_bl_filt)/sum(bl_filt)
disp('Hann filter:');
y_avg_han  = sum(y_han_filt)/sum(han_filt)
disp('Kaiser filter:');
y_avg_kai  = sum(y_kai_filt)/sum(kai_filt)

%%% [MOD] Quantization error per filter (filtered_avg - true_offset)
disp('---- Quantization error (filtered_avg - true_offset) ----');
qerr_rect = y_avg_rect - offset
qerr_tr   = y_avg_tr   - offset
qerr_bl   = y_avg_bl   - offset
qerr_han  = y_avg_han  - offset
qerr_kai  = y_avg_kai  - offset

%%% [MOD] === (b) Sweep filter length: how does q_err scale with N? =========
fprintf('\n[Filter-length sweep, offset = %g V]\n', offset);
fprintf('  N        rect          tr           bl           han          kai\n');
fprintf(' -----   ----------   ----------   ----------   ----------   ----------\n');
N_list = [16 64 256 1024 4096];
for N = N_list
    if N > nr_points,  continue,  end
    yN = y(1:N);
    rf = ones(1,N)';
    tf = window(@triang,N);
    bf = window(@blackman,N);
    hf = window(@hann,N);
    kf = window(@kaiser,N,20);
    e_rect = sum(yN'.*rf)/sum(rf) - offset;
    e_tr   = sum(yN'.*tf)/sum(tf) - offset;
    e_bl   = sum(yN'.*bf)/sum(bf) - offset;
    e_han  = sum(yN'.*hf)/sum(hf) - offset;
    e_kai  = sum(yN'.*kf)/sum(kf) - offset;
    fprintf(' %5d   %+9.6f    %+9.6f    %+9.6f    %+9.6f    %+9.6f\n', ...
            N, e_rect, e_tr, e_bl, e_han, e_kai);
end

%%% [MOD] === (c) Sweep DC offset over [-1, 1] V ============================
%%% [MOD] For each offset, simulate fresh and compute q_err for each filter
fprintf('\n[Input-offset sweep,  N = %d]\n', nr_points);
fprintf('  offset      rect         tr          bl          han         kai\n');
fprintf(' --------   ----------   ----------   ----------   ----------   ----------\n');
off_list = -0.9:0.1:0.9;
N        = nr_points;
rf = ones(1,N)';
tf = window(@triang,N);
bf = window(@blackman,N);
hf = window(@hann,N);
kf = window(@kaiser,N,20);
err_table = zeros(length(off_list),5);
for k = 1:length(off_list)
    off_k = off_list(k);
    in_k  = off_k*ones(1,N);
    wk = zeros(1,N);  yk = zeros(1,N);  wk(1)=0; yk(1)=1;
    for a = 2:N
        wk(a) = wk(a-1) + in_k(a-1) - yk(a-1);
        yk(a) = sign(wk(a));
    end
    e_rect = sum(yk'.*rf)/sum(rf) - off_k;
    e_tr   = sum(yk'.*tf)/sum(tf) - off_k;
    e_bl   = sum(yk'.*bf)/sum(bf) - off_k;
    e_han  = sum(yk'.*hf)/sum(hf) - off_k;
    e_kai  = sum(yk'.*kf)/sum(kf) - off_k;
    err_table(k,:) = [e_rect e_tr e_bl e_han e_kai];
    fprintf(' %+6.2f    %+9.6f    %+9.6f    %+9.6f    %+9.6f    %+9.6f\n', ...
            off_k, e_rect, e_tr, e_bl, e_han, e_kai);
end

figure(4);
plot(off_list, err_table, 'LineWidth',1.2); grid on;
xlabel('Input offset [V]'); ylabel('Quantization error [V]');
legend('rect','triang','blackman','hann','kaiser(20)');
title(sprintf('Quantization error vs input offset (N = %d)', N));
saveas(gcf,'results/MOD1_filt_errVsOffset.png');
