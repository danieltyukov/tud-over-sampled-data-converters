% FIRDSM_nonideal.m
% Q3.1 / Q3.2 / Q3.3 - circuit non-idealities:
%  Q3.1 finite opamp dc gain and unity-gain bandwidth (paper 55 dB / 2 GHz)
%  Q3.2 fir-dac unit-element (resistor) mismatch -> shifts F(z) zeros, no harmonics
%  Q3.3 excess loop delay -> instability; rz dac0 (prompt fast feedback) restores
clear; close all; clc;
if ~exist('results','dir'), mkdir('results'); end
p = firdsm_params(); p.Nfft = 2^15; p.amp = 0.5;

%% Q3.1 finite gain / bw
gains_db = 30:5:70; ugbs = (1:0.5:6)*1e9;
Sg = zeros(size(gains_db)); Su = zeros(size(ugbs));
for k=1:numel(gains_db)
    q=p; q.A_dc=10^(gains_db(k)/20); [y,st]=firdsm_run(q); s=firdsm_spec(y,q,st.fin);
    Sg(k)=s.SNDR;
end
for k=1:numel(ugbs)
    q=p; q.ugb=ugbs(k); [y,st]=firdsm_run(q); s=firdsm_spec(y,q,st.fin);
    if st.unstable, Su(k)=NaN; else, Su(k)=s.SNDR; end
end
figure('Position',[100 100 950 620]);
subplot(1,2,1);
plot(gains_db, Sg,'bo-','LineWidth',1.5); grid on; hold on;
xline(55,'r--','LineWidth',1.5); hold off;
xlabel('opamp DC gain (dB)'); ylabel('SNDR (dB)'); title('Finite DC gain'); legend('SNDR','paper 55 dB','Location','southeast');
subplot(1,2,2);
plot(ugbs/1e9, Su,'bo-','LineWidth',1.5); grid on; hold on;
xline(2,'r--','LineWidth',1.5); hold off;
xlabel('opamp UGB (GHz)'); ylabel('SNDR (dB)'); title('Finite bandwidth'); legend('SNDR','paper 2 GHz','Location','southeast');
sgtitle('Q3.1 finite amplifier gain and bandwidth');
print(gcf, fullfile('results','FIRDSM_nonideal_gainbw'), '-dpng','-r110');
fprintf('Q3.1: gain 55 dB -> SNDR %.1f; ugb 2 GHz -> SNDR %.1f\n', ...
    interp1(gains_db,Sg,55), interp1(ugbs/1e9,Su,2));

%% Q3.2 fir-dac tap mismatch (linear -> shifts F(z) zeros)
fg = linspace(1e6, p.fs/2, 4000); zexp = exp(-1j*2*pi*fg/p.fs);
figure('Position',[100 100 950 620]);
Fnom = abs(polyval(fliplr(p.firtaps), zexp));
semilogx(fg/1e6, 20*log10(Fnom+eps),'k','LineWidth',2.5); hold on;
rng(3); sig = 0.02;                          % 2% unit-element mismatch (visible)
for r=1:4
    ftm = p.firtaps.*(1+sig*randn(1,p.Ntap));
    Fm = abs(polyval(fliplr(ftm), zexp));
    semilogx(fg/1e6, 20*log10(Fm+eps),'LineWidth',1);
end
hold off; grid on; xlim([400 1200]); ylim([-55 -10]);  % zoom on the first two nulls
xlabel('Frequency (MHz)'); ylabel('|F(z)| (dB)');
legend('nominal F(z)','2% mismatch','2% mismatch','2% mismatch','2% mismatch','Location','south');
title('Q3.2 FIR tap mismatch moves the F(z) zeros (jitter nulls), adds no harmonics');
print(gcf, fullfile('results','FIRDSM_nonideal_mismatch'), '-dpng','-r110');
q=p; q.tapmismatch=0.01; [y,st]=firdsm_run(q); s=firdsm_spec(y,q,st.fin);
fprintf('Q3.2: tap mismatch 1%% -> SNDR=%.1f HD2=%.1f (no new harmonics)\n', s.SNDR, s.HD2);

%% Q3.3 eld + rz dac0
elds = 0:0.05:0.6;
Snorz = zeros(size(elds)); Srz = Snorz;
for k=1:numel(elds)
    q=p; q.eld=elds(k); q.kdac0=0;   [y,st]=firdsm_run(q); s=firdsm_spec(y,q,st.fin);
    Snorz(k) = ternary(st.unstable, -45, s.SNDR);   % unstable -> plot a clear failed level
    q.kdac0=1; [y,st]=firdsm_run(q); s=firdsm_spec(y,q,st.fin);
    Srz(k) = ternary(st.unstable, -45, s.SNDR);
end
figure('Position',[100 100 950 620]);
plot(elds, Snorz,'rs-', elds, Srz,'bo-','LineWidth',1.5); grid on;
xlabel('excess loop delay (fraction of Ts)'); ylabel('SNDR (dB)'); ylim([-50 105]);
yline(0,'k:');   % unstable region sits well below the stable ~94 dB
legend('no ELD comp','with RZ DAC_0','Location','southwest');
title('Q3.3 ELD degrades/destabilises the loop; RZ DAC_0 restores it');
print(gcf, fullfile('results','FIRDSM_nonideal_eld'), '-dpng','-r110');
fprintf('Q3.3: ELD 0.3 Ts -> no comp SNDR=%.1f, with RZ DAC0 SNDR=%.1f\n', ...
    Snorz(elds==0.3), Srz(elds==0.3));
fprintf('saved nonideal plots to results/\n');

function v = ternary(c,a,b), if c, v=a; else, v=b; end, end
