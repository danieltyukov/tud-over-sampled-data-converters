% verify_A2.m  (test-only, NOT part of the submission)
% Mirrors every section of HW2.m and saves a PNG per figure into results/.
% Run after HW2.m to confirm the three designs reproduce the expected
% OSR / noise / scaling numbers from the header comments. ASCII-only.

mkdir('results');

% Common settings (match HW2.m)
fin        = 1.003;
fb         = 20;
offset     = 0.00;
nr_periods = 300;

%% ---- Question A: 2nd-order FEED-FORWARD ----
SNR_vals = []; amp_vals = 0.1:0.05:1;
for amplitude = amp_vals
    fs = 10000;
    nr_points = round(nr_periods*fs/fin);
    fres = fs/nr_points;
    maintone = round(fin/fres);
    signal_bins = maintone-7:maintone+7;
    inband_bins = round(0.02/fres):round(20/fres);
    noise_bins = setdiff(inband_bins,signal_bins);
    in = offset + amplitude*sin(2*pi*(1:nr_points)/(fs/fin));
    y = zeros(1,nr_points+1); w1 = y; w2 = y; w12 = y; y(1) = 1;
    b1 = 1; b2 = 1; c1 = 2; c2 = 1;
    for a = 2:nr_points+1
        w2(a)  = w2(a-1) + b2*w1(a-1);
        w1(a)  = w1(a-1) + b1*(in(a-1) - y(a-1));
        w12(a) = c1*w1(a) + c2*w2(a);
        y(a)   = 2*(w12(a)>=0)-1;
    end
    ffty = abs(fft(y(2:nr_points+1)'.*kaiser(length(y)-1,20)));
    SNR_vals(end+1) = 10*log10(sum(ffty(signal_bins).^2)/sum(ffty(noise_bins).^2));
end
[~, idx] = max(SNR_vals); QA_amp = amp_vals(idx); QA_peakSNR = SNR_vals(idx);

f = figure('Position',[100 100 900 500]);
plot(amp_vals, SNR_vals, '-o','LineWidth',1.5); grid on;
xlabel('Input amplitude'); ylabel('SQNR (dB)');
title(sprintf('Q A FF: SQNR vs amplitude (best A=%.2f, peak=%.2f dB)', QA_amp, QA_peakSNR));
saveas(f, 'results/A2_QA_snr_vs_amp.png'); close(f);

% Find min OSR for SQNR > 100 (use partner's start fs=10000)
amplitude = QA_amp;
for fs = 7000:100:13000
    nr_points = round(nr_periods*fs/fin);
    fres = fs/nr_points;
    maintone = round(fin/fres);
    signal_bins = maintone-7:maintone+7;
    inband_bins = round(0.02/fres):round(20/fres);
    noise_bins = setdiff(inband_bins,signal_bins);
    in = offset + amplitude*sin(2*pi*(1:nr_points)/(fs/fin));
    y = zeros(1,nr_points+1); w1 = y; w2 = y; w12 = y; y(1) = 1;
    b1 = 1; b2 = 1; c1 = 2; c2 = 1;
    for a = 2:nr_points+1
        w2(a)  = w2(a-1) + b2*w1(a-1);
        w1(a)  = w1(a-1) + b1*(in(a-1) - y(a-1));
        w12(a) = c1*w1(a) + c2*w2(a);
        y(a)   = 2*(w12(a)>=0)-1;
    end
    ffty = abs(fft(y(2:nr_points+1)'.*kaiser(length(y)-1,20)));
    SNR = 10*log10(sum(ffty(signal_bins).^2)/sum(ffty(noise_bins).^2));
    if SNR > 100, break; end
end
QA_fs = fs; QA_OSR = fs/(2*fb); QA_SQNR = SNR;

% Noise sweep with scaling (target 0.48 V)
for noise_rms_1 = 5e-6:5e-6:500e-6
    y = zeros(1,nr_points+1); w1 = y; w2 = y; w12 = y; y(1) = 1;
    b1 = 1; b2 = 1; c1 = 2; c2 = 1;
    for a = 2:nr_points+1
        w2(a)  = w2(a-1) + b2*w1(a-1);
        w1(a)  = w1(a-1) + b1*(in(a-1) - y(a-1)) + noise_rms_1*randn;
        w12(a) = c1*w1(a) + c2*w2(a);
        y(a)   = 2*(w12(a)>=0)-1;
    end
    k1 = 0.48/max(abs(w1)); k2 = 0.48/max(abs(w2));
    b1 = b1*k1; b2 = b2*k2/k1; c1 = 2*b2; c2 = 1;
    for a = 2:nr_points+1
        w2(a)  = w2(a-1) + b2*w1(a-1);
        w1(a)  = w1(a-1) + b1*(in(a-1) - y(a-1)) + noise_rms_1*randn;
        w12(a) = c1*w1(a) + c2*w2(a);
        y(a)   = 2*(w12(a)>=0)-1;
    end
    ffty = abs(fft(y(2:nr_points+1)'.*kaiser(length(y)-1,20)));
    SNR = 10*log10(sum(ffty(signal_bins).^2)/sum(ffty(noise_bins).^2));
    if SNR <= 90, break; end
end
QA_noise = noise_rms_1; QA_SNR = SNR;
QA_b1 = b1; QA_b2 = b2; QA_c1 = c1;
QA_w1max = max(abs(w1)); QA_w2max = max(abs(w2));
ffty_dB = 20*log10(abs(ffty)/max(abs(ffty)));

f = figure('Position',[100 100 900 700]);
subplot(3,1,1); plot(w1,'k','LineWidth',1.0); grid on;
xlabel('Samples'); ylabel('w1 [V]'); ylim([-0.6 0.6]);
title(sprintf('Q A FF time domain (scaled, noise=%.0f uV)', QA_noise*1e6));
subplot(3,1,2); plot(w2,'k','LineWidth',1.0); grid on;
xlabel('Samples'); ylabel('w2 [V]'); ylim([-0.6 0.6]);
subplot(3,1,3); plot(y,'k','LineWidth',1.0); grid on;
xlabel('Samples'); ylabel('y');
saveas(f, 'results/A2_QA_time.png'); close(f);

f = figure('Position',[100 100 900 500]);
semilogx((1:nr_points/2)*fres*1e3, ffty_dB(1:floor(nr_points/2))); hold on;
plot(inband_bins*fres*1e3, ffty_dB(inband_bins),'g','LineWidth',3);
plot(signal_bins*fres*1e3, ffty_dB(signal_bins),'r','LineWidth',3);
hold off; grid on;
xlabel('Frequency [Hz]'); ylabel('Magnitude [dB]');
title(sprintf('Q A FF spectrum (OSR=%.0f, SNR=%.1f dB at %.0f uV)', QA_OSR, QA_SNR, QA_noise*1e6));
legend('Full spectrum','Inband bins','Main tone','Location','northwest');
saveas(f, 'results/A2_QA_spectrum.png'); close(f);

%% ---- Question B: 2nd-order FEEDBACK ----
clearvars -except fin fb offset nr_periods QA_*
SNR_vals = []; amp_vals = 0.1:0.05:1;
for amplitude = amp_vals
    fs = 10000;
    nr_points = round(nr_periods*fs/fin);
    fres = fs/nr_points;
    maintone = round(fin/fres);
    signal_bins = maintone-7:maintone+7;
    inband_bins = round(0.02/fres):round(20/fres);
    noise_bins = setdiff(inband_bins,signal_bins);
    in = offset + amplitude*sin(2*pi*(1:nr_points)/(fs/fin));
    y = zeros(1,nr_points+1); w1 = y; w2 = y; y(1) = 1;
    b1 = 1; b2 = 1; a1 = 1; a2 = 2;
    for a = 2:nr_points+1
        w2(a) = w2(a-1) + b2*(w1(a-1)-a2*y(a-1));
        y(a) = 2*(w2(a)>=0)-1;
        w1(a) = w1(a-1) + b1*(in(a-1)-a1*y(a-1));
    end
    ffty = abs(fft(y(2:nr_points+1)'.*kaiser(length(y)-1,20)));
    SNR_vals(end+1) = 10*log10(sum(ffty(signal_bins).^2)/sum(ffty(noise_bins).^2));
end
[~, idx] = max(SNR_vals); QB_amp = amp_vals(idx); QB_peakSNR = SNR_vals(idx);

f = figure('Position',[100 100 900 500]);
plot(amp_vals, SNR_vals, '-o','LineWidth',1.5); grid on;
xlabel('Input amplitude'); ylabel('SQNR (dB)');
title(sprintf('Q B FB: SQNR vs amplitude (best A=%.2f, peak=%.2f dB)', QB_amp, QB_peakSNR));
saveas(f, 'results/A2_QB_snr_vs_amp.png'); close(f);

amplitude = QB_amp;
for fs = 7000:100:13000
    nr_points = round(nr_periods*fs/fin);
    fres = fs/nr_points;
    maintone = round(fin/fres);
    signal_bins = maintone-7:maintone+7;
    inband_bins = round(0.02/fres):round(20/fres);
    noise_bins = setdiff(inband_bins,signal_bins);
    in = offset + amplitude*sin(2*pi*(1:nr_points)/(fs/fin));
    y = zeros(1,nr_points+1); w1 = y; w2 = y; y(1) = 1;
    b1 = 1; b2 = 1; a1 = 1; a2 = 2;
    for a = 2:nr_points+1
        w2(a) = w2(a-1) + b2*(w1(a-1)-a2*y(a-1));
        y(a) = 2*(w2(a)>=0)-1;
        w1(a) = w1(a-1) + b1*(in(a-1)-a1*y(a-1));
    end
    ffty = abs(fft(y(2:nr_points+1)'.*kaiser(length(y)-1,20)));
    SNR = 10*log10(sum(ffty(signal_bins).^2)/sum(ffty(noise_bins).^2));
    if SNR > 100, break; end
end
QB_fs = fs; QB_OSR = fs/(2*fb); QB_SQNR = SNR;

for noise_rms_1 = 5e-6:5e-6:500e-6
    y = zeros(1,nr_points+1); w1 = y; w2 = y; y(1) = 1;
    b1 = 1; b2 = 1; a1 = 1; a2 = 2;
    for a = 2:nr_points+1
        w2(a) = w2(a-1) + b2*(w1(a-1)-a2*y(a-1));
        y(a) = 2*(w2(a)>=0)-1;
        w1(a) = w1(a-1) + b1*(in(a-1)-a1*y(a-1)) + noise_rms_1*randn;
    end
    k1 = 0.48/max(abs(w1)); k2 = 0.48/max(abs(w2));
    b1 = b1*k1; b2 = b2*k2/k1; a1 = 1; a2 = 2*b1;
    for a = 2:nr_points+1
        w2(a) = w2(a-1) + b2*(w1(a-1)-a2*y(a-1));
        y(a) = 2*(w2(a)>=0)-1;
        w1(a) = w1(a-1) + b1*(in(a-1)-a1*y(a-1)) + noise_rms_1*randn;
    end
    ffty = abs(fft(y(2:nr_points+1)'.*kaiser(length(y)-1,20)));
    SNR = 10*log10(sum(ffty(signal_bins).^2)/sum(ffty(noise_bins).^2));
    if SNR <= 90, break; end
end
QB_noise = noise_rms_1; QB_SNR = SNR;
QB_b1 = b1; QB_b2 = b2; QB_a2 = a2;
QB_w1max = max(abs(w1)); QB_w2max = max(abs(w2));
ffty_dB = 20*log10(abs(ffty)/max(abs(ffty)));

f = figure('Position',[100 100 900 700]);
subplot(3,1,1); plot(w1,'k','LineWidth',1.0); grid on;
xlabel('Samples'); ylabel('w1 [V]'); ylim([-0.6 0.6]);
title(sprintf('Q B FB time domain (scaled, noise=%.0f uV)', QB_noise*1e6));
subplot(3,1,2); plot(w2,'k','LineWidth',1.0); grid on;
xlabel('Samples'); ylabel('w2 [V]'); ylim([-0.6 0.6]);
subplot(3,1,3); plot(y,'k','LineWidth',1.0); grid on;
xlabel('Samples'); ylabel('y');
saveas(f, 'results/A2_QB_time.png'); close(f);

f = figure('Position',[100 100 900 500]);
semilogx((1:nr_points/2)*fres*1e3, ffty_dB(1:floor(nr_points/2))); hold on;
plot(inband_bins*fres*1e3, ffty_dB(inband_bins),'g','LineWidth',3);
plot(signal_bins*fres*1e3, ffty_dB(signal_bins),'r','LineWidth',3);
hold off; grid on;
xlabel('Frequency [Hz]'); ylabel('Magnitude [dB]');
title(sprintf('Q B FB spectrum (OSR=%.0f, SNR=%.1f dB at %.0f uV)', QB_OSR, QB_SNR, QB_noise*1e6));
legend('Full spectrum','Inband bins','Main tone','Location','northwest');
saveas(f, 'results/A2_QB_spectrum.png'); close(f);

%% ---- Question C: 2nd-order FB with notch (local feedback) ----
clearvars -except fin fb offset nr_periods QA_* QB_*
SNR_vals = []; amp_vals = 0.1:0.05:1;
for amplitude = amp_vals
    fs = 10000;
    nr_points = round(nr_periods*fs/fin);
    fres = fs/nr_points;
    maintone = round(fin/fres);
    signal_bins = maintone-7:maintone+7;
    inband_bins = round(0.02/fres):round(20/fres);
    noise_bins = setdiff(inband_bins,signal_bins);
    in = offset + amplitude*sin(2*pi*(1:nr_points)/(fs/fin));
    y = zeros(1,nr_points+1); w1 = y; w2 = y; y(1) = 1;
    b1 = 1; b2 = 1; a1 = 1; a2 = 2;
    for a = 2:nr_points+1
        w2(a) = w2(a-1) + b2*(w1(a-1)-a2*y(a-1));
        y(a) = 2*(w2(a)>=0)-1;
        w1(a) = w1(a-1) + b1*(in(a-1)-a1*y(a-1));
    end
    ffty = abs(fft(y(2:nr_points+1)'.*kaiser(length(y)-1,20)));
    SNR_vals(end+1) = 10*log10(sum(ffty(signal_bins).^2)/sum(ffty(noise_bins).^2));
end
[~, idx] = max(SNR_vals); QC_amp = amp_vals(idx); QC_peakSNR = SNR_vals(idx);

f = figure('Position',[100 100 900 500]);
plot(amp_vals, SNR_vals, '-o','LineWidth',1.5); grid on;
xlabel('Input amplitude'); ylabel('SQNR (dB)');
title(sprintf('Q C local-FB: SQNR vs amplitude (best A=%.2f, peak=%.2f dB)', QC_amp, QC_peakSNR));
saveas(f, 'results/A2_QC_snr_vs_amp.png'); close(f);

% OSR sweep with notch optimisation (Schreier rule)
amplitude = QC_amp; f_notch = fb/sqrt(3);
for fs = 5000:100:11000
    nr_points = round(nr_periods*fs/fin);
    fres = fs/nr_points;
    maintone = round(fin/fres);
    signal_bins = maintone-7:maintone+7;
    inband_bins = round(0.02/fres):round(20/fres);
    noise_bins = setdiff(inband_bins,signal_bins);
    in = offset + amplitude*sin(2*pi*(1:nr_points)/(fs/fin));
    d_theory = (2*pi*f_notch/fs)^2;
    d_grid = d_theory*linspace(0.5,1.8,8);
    best_SNR = -Inf; best_d = d_theory;
    for d = d_grid
        y = zeros(1,nr_points+1); w1 = y; w2 = y; y(1) = 1;
        b1 = 1; b2 = 1; a1 = 1; a2 = 2;
        for a = 2:nr_points+1
            w2(a) = w2(a-1) + b2*(w1(a-1)-a2*y(a-1));
            y(a) = 2*(w2(a)>=0)-1;
            w1(a) = w1(a-1) + b1*(in(a-1)-a1*y(a-1)-d*w2(a-1));
        end
        ffty = abs(fft(y(2:nr_points+1)'.*kaiser(length(y)-1,20)));
        S = 10*log10(sum(ffty(signal_bins).^2)/sum(ffty(noise_bins).^2));
        if S > best_SNR, best_SNR = S; best_d = d; end
    end
    SNR = best_SNR; d = best_d;
    if SNR > 100, break; end
end
QC_fs = fs; QC_OSR = fs/(2*fb); QC_SQNR = SNR; QC_d_unscaled = d;

for noise_rms_1 = 5e-6:5e-6:500e-6
    y = zeros(1,nr_points+1); w1 = y; w2 = y; y(1) = 1;
    b1 = 1; b2 = 1; a1 = 1; a2 = 2; d = QC_d_unscaled;
    for a = 2:nr_points+1
        w2(a) = w2(a-1) + b2*(w1(a-1)-a2*y(a-1));
        y(a) = 2*(w2(a)>=0)-1;
        w1(a) = w1(a-1) + b1*(in(a-1)-a1*y(a-1)-d*w2(a-1)) + noise_rms_1*randn;
    end
    k1 = 0.48/max(abs(w1)); k2 = 0.48/max(abs(w2));
    b1 = b1*k1; b2 = b2*k2/k1; a1 = 1; a2 = 2*b1; d = d/b1/b2;
    for a = 2:nr_points+1
        w2(a) = w2(a-1) + b2*(w1(a-1)-a2*y(a-1));
        y(a) = 2*(w2(a)>=0)-1;
        w1(a) = w1(a-1) + b1*(in(a-1)-a1*y(a-1)-d*w2(a-1)) + noise_rms_1*randn;
    end
    ffty = abs(fft(y(2:nr_points+1)'.*kaiser(length(y)-1,20)));
    SNR = 10*log10(sum(ffty(signal_bins).^2)/sum(ffty(noise_bins).^2));
    if SNR <= 90, break; end
end
QC_noise = noise_rms_1; QC_SNR = SNR;
QC_b1 = b1; QC_b2 = b2; QC_a2 = a2; QC_d_scaled = d;
QC_w1max = max(abs(w1)); QC_w2max = max(abs(w2));
ffty_dB = 20*log10(abs(ffty)/max(abs(ffty)));

f = figure('Position',[100 100 900 700]);
subplot(3,1,1); plot(w1,'k','LineWidth',1.0); grid on;
xlabel('Samples'); ylabel('w1 [V]'); ylim([-0.6 0.6]);
title(sprintf('Q C local-FB time domain (scaled, noise=%.0f uV)', QC_noise*1e6));
subplot(3,1,2); plot(w2,'k','LineWidth',1.0); grid on;
xlabel('Samples'); ylabel('w2 [V]'); ylim([-0.6 0.6]);
subplot(3,1,3); plot(y,'k','LineWidth',1.0); grid on;
xlabel('Samples'); ylabel('y');
saveas(f, 'results/A2_QC_time.png'); close(f);

f = figure('Position',[100 100 900 500]);
semilogx((1:nr_points/2)*fres*1e3, ffty_dB(1:floor(nr_points/2))); hold on;
plot(inband_bins*fres*1e3, ffty_dB(inband_bins),'g','LineWidth',3);
plot(signal_bins*fres*1e3, ffty_dB(signal_bins),'r','LineWidth',3);
xline(f_notch*1e3,'--m','f_notch=fb/sqrt(3)');
hold off; grid on;
xlabel('Frequency [Hz]'); ylabel('Magnitude [dB]');
title(sprintf('Q C local-FB spectrum (OSR=%.0f, SNR=%.1f dB, d_{unsc}=%.2e)', ...
       QC_OSR, QC_SNR, QC_d_unscaled));
legend('Full spectrum','Inband bins','Main tone','Location','northwest');
saveas(f, 'results/A2_QC_spectrum.png'); close(f);

%% ---- Summary ----
fprintf('\n=== Verification summary ===\n');
fprintf('Q A FF       : A=%.2f  OSR=%5.1f  SQNR=%6.2f dB  noise=%5.1f uV  |w1|=%.3f  |w2|=%.3f  -> %s\n', ...
        QA_amp, QA_OSR, QA_SQNR, QA_noise*1e6, QA_w1max, QA_w2max, okstr(QA_OSR<=250 && QA_w1max<0.5 && QA_w2max<0.5));
fprintf('Q B FB       : A=%.2f  OSR=%5.1f  SQNR=%6.2f dB  noise=%5.1f uV  |w1|=%.3f  |w2|=%.3f  -> %s\n', ...
        QB_amp, QB_OSR, QB_SQNR, QB_noise*1e6, QB_w1max, QB_w2max, okstr(QB_OSR<=250 && QB_w1max<0.5 && QB_w2max<0.5));
fprintf('Q C local-FB : A=%.2f  OSR=%5.1f  SQNR=%6.2f dB  noise=%5.1f uV  |w1|=%.3f  |w2|=%.3f  d_unsc=%.2e  -> %s\n', ...
        QC_amp, QC_OSR, QC_SQNR, QC_noise*1e6, QC_w1max, QC_w2max, QC_d_unscaled, ...
        okstr(QC_OSR<QA_OSR && QC_w1max<0.5 && QC_w2max<0.5));
fprintf('\nFigures saved to results/.\n');

function s = okstr(b)
    if b, s = 'OK'; else, s = 'CHECK'; end
end
