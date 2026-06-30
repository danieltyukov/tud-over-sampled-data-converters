% FIRDSM_jitter.m
% Q2.6D/E/F, Q3.4 - clock jitter.
%  part 1 (fig 2)  : white jitter psd, 1-bit+FIR vs plain 1-bit vs 4-bit
%  part 2 (fig 26) : in-band noise vs sinusoidal-fm jitter freq, nulls at F(z) zeros
%  part 3 (fig 27) : max tolerable rms jitter vs jitter freq, FIR vs plain 1-bit
clear; close all; clc;
if ~exist('results','dir'), mkdir('results'); end
p = firdsm_params();

% ---------- part 1: white jitter psd (fig 2) ----------
p1 = p; p1.Nfft = 2^16; p1.amp = 0.5;
jit_ps = 0.3e-12; jr = jit_ps*p.fs;          % 0.3 ps rms as fraction of Ts
cfg(1) = setfields(p1, 'jitter_rms',jr);                              % 1-bit + FIR
cfg(2) = setfields(p1, 'jitter_rms',jr, 'fir_on',0, 'comp_on',0);    % plain 1-bit
cfg(3) = setfields(p1, 'jitter_rms',jr, 'fir_on',0, 'comp_on',0, 'nlev',16); % 4-bit
lab = {'1-bit + FIR DAC','plain single-bit','4-bit'};
col = {'b','r','m'};
figure('Position',[100 100 950 620]);
for i=1:3
  [y,st]=firdsm_run(cfg(i)); s=firdsm_spec(y,cfg(i),st.fin);
  ibr = s.faxis<=p.fb;
  semilogx(s.faxis(ibr), s.fdB(ibr), col{i}, 'LineWidth',1.2); hold on;
  fprintf('%-16s jitter SNDR=%.1f dB\n', lab{i}, s.SNDR);
end
hold off; grid on; xlabel('Frequency (Hz)'); ylabel('In-band PSD (dBFS)');
legend(lab,'Location','northwest'); xlim([1e6 p.fb]); ylim([-160 -40]);
title(sprintf('In-band PSD with %.1f ps rms white jitter (reproduces Fig. 2)',jit_ps*1e12));
print(gcf, fullfile('results','FIRDSM_jitter_psd'), '-dpng','-r110');

% ---------- part 2: fm jitter nulls at F(z) zeros (fig 26) ----------
p2 = p; p2.Nfft = 2^14; p2.amp = 0.3;
fmod = linspace(100e6, 1.8e9, 28);
inband = zeros(size(fmod));
for k=1:numel(fmod)
  q=setfields(p2,'jitter_rms',0.10,'jitter_fmod',fmod(k));
  [y,st]=firdsm_run(q); s=firdsm_spec(y,q,st.fin);
  nb = setdiff(s.inband_bins, s.signal_bins);
  P = abs(fft(y(:).*kaiser(numel(y),20))).^2;
  inband(k) = 10*log10(sum(P(nb)));
end
% |F(z)| magnitude for the overlay
Fz = abs(polyval(fliplr(p.firtaps), exp(-1j*2*pi*fmod/p.fs)));
fz_zeros = roots(p.firtaps); ang = angle(fz_zeros); fnull = abs(ang)/(2*pi)*p.fs;
fnull = fnull(abs(abs(fz_zeros)-1)<0.05);     % zeros on the unit circle
figure('Position',[100 100 950 620]);
yyaxis left;  plot(fmod/1e9, inband-max(inband), 'bo-','LineWidth',1.5); ylabel('In-band jitter noise (dB, norm)');
yyaxis right; plot(fmod/1e9, 20*log10(Fz),'r--','LineWidth',1.5); ylabel('|F(z)| (dB)');
grid on; xlabel('FM jitter frequency (GHz)');
title('In-band jitter noise vs FM frequency, nulls at F(z) zeros (reproduces Fig. 26)');
legend('in-band jitter noise','|F(z)|','Location','south');
print(gcf, fullfile('results','FIRDSM_jitter_nulls'), '-dpng','-r110');
fprintf('F(z) unit-circle zeros at: %s MHz\n', strtrim(sprintf('%.0f ',sort(fnull)/1e6)));

% ---------- part 3: jitter tolerance vs jitter freq (fig 27) ----------
p3 = p; p3.Nfft = 2^14; p3.amp = 0.0;        % idle channel
fmt = (0.2:0.12:1.6)*1e9;            % finer frequency grid for a smoother curve
jr_grid = logspace(-4.3,-0.5,28);    % jitter grid (low floor so plain 1-bit is not clipped)
tolFIR = zeros(size(fmt)); tolPlain = tolFIR;
for k=1:numel(fmt)
  tolFIR(k)   = jittol(p3, fmt(k), jr_grid, true);
  tolPlain(k) = jittol(p3, fmt(k), jr_grid, false);
end
figure('Position',[100 100 950 620]);
semilogy(fmt/1e9, tolFIR, 'bo-', fmt/1e9, tolPlain, 'rs-', 'LineWidth',1.5); grid on;
xlabel('Jitter frequency (GHz)'); ylabel('Max tolerable rms jitter (frac of Ts)');
legend('1-bit + FIR DAC','plain single-bit','Location','northwest');
title('Jitter tolerance vs frequency: 1-bit+FIR tolerates ~10x+ more than plain 1-bit (Fig. 27)');
print(gcf, fullfile('results','FIRDSM_jitter_tolerance'), '-dpng','-r110');
fprintf('median FIR/plain jitter tolerance ratio = %.1fx\n', median(tolFIR./tolPlain));
fprintf('saved jitter plots to results/\n');

% ---- helpers ----
function q = setfields(p, varargin)
  q = p; for i=1:2:numel(varargin), q.(varargin{i}) = varargin{i+1}; end
end
function jr = jittol(p, fmod, jr_grid, fir)
  jr = jr_grid(1);
  for j=1:numel(jr_grid)
    q=p; q.jitter_rms=jr_grid(j); q.jitter_fmod=fmod;
    if ~fir, q.fir_on=0; q.comp_on=0; end
    [y,st]=firdsm_run(q);
    if st.unstable, break; end
    P=abs(fft(y(:).*kaiser(numel(y),20))).^2; fr=p.fs/numel(y);
    nb=2:round(p.fb/fr);
    nlev = 10*log10(sum(P(nb))/(sum(kaiser(numel(y),20))/2)^2);  % crude dbfs floor
    if nlev > -80, break; end
    jr = jr_grid(j);
  end
end
