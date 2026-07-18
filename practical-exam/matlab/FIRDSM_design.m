% FIRDSM_design.m  Q2 model: coefficients, NTF (fig 8), STF (fig 9), F(z)/E(z)/H1(s)
clear; close all; clc;
if ~exist('results','dir'), mkdir('results'); end

p = firdsm_params();
a = p.a; g1 = p.g1; g2 = p.g2; numz = p.numz; Dt = p.Dt; fs = p.fs; fb = p.fb;

%% compensation fir E(z) = (1 - F(z)) / (1 - z^-1), 7 taps, dc gain 0
F = p.firtaps;                       % f0..f7
oneminusF = [1-F(1), -F(2:end)];     % 1 - F(z) in z^-1
E = deconv(oneminusF, [1 -1]);       % divide by (1 - z^-1) -> 7 taps

%% bandpass H1(s) approximating the replica-integrator path
% low dc gain (rejects offset) + 1/s roll-off at high f, peak ~100 mhz (figs 6d/11)
wa = 2*pi*30e6; wb = 2*pi*330e6; kh1 = 2;
H1 = @(s) kh1*(s/wa)./((1+s/wa).*(1+s/wb));

%% print the coefficient list (for the Q2 model slide)
fprintf('=== FIR-DAC modulator coefficients (derived) ===\n');
fprintf('order=%d  OSR=%.1f  OBG=%.2f  fs=%.2f GS/s  fb=%.0f MHz\n',p.order,p.OSR,p.OBG,fs/1e9,fb/1e6);
fprintf('F(z) 8 taps : [%s]  (sum=%.3f)\n', strtrim(sprintf('%.2f ',F)), sum(F));
fprintf('E(z) 7 taps : [%s]  (sum=%.4f, dc gain 0)\n', strtrim(sprintf('%+.4f ',E)), sum(E));
fprintf('cifb dac a  : a1..a4 = [%.4f %.4f %.4f %.4f]\n', a);
fprintf('resonators  : g1=%.3e g2=%.3e -> zeros at f/fb = [%.2f %.2f]\n', g1, g2, p.coeff.alpha);
fprintf('input ff kff= %.2f (stf peaking)\n', p.kff);
fprintf('H1(s) bandpass: corners fa=%.0f MHz fb=%.0f MHz, peak ~%.0f MHz\n', wa/2/pi/1e6, wb/2/pi/1e6, sqrt(wa*wb)/2/pi/1e6);

%% realised NTF (optimised zeros) and maximally-flat reference (dc zeros)
w = linspace(0,pi,200000); ejw = exp(1j*w); fovfs = w/(2*pi);
ntf_opt = abs(polyval(numz,ejw))./abs(polyval(Dt,ejw));
% maximally-flat: same obg, all four zeros at dc
cmf = firdsm_coeffs(p.OSR, p.OBG, [1e-6 1e-6]);
ntf_mf = abs(polyval(cmf.numz,ejw))./abs(polyval(cmf.Dt,ejw));

figure('Position',[100 100 900 600]);
semilogx(fovfs, 20*log10(ntf_mf+eps),'b','LineWidth',1); hold on;
semilogx(fovfs, 20*log10(ntf_opt+eps),'r','LineWidth',1.5);
yline(20*log10(p.OBG),'k--','LineWidth',1);
xline(1/(2*p.OSR),'g--','LineWidth',1.5);
hold off; grid on; xlim([2e-3 0.5]); ylim([-100 10]);
xlabel('f / Fs'); ylabel('|NTF| (dB)');
legend('maximally flat (zeros at dc)','realised (2 optimised zeros)','OBG = 1.5','f_b edge','Location','northwest');
title('Realised NTF, 4th-order OBG-1.5 (reproduces Fig. 8)');
print(gcf, fullfile('results','FIRDSM_design_NTF'), '-dpng','-r110');

%% STF magnitude (input feed-forward peaking, fig 9)
% linear closed loop with input ff to the quantizer node
Acl = zeros(4); b1 = p.b1;
stepl = @(s,u) seqstep(s,u,p.kff,a,g1,g2,b1);
for j=1:4, e=zeros(4,1); e(j)=1; Acl(:,j)=stepl(e,0); end
Bcl = stepl([0;0;0;0],1); C=[0 0 0 1];
wS = 2*pi*logspace(5,log10(fs/2),4000)/fs; ejwS=exp(1j*wS);
stf=zeros(size(wS));
for i=1:numel(wS), stf(i)=C*((ejwS(i)*eye(4)-Acl)\Bcl); end
[pk,ip]=max(abs(stf));
fprintf('STF: dc=%.2f dB, peak=%.2f dB @ %.0f MHz\n',20*log10(abs(stf(1))),20*log10(pk),wS(ip)*fs/2/pi/1e6);
figure('Position',[100 100 900 600]);
semilogx(wS*fs/2/pi/1e6, 20*log10(abs(stf)),'r','LineWidth',1.5); hold on;
xline(fb/1e6,'g--','LineWidth',1.5); yline(0,'k:'); hold off; grid on;
xlim([10 1000]); ylim([-2 14]);                 % match paper fig 9 axes
xlabel('Frequency (MHz)'); ylabel('|STF| (dB)');
legend('|STF|','f_b = 36 MHz','Location','northwest');
title(sprintf('Signal transfer function, peak %.0f dB (reproduces Fig. 9)',20*log10(pk)));
print(gcf, fullfile('results','FIRDSM_design_STF'), '-dpng','-r110');

%% compensation path: F(z), E(z) responses and bandpass H1(s)
figure('Position',[100 100 900 600]);
fg = logspace(6, log10(fs/2), 4000); s = 1j*2*pi*fg; zg = exp(1j*2*pi*fg/fs);
Fz = polyval(fliplr(F), 1./zg); Ez = polyval(fliplr(E), 1./zg);
subplot(2,1,1);
semilogx(fg/1e6,20*log10(abs(Fz)),'b','LineWidth',1.5); hold on;
semilogx(fg/1e6,20*log10(abs(Ez)+eps),'r','LineWidth',1.5); grid on; hold off;
ylabel('Magnitude (dB)'); legend('|F(z)| main fir','|E(z)| comp fir','Location','southwest');
title('FIR feedback F(z) and compensation E(z)');
subplot(2,1,2);
semilogx(fg/1e6,20*log10(abs(H1(s))),'k','LineWidth',1.5); grid on;
xlabel('Frequency (MHz)'); ylabel('|H_1(s)| (dB)');
title('Analog compensation bandpass H_1(s), peak ~100 MHz');
print(gcf, fullfile('results','FIRDSM_design_comp'), '-dpng','-r110');

fprintf('saved NTF, STF, compensation plots to results/\n');

% linear step of the cifb (e=0), input feed-forward into the last integrator
function xn = seqstep(s,u,kff,a,g1,g2,b1)
  x1=s(1);x2=s(2);x3=s(3);x4=s(4); dac=x4;
  x1=x1+b1*(u-dac)-g1*x2; x2=x2+x1-a(2)*dac; x3=x3+x2-a(3)*dac-g2*x4; x4=x4+x3-a(4)*dac+kff*u;
  xn=[x1;x2;x3;x4];
end
