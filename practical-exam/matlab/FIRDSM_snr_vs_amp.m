% FIRDSM_snr_vs_amp.m
% Q2.6I - snr and sndr vs input amplitude (reproduces fig 21). thermal noise
% sets the low-amplitude floor (-> dynamic range), isi makes sndr fall below
% snr at large amplitude (the hd2 / isi kink). peak snr/sndr and dr reported.
clear; close all; clc;
if ~exist('results','dir'), mkdir('results'); end

p = firdsm_params();
p.Nfft = 2^15;
noise_rms = 4.5e-4;             % thermal floor (same budget as FIRDSM_sim)
isi_alpha = 7e-4;              % dac isi -> hd2 ~ signal^2

ampdb = -85:4:-1;               % input amplitude sweep (dbfs)
amps  = 10.^(ampdb/20);
SNR = zeros(size(amps)); SNDR = SNR;
for k = 1:numel(amps)
    q = p; q.amp = amps(k); q.noise_rms = noise_rms; q.isi_on = 1; q.isi_alpha = isi_alpha;
    [y,st] = firdsm_run(q);
    if st.unstable, SNR(k)=NaN; SNDR(k)=NaN; continue; end
    s = firdsm_spec(y, q, st.fin);
    SNR(k) = s.SNR; SNDR(k) = s.SNDR;
end

[pkSNR,iS]  = max(SNR);
[pkSNDR,iD] = max(SNDR);
% dynamic range: extrapolate the thermal-limited snr to where it crosses 0 db
lowmask = ampdb < -40 & isfinite(SNR);
DR = mean(ampdb(lowmask) - SNR(lowmask)) * -1;   % snr(dbfs) ~ amp - (-DR) -> DR = amp-SNR
fprintf('peak SNR  = %.1f dB @ %.0f dBFS  (paper 76.4)\n', pkSNR, ampdb(iS));
fprintf('peak SNDR = %.1f dB @ %.0f dBFS  (paper 70.9)\n', pkSNDR, ampdb(iD));
fprintf('dynamic range ~ %.0f dB  (paper 83)\n', DR);

figure('Position',[100 100 900 600]);
plot(ampdb, SNR, 'bo-', 'LineWidth',1.5); hold on;
plot(ampdb, SNDR, 'rs-', 'LineWidth',1.5);
plot([-DR 0], [0 DR], 'k:', 'LineWidth',1);
hold off; grid on;
xlabel('Input amplitude (dBFS)'); ylabel('SNR / SNDR (dB)');
legend('SNR', 'SNDR', 'DR slope', 'Location','northwest');
title(sprintf('SNR/SNDR vs amplitude  (peak SNR %.1f, SNDR %.1f, DR ~%.0f dB)', pkSNR, pkSNDR, DR));
print(gcf, fullfile('results','FIRDSM_snr_vs_amp'), '-dpng','-r110');
fprintf('saved snr-vs-amp plot to results/\n');
