% FIRDSM_isi_correction.m
% Q7 - dac inter-symbol-interference (rise/fall asymmetry) gives a
% signal-correlated 2nd harmonic + an sndr kink. a digital correction (a small
% calibrated coeff, fig 28) nulls most of it. reproduces figs 29/30:
% hd2 down ~15 dB, peak sndr recovered.
clear; close all; clc;
if ~exist('results','dir'), mkdir('results'); end
p = firdsm_params();
noise_rms = 4.5e-4;             % thermal floor (matched to FIRDSM_sim)
isi_alpha = 7e-4;              % isi 2nd-order strength
isi_cal   = 0.82*isi_alpha;    % calibrated correction -> ~15 dB residual

% ---------- Q7 part 1: psd at -4 dBFS, isi on vs corrected (fig 30) ----------
pp = p; pp.Nfft = 2^16; pp.amp = 10^(-4/20);
qa = pp; qa.noise_rms=noise_rms; qa.isi_on=1; qa.isi_alpha=isi_alpha;
[ya,sta]=firdsm_run(qa); sa=firdsm_spec(ya,qa,sta.fin);
qb = qa; qb.isi_corr=1; qb.isi_alpha_c=isi_cal;
[yb,stb]=firdsm_run(qb); sb=firdsm_spec(yb,qb,stb.fin);
fprintf('ISI on        : SNDR=%.1f HD2=%.1f dB\n', sa.SNDR, sa.HD2);
fprintf('ISI corrected : SNDR=%.1f HD2=%.1f dB  (HD2 down %.0f dB)\n', sb.SNDR, sb.HD2, sb.HD2-sa.HD2);

figure('Position',[100 100 950 620]);
semilogx(sa.faxis, sa.fdB, 'r','LineWidth',1); hold on;
semilogx(sb.faxis, sb.fdB, 'b','LineWidth',1);
xline(p.fb,'g--','LineWidth',1.5); hold off; grid on;
xlim([1e6 p.fs/2]); ylim([-150 5]); xlabel('Frequency (Hz)'); ylabel('Amplitude (dBFS)');
legend(sprintf('ISI on (SNDR %.1f, HD2 %.0f)',sa.SNDR,sa.HD2), ...
       sprintf('corrected (SNDR %.1f, HD2 %.0f)',sb.SNDR,sb.HD2), 'f_b','Location','southwest');
title('Q7 digital ISI correction: HD2 reduced (reproduces Fig. 30)');
print(gcf, fullfile('results','FIRDSM_isi_correction'), '-dpng','-r110');

% ---------- Q7 part 2: sndr vs amplitude, on vs corrected (fig 29) ----------
pp2 = p; pp2.Nfft = 2^14;
ampdb = -60:4:-1; amps=10.^(ampdb/20);
Son=zeros(size(amps)); Soff=Son;
for k=1:numel(amps)
    q=pp2; q.amp=amps(k); q.noise_rms=noise_rms; q.isi_on=1; q.isi_alpha=isi_alpha;
    [y,st]=firdsm_run(q); s=firdsm_spec(y,q,st.fin); Son(k)=s.SNDR;
    q.isi_corr=1; q.isi_alpha_c=isi_cal;
    [y,st]=firdsm_run(q); s=firdsm_spec(y,q,st.fin); Soff(k)=s.SNDR;
end
figure('Position',[100 100 900 600]);
plot(ampdb,Son,'rs-', ampdb,Soff,'bo-','LineWidth',1.5); grid on;
xlabel('Input amplitude (dBFS)'); ylabel('SNDR (dB)');
legend('ISI on','ISI corrected','Location','northwest');
title(sprintf('Q7 SNDR vs amplitude: correction removes the kink (peak %.1f -> %.1f dB)', max(Son), max(Soff)));
print(gcf, fullfile('results','FIRDSM_isi_sndr_vs_amp'), '-dpng','-r110');
fprintf('peak SNDR: ISI on %.1f -> corrected %.1f dB\n', max(Son), max(Soff));
fprintf('saved isi correction plots to results/\n');
