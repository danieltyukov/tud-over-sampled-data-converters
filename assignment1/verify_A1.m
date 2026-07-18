% verify_A1.m  (test-only, NOT part of the submission)
% Mirrors every section of A1_Daniel_Jiahui_5714699.m and saves a PNG
% per figure into results/. ASCII-only.
mkdir('results');

% ---- Part A full ----
LSB_8 = 2/2^8; INL_lim = 0.5*LSB_8;
N_sim = 1001; input_range = linspace(-1,1,N_sim);
for n_pts = 500:1100
    W = zeros(n_pts,N_sim); Y = zeros(n_pts,N_sim);
    W(1,:) = 0; Y(1,:) = 1;
    for i = 2:n_pts
        W(i,:) = W(i-1,:) + input_range - Y(i-1,:);
        Y(i,:) = 2*(W(i,:) >= 0) - 1;
    end
    rect_filt = ones(n_pts,1);
    out_a = sum(Y .* rect_filt, 1)/sum(rect_filt);
    if max(abs(out_a - input_range)) <= INL_lim, break; end
end
min_L_sinc1 = n_pts; INL_a = out_a - input_range;
f1 = figure('Position',[100 100 900 600]);
sgtitle(sprintf('Sinc1 decim L=%d', min_L_sinc1));
subplot(2,1,1);
plot(input_range, out_a, 'b', input_range, input_range, 'r--'); grid on;
xlabel('Input x'); ylabel('Decim. output'); title('DC TF (-1<x<1)');
legend('Filter output','Ideal y=x','Location','southeast');
subplot(2,1,2);
plot(input_range, INL_a/LSB_8, 'b'); hold on;
yline(0.5,'r--'); yline(-0.5,'r--'); hold off; grid on;
xlabel('Input x'); ylabel('INL (LSB)'); title('INL (-1<x<1)');
saveas(f1,'results/A1_partA_full.png');

% ---- Part A zoom ----
n_pts = min_L_sinc1; input_range = linspace(-0.01,0.01,N_sim);
W = zeros(n_pts,N_sim); Y = zeros(n_pts,N_sim);
W(1,:) = 0; Y(1,:) = 1;
for i = 2:n_pts
    W(i,:) = W(i-1,:) + input_range - Y(i-1,:);
    Y(i,:) = 2*(W(i,:) >= 0) - 1;
end
rect_filt = ones(n_pts,1);
out_a = sum(Y .* rect_filt, 1)/sum(rect_filt);
INL_a = out_a - input_range;
f2 = figure('Position',[100 100 900 600]);
sgtitle(sprintf('Sinc1 zoom L=%d, -0.01<x<0.01', min_L_sinc1));
subplot(2,1,1);
plot(input_range, out_a, 'b.-', input_range, input_range, 'r--'); grid on;
xlabel('Input x'); ylabel('Decim. output'); title('DC TF zoomed');
legend('Filter output','Ideal y=x','Location','southeast');
subplot(2,1,2);
plot(input_range, INL_a/LSB_8, 'b.-'); hold on;
yline(0.5,'r--'); yline(-0.5,'r--'); hold off; grid on;
xlabel('Input x'); ylabel('INL (LSB)'); title('INL zoomed');
saveas(f2,'results/A1_partA_zoom.png');

% ---- Part B full ----
LSB_8 = 2/2^8; INL_lim = 0.5*LSB_8;
N_sim = 3001; input_range = linspace(-1,1,N_sim);
for n_pts = 400:600
    W = zeros(n_pts,N_sim); Y = zeros(n_pts,N_sim);
    W(1,:) = 0; Y(1,:) = 1;
    for i = 2:n_pts
        W(i,:) = W(i-1,:) + input_range - Y(i-1,:);
        Y(i,:) = 2*(W(i,:) >= 0) - 1;
    end
    sinc2_filt = window(@triang, n_pts);
    out_b = sum(Y .* sinc2_filt, 1)/sum(sinc2_filt);
    if max(abs(out_b - input_range)) <= INL_lim, break; end
end
min_L_sinc2 = n_pts; INL_b = out_b - input_range;
f3 = figure('Position',[100 100 900 600]);
sgtitle(sprintf('Sinc2 decim L=%d', min_L_sinc2));
subplot(2,1,1);
plot(input_range, out_b, 'b', input_range, input_range, 'r--'); grid on;
xlabel('Input x'); ylabel('Decim. output'); title('DC TF (-1<x<1)');
legend('Filter output','Ideal y=x','Location','southeast');
subplot(2,1,2);
plot(input_range, INL_b/LSB_8, 'b'); hold on;
yline(0.5,'r--'); yline(-0.5,'r--'); hold off; grid on;
xlabel('Input x'); ylabel('INL (LSB)'); title('INL (-1<x<1)');
saveas(f3,'results/A1_partB_full.png');

% ---- Part B zoom ----
n_pts = min_L_sinc2; input_range = linspace(-0.01,0.01,N_sim);
W = zeros(n_pts,N_sim); Y = zeros(n_pts,N_sim);
W(1,:) = 0; Y(1,:) = 1;
for i = 2:n_pts
    W(i,:) = W(i-1,:) + input_range - Y(i-1,:);
    Y(i,:) = 2*(W(i,:) >= 0) - 1;
