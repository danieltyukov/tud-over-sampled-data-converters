% FIRDSM_techniques_onoff.m
% Q2.1 - enable/disable the proposed techniques and quantify each.
% fir dac on/off (under jitter), compensation on/off (off -> unstable),
% first-tap-zero on/off (metastability). prints a dB table + psd overlay.
clear; close all; clc;
if ~exist('results','dir'), mkdir('results'); end

p = firdsm_params(); p.Nfft = 2^15; p.amp = 0.5;
jit = 0.003;                    % rms jitter (fraction of Ts) for the fir comparison
mtau = 0.025;                   % metastability regen time const for ~52 dB hit

run = @(q) deal_spec(q);
function s = deal_spec(q)
  [y,st] = firdsm_run(q); s = firdsm_spec(y, q, st.fin); s.unstable = st.unstable;
end

% full proposed design
sA = run(p);
% fir dac off (plain single-bit) vs on, both with clock jitter
qf=p; qf.fir_on=0; qf.comp_on=0; qf.jitter_rms=jit; sFoff = run(qf);
qn=p; qn.jitter_rms=jit; sFon = run(qn);
% compensation off (fir in, no comp) -> unstable
qc=p; qc.comp_on=0; sCoff = run(qc);
% metastability with / without the first tap zeroed
qm=p; qm.meta_on=1; qm.meta_tau=mtau; qm.first_tap_zero=0; sMoff = run(qm);
qz=p; qz.meta_on=1; qz.meta_tau=mtau; qz.first_tap_zero=1; sMon  = run(qz);

fprintf('\n=== technique enable/disable (SNDR, dB) ===\n');
fprintf('full proposed design (ideal)        : %6.1f\n', sA.SNDR);
fprintf('FIR dac OFF (plain 1-bit) + jitter   : %6.1f\n', sFoff.SNDR);
fprintf('FIR dac ON              + jitter     : %6.1f   (FIR jitter gain %.0f dB)\n', sFon.SNDR, sFon.SNDR-sFoff.SNDR);
fprintf('compensation OFF (FIR, no comp)      : %6.1f   unstable=%d\n', sCoff.SNDR, sCoff.unstable);
fprintf('metastability, first-tap-zero OFF    : %6.1f\n', sMoff.SNDR);
fprintf('metastability, first-tap-zero ON     : %6.1f   (recovery %.0f dB)\n', sMon.SNDR, sMon.SNDR-sMoff.SNDR);

% psd overlay of the most telling cases
figure('Position',[100 100 950 620]);
semilogx(sA.faxis, sA.fdB, 'k', 'LineWidth',1); hold on;
semilogx(sCoff.faxis, sCoff.fdB, 'r', 'LineWidth',1);
semilogx(sMoff.faxis, sMoff.fdB, 'm', 'LineWidth',1);
semilogx(sFoff.faxis, sFoff.fdB, 'b', 'LineWidth',1);
xline(p.fb,'g--','LineWidth',1.5); hold off; grid on;
xlim([1e6 p.fs/2]); ylim([-160 5]); xlabel('Frequency (Hz)'); ylabel('Amplitude (dBFS)');
legend(sprintf('full design (%.0f dB)',sA.SNDR), sprintf('comp OFF (unstable)'), ...
       sprintf('metastab, no 1st-tap-zero (%.0f dB)',sMoff.SNDR), ...
       sprintf('FIR off + jitter (%.0f dB)',sFoff.SNDR), 'f_b','Location','southwest');
title('Q2.1 enable/disable techniques: output PSD');
print(gcf, fullfile('results','FIRDSM_techniques_onoff'), '-dpng','-r110');
fprintf('saved technique on/off plot to results/\n');
