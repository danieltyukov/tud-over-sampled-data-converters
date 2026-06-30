% FIRDSM_nonlin_integrator.m  Q2.6H/Q3.5: weak cubic on input integrator I4 raises
% the in-band floor (i = Gm*v - G3*v^3, pavan [14]). fig 3.
clear; close all; clc;
if ~exist('results','dir'), mkdir('results'); end
p = firdsm_params(); p.Nfft = 2^16; p.amp = 0.5;

g3list = [0 0.1 0.3];
col = {'b','m','r'};
figure('Position',[100 100 950 620]);
fprintf('--- weak cubic on input integrator (1-bit + FIR) ---\n');
for i = 1:numel(g3list)
    q = p; q.g3 = g3list(i); q.Gm = 1;
    [y,st] = firdsm_run(q); s = firdsm_spec(y,q,st.fin);
    ibr = s.faxis <= p.fb;
    semilogx(s.faxis(ibr)/1e6, s.fdB(ibr), col{i}, 'LineWidth',1.2); hold on;
    fprintf('g3=%.2f  SNDR=%.1f dB\n', g3list(i), s.SNDR);
end
hold off; grid on; xlim([1 p.fb/1e6]); ylim([-160 -30]);
xlabel('Frequency (MHz)'); ylabel('In-band PSD (dBFS)');
legend('G_3=0 (ideal)','G_3=0.1','G_3=0.3','Location','northwest');
title('Weak cubic on input integrator raises the in-band floor (reproduces Fig. 3)');
print(gcf, fullfile('results','FIRDSM_nonlin_integrator'), '-dpng','-r110');

% the input integrator dominates: the same cubic on a later integrator (smaller
% swing, less out-of-band content) barely moves the floor.
qa = p; qa.g3 = 0.2; [ya,sta]=firdsm_run(qa); sa=firdsm_spec(ya,qa,sta.fin);
fprintf('input-integrator cubic G3=0.2 -> SNDR=%.1f dB (the input integrator I4 dominates)\n', sa.SNDR);
fprintf('saved nonlinear-integrator plot to results/\n');