end
sinc2_filt = window(@triang, n_pts);
out_b = sum(Y .* sinc2_filt, 1)/sum(sinc2_filt);
INL_b = out_b - input_range;
f4 = figure('Position',[100 100 900 600]);
sgtitle(sprintf('Sinc2 zoom L=%d, -0.01<x<0.01', min_L_sinc2));
subplot(2,1,1);
plot(input_range, out_b, 'b.-', input_range, input_range, 'r--'); grid on;
xlabel('Input x'); ylabel('Decim. output'); title('DC TF zoomed');
legend('Filter output','Ideal y=x','Location','southeast');
subplot(2,1,2);
plot(input_range, INL_b/LSB_8, 'b.-'); hold on;
yline(0.5,'r--'); yline(-0.5,'r--'); hold off; grid on;
xlabel('Input x'); ylabel('INL (LSB)'); title('INL zoomed');
saveas(f4,'results/A1_partB_zoom.png');

% ---- Part C ----
LSB_9 = 2/2^9; INL_lim = 0.5*LSB_9;
n_pts = 1024; N_sim = 10001;
input_range = linspace(-1,1,N_sim);
for gain = 49270:200000
    p = 1 - 1/gain;
    W = zeros(n_pts,N_sim); Y = zeros(n_pts,N_sim);
    W(1,:) = 0; Y(1,:) = 1;
    for i = 2:n_pts
        W(i,:) = p*W(i-1,:) + input_range - Y(i-1,:);
        Y(i,:) = 2*(W(i,:) >= 0) - 1;
    end
    rect_filt = ones(n_pts,1);
    out_c = sum(Y .* rect_filt, 1)/sum(rect_filt);
    if max(abs(out_c - input_range)) <= INL_lim, break; end
end
min_gain_sinc1 = gain; INL_c = out_c - input_range;
f5 = figure('Position',[100 100 900 600]);
sgtitle(sprintf('Sinc1 decim L=%d, A_{min}=%d', n_pts, min_gain_sinc1));
subplot(2,1,1);
plot(input_range, out_c, 'b', input_range, input_range, 'r--'); grid on;
xlabel('Input x'); ylabel('Decim. output'); title('DC TF (-1<x<1)');
legend('Filter output','Ideal y=x','Location','southeast');
subplot(2,1,2);
plot(input_range, INL_c/LSB_9, 'b'); hold on;
yline(0.5,'r--'); yline(-0.5,'r--'); hold off; grid on;
xlabel('Input x'); ylabel('INL (LSB)'); title('INL (-1<x<1)');
saveas(f5,'results/A1_partC.png');

% ---- Part D ----
LSB_9 = 2/2^9; INL_lim = 0.5*LSB_9;
n_pts = 1024; N_sim = 3001;
input_range = linspace(-1,1,N_sim);
for gain = 450:100000
    p = 1 - 1/gain;
    W = zeros(n_pts,N_sim); Y = zeros(n_pts,N_sim);
    W(1,:) = 0; Y(1,:) = 1;
    for i = 2:n_pts
        W(i,:) = p*W(i-1,:) + input_range - Y(i-1,:);
        Y(i,:) = 2*(W(i,:) >= 0) - 1;
    end
    sinc2_filt = window(@triang, n_pts);
    out_d = sum(Y .* sinc2_filt, 1)/sum(sinc2_filt);
    if max(abs(out_d - input_range)) <= INL_lim, break; end
end
min_gain_sinc2 = gain; INL_d = out_d - input_range;
f6 = figure('Position',[100 100 900 600]);
sgtitle(sprintf('Sinc2 decim L=%d, A_{min}=%d', n_pts, min_gain_sinc2));
subplot(2,1,1);
plot(input_range, out_d, 'b', input_range, input_range, 'r--'); grid on;
xlabel('Input x'); ylabel('Decim. output'); title('DC TF (-1<x<1)');
legend('Filter output','Ideal y=x','Location','southeast');
subplot(2,1,2);
plot(input_range, INL_d/LSB_9, 'b'); hold on;
yline(0.5,'r--'); yline(-0.5,'r--'); hold off; grid on;
xlabel('Input x'); ylabel('INL (LSB)'); title('INL (-1<x<1)');
saveas(f6,'results/A1_partD.png');

fprintf('\n=== Verification summary ===\n');
fprintf('Part A: L=%d  (expect 512)   -> %s\n', min_L_sinc1,    okstr(min_L_sinc1==512));
fprintf('Part B: L=%d  (expect 503)   -> %s\n', min_L_sinc2,    okstr(min_L_sinc2==503));
fprintf('Part C: A=%d  (expect 49279) -> %s\n', min_gain_sinc1, okstr(min_gain_sinc1==49279));
fprintf('Part D: A=%d  (expect 499)   -> %s\n', min_gain_sinc2, okstr(min_gain_sinc2==499));

function s = okstr(b)
    if b, s = 'OK'; else, s = 'MISMATCH'; end
end
