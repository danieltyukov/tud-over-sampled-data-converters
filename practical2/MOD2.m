clear all
close all;

%%% [MOD] === Exercise 2.1: 2nd-order modulator, time-domain simulation ====
%%% [MOD] Difference equations (delay-free 1st accumulator):
%%% [MOD]   w2(i) = w2(i-1) + w1(i-1) - a*y(i-1)
%%% [MOD]   y(i)  = sign(w2(i))
%%% [MOD]   w1(i) = w1(i-1) + x(i-1) - y(i)

%Input signal definition
% This is the DC offset applied to the input of the modulator
offset = 0;

nr_points = 1000;

in = offset*(ones(1,nr_points));

% Pre-allocate and initialize array variables => faster code
% w2 is the second accumulator's output
% w1 is the first accumulator's output
% a is the stabilizing zero coefficient

a = 1;

w1 = zeros(1,nr_points);
w2 = zeros(1,nr_points);
y = zeros(1,nr_points);
y(1) = 1;
w1(1) = 0;
w2(1) = 0;

% The main loop simulating the second order loop
%************************************************************************

for i = 2:nr_points,
    w2(i) = w2(i-1) + w1(i-1) - a*y(i-1);
    y(i) = sign(w2(i));
    %y(i) = 2*(w2(i)>=0)-1;
    w1(i) = w1(i-1) + in(i-1) - y(i);
end

%************************************************************************

% Display the output values
%************************************************************************

figure(1);
subplot(3,1,1);plot(w1,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('w1 (1st Accumulator)');grid;
subplot(3,1,2);plot(w2,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('w2 (2nd Accumulator)');grid;
subplot(3,1,3);plot(y,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('y (Bitstream)');grid;
sgtitle(sprintf('Baseline run: x = %g, a = %g, N = %d', offset, a, nr_points));

%%% [MOD] === Part (b): DC offsets 50 mV and 34.6 mV, sinc1 vs sinc2 ======
%%% [MOD] sinc1 = rectangular window, sinc2 = triangular window.
%%% [MOD] Q-error = filtered_avg - true_offset.
off_list = [50e-3, 34.6e-3];
fprintf('\n[Offset sweep, N = %d, a = %g]\n', nr_points, a);
fprintf('  offset[V]    avg(y)        Q-err(sinc1)     Q-err(sinc2)\n');
fprintf(' ----------  -----------   --------------   --------------\n');
for k = 1:length(off_list)
    off_k = off_list(k);
    [w1k, w2k, yk] = mod2_sim(off_k, a, nr_points);
    rect_filt = ones(1,nr_points)';
    tri_filt  = window(@triang,nr_points);
    y_avg     = sum(yk)/nr_points;
    y_rect    = sum(yk'.*rect_filt)/sum(rect_filt);
    y_tri     = sum(yk'.*tri_filt) /sum(tri_filt);
    qerr_rect = y_rect - off_k;
    qerr_tri  = y_tri  - off_k;
    fprintf(' %+8.4f    %+9.6f   %+12.6f    %+12.6f\n', ...
            off_k, y_avg, qerr_rect, qerr_tri);

    figure(1+k);
    subplot(3,1,1);plot(w1k,'k','LineWidth',1.2);
    xlabel('Samples');ylabel('w1');grid;
    sgtitle(sprintf('x = %g V, a = %g, N = %d', off_k, a, nr_points));
    subplot(3,1,2);plot(w2k,'k','LineWidth',1.2);
    xlabel('Samples');ylabel('w2');grid;
    subplot(3,1,3);plot(yk,'k','LineWidth',1.2);
    xlabel('Samples');ylabel('y');grid;
end

%%% [MOD] === Part (c): nr_points 100 vs 1000, Q-error scaling ============
%%% [MOD] Linear model: in-band noise ~ 1/OSR^5 (2nd order shaping).
%%% [MOD] So q_rms ~ OSR^(-5/2). 10x in N -> ~316x drop ideally
%%% [MOD] (sinc2 matches shaping much better than sinc1).
fprintf('\n[Length sweep at offset = 34.6 mV, a = %g]\n', a);
fprintf('   N        Q-err(sinc1)     Q-err(sinc2)\n');
fprintf(' ------   --------------   --------------\n');
N_list = [100 1000];
qerr_rect_N = zeros(size(N_list));
qerr_tri_N  = zeros(size(N_list));
for k = 1:length(N_list)
    Nk = N_list(k);
    [~, ~, ykN] = mod2_sim(34.6e-3, a, Nk);
    rfk = ones(1,Nk)';
    tfk = window(@triang,Nk);
    qerr_rect_N(k) = sum(ykN'.*rfk)/sum(rfk) - 34.6e-3;
    qerr_tri_N(k)  = sum(ykN'.*tfk)/sum(tfk) - 34.6e-3;
    fprintf(' %5d    %+12.6f    %+12.6f\n', Nk, qerr_rect_N(k), qerr_tri_N(k));
end
fprintf('Ratio |q(N=100)/q(N=1000)|, sinc1 = %.2f, sinc2 = %.2f\n', ...
        abs(qerr_rect_N(1)/qerr_rect_N(2)), ...
        abs(qerr_tri_N(1) /qerr_tri_N(2)));

%%% [MOD] === Part (d): sweep stabilizing coefficient a at x = 34.6 mV ====
%%% [MOD] Smaller a -> larger w1, w2 swings; a = 0 -> unstable (w2 runs away).
fprintf('\n[a-sweep at offset = 34.6 mV, N = %d]\n', nr_points);
fprintf('    a       max|w1|     max|w2|     Q-err(sinc1)   Q-err(sinc2)\n');
fprintf(' -------   --------    --------   --------------  --------------\n');
a_list = [1.5, 1.0, 0.5, 0.25, 0.1, 0.0];
fig_id = 1 + length(off_list);
for k = 1:length(a_list)
    ak = a_list(k);
    [w1a, w2a, ya] = mod2_sim(34.6e-3, ak, nr_points);
    rfk = ones(1,nr_points)';
    tfk = window(@triang,nr_points);
    e_rect = sum(ya'.*rfk)/sum(rfk) - 34.6e-3;
    e_tri  = sum(ya'.*tfk)/sum(tfk) - 34.6e-3;
    fprintf(' %6.2f    %8.2f    %8.2f   %+12.6f   %+12.6f\n', ...
            ak, max(abs(w1a)), max(abs(w2a)), e_rect, e_tri);
    if any(abs(ak - [1.0 0.5 0.1 0.0]) < 1e-9)
        fig_id = fig_id + 1;
        figure(fig_id);
        subplot(3,1,1);plot(w1a,'k','LineWidth',1.0);
        xlabel('Samples');ylabel('w1');grid;
        sgtitle(sprintf('a = %g, x = 34.6 mV', ak));
        subplot(3,1,2);plot(w2a,'k','LineWidth',1.0);
        xlabel('Samples');ylabel('w2');grid;
        subplot(3,1,3);plot(ya,'k','LineWidth',1.0);
        xlabel('Samples');ylabel('y');grid;
    end
end

%%% [MOD] Helper: simulate MOD2 with delay-free 1st accumulator
function [w1, w2, y] = mod2_sim(offset, a, N)
    in = offset*ones(1,N);
    w1 = zeros(1,N);
    w2 = zeros(1,N);
    y  = zeros(1,N);
    y(1) = 1;
    for i = 2:N
        w2(i) = w2(i-1) + w1(i-1) - a*y(i-1);
        y(i)  = sign(w2(i));
        if y(i) == 0, y(i) = 1; end
        w1(i) = w1(i-1) + in(i-1) - y(i);
    end
end
