% FIRDSM_metastability.m  Q2.6G: first-tap-zero removes metastability (fig 4, 52->91 dB)
clear; close all; clc;
if ~exist('results','dir'), mkdir('results'); end

p = firdsm_params(); p.Nfft = 2^16; p.amp = 0.5;
mtau = 0.06;                   % regen time constant (fraction of Ts)

q1 = p; q1.meta_on=1; q1.meta_tau=mtau; q1.first_tap_zero=0;   % metastable
[y1,st1] = firdsm_run(q1); s1 = firdsm_spec(y1,q1,st1.fin);
q2 = p; q2.meta_on=1; q2.meta_tau=mtau; q2.first_tap_zero=1;   % first tap = 0
[y2,st2] = firdsm_run(q2); s2 = firdsm_spec(y2,q2,st2.fin);

fprintf('metastability, no delay      : SNDR=%.1f dB\n', s1.SNDR);
fprintf('first-tap-zero (1-clk delay) : SNDR=%.1f dB  (recovery %.0f dB)\n', s2.SNDR, s2.SNDR-s1.SNDR);
fprintf('paper fig 4: ~52 -> ~91 dB\n');

figure('Position',[100 100 950 620]);
plot(s1.faxis/1e6, s1.fdB, 'r', 'LineWidth',1); hold on;       % linear x like fig 4
plot(s2.faxis/1e6, s2.fdB, 'b', 'LineWidth',1);
xline(p.fb/1e6,'g--','LineWidth',1.5); hold off; grid on;
xlim([1 60]); ylim([-130 5]); xlabel('Frequency (MHz)'); ylabel('Amplitude (dBFS)');
legend(sprintf('metastable, f_1\\neq0 (SNDR %.0f dB)',s1.SNDR), ...
       sprintf('first tap zero (SNDR %.0f dB)',s2.SNDR), 'f_b', 'Location','southwest');
title('Comparator metastability: effect of zeroing the first FIR tap (reproduces Fig. 4)');
print(gcf, fullfile('results','FIRDSM_metastability'), '-dpng','-r110');
fprintf('saved metastability plot to results/\n');
