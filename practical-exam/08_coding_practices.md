# Coding Practices — match the existing assignment/practical style

Extracted from all 38 `.m` files in `assignment1..5` and `practical1..3`. The new exam MATLAB must look like the student wrote it. **Most important fact: there is NO Schreier delsig toolbox and NO `addpath` anywhere — everything is hand-rolled.** Do not introduce the toolbox.

---

## 1. Environment rules
- **ASCII-only** in `.m` files (comments + strings). Greek/superscripts only inside TeX plot strings like `ylabel('w_1')`, `'Sinc^2'`, `'\rightarrow'`. Unicode math lives in `.md` write-ups (e.g. `ANSWERS.md`), never in code.
- **No Deep Learning Toolbox / `quant()`** — it errors here. `practical3/mbq.m` documents this. Use `q*round(x/q)`.
- **Headless:** scripts run top-to-bottom and save every figure; run `matlab -nodisplay -batch "name"`. Guard `if ~exist('results','dir'), mkdir('results'); end`.
- **Preamble:** `clear; close all;` (often `clc; format long;`).
- **Comment voice:** terse, lower-case, student style, no em-dashes (` - ` or `->`), dense near design decisions, sparse in loops.

## 2. Quantizers
```
y(a) = 2*(w2(a) >= 0) - 1;     % preferred 1-bit (never 0); sign(w) also seen
% multi-bit mid-rise (assignment3 + practical3/mbq.m), no quant():
delta = 2/(nr_levels-1);
q_out = round((in/vref + 1)/delta)*delta - 1;
q_out = sign(in)*min(abs(q_out),1);            % clip to +-1
```

## 3. Spectral analysis (universal recipe)
- **Window: `kaiser(N,20)` always.** (`window(@hann,N)` appears only to *demonstrate* leakage.)
- **Coherent tone:** `nr_points = round(nr_periods*fs/fin)` (DT) or `N = ceil(fs/fres)` (CT, `fres=0.05`).
- **dBFS (CT-assignment style, use this to overlay the paper):**
```
ffty = fft(y(2:N+1)'.*kaiser(length(y)-1,20));
ffty_magn = abs(ffty)/(amplitude*N/2);   % full-scale-sine peak = A*N/2
ffty_dB   = 20*log10(ffty_magn);
```
- Axis: `semilogx((1:round(N/2))*fres, ffty_dB(1:round(N/2)))` (scale `*1e3` if kHz base).

## 4. SNR / SNDR (hand-rolled bin sum — never calculateSNR)
```
fres        = fs/nr_points;
maintone    = round(fin/fres);                 % or nr_periods+1 in CT scripts
signal_bins = maintone-7 : maintone+7;         % ~15 bins = Kaiser(20) main lobe
inband_bins = 1 : round(fb/fres);              % CT scripts start at bin 1
noise_bins  = setdiff(inband_bins, signal_bins);
P = ffty(inband_bins).*conj(ffty(inband_bins));
SNR = 10*log10(sum(P(signal_bins)) / sum(P(noise_bins)));
```
- **SNDR vs SNR:** SNDR keeps harmonics in the noise sum; SNR also removes `harm_bins = k*(maintone-1)+1 +/- 3` for k=2..5. Report **HD2/HD3** in dBc (`h2=2*(maintone-1)+1`, `h3=3*(maintone-1)+1`, ±3 bins).
- **No NBW normalisation** — the main lobe is excised by the ±7 window instead.
- **OSR / threshold sweeps** use `for ... if (SNR>target) break; end`.

## 5. Loop-filter / integrator idioms
- Plain accumulator: `w(a) = w(a-1) + in(a-1) - y(a-1);`
- Leaky (finite gain A): `p = 1 - 1/A; w(a) = p*w(a-1) + ...;`
- 2nd-order CIFF (DT): `w2=w2+b2*w1; w1=w1+b1*(in-y); w12=c1*w1+c2*w2; y=2*(w12>=0)-1;`
- 2nd-order CIFB (DT): `w2=w2+b2*(w1-a2*y); y=...; w1=w1+b1*(in-a1*y);`
- Resonator (NTF zero): extra `-d*w2(a-1)` in the w1 update; `d=(2*pi*(fb/sqrt(3))/fs)^2`.
- **CT (sub-stepped):** inner `for b=1:nr_steps`, `om=1/nr_steps`, integrate every sub-step, quantise once per clock, hold the NRZ DAC value over the inner loop. `nr_steps=20` (2000 for VCO).

## 6. Coefficient scaling (keep states < ~0.45-0.5; preserves NTF/STF for 1-bit)
```
k1 = 0.45/max(abs(w1)); k2 = 0.45/max(abs(w2));
b1 = b1*k1; b2 = b2*k2/k1;
c1 = 2*b2;   % FF: c*=c*b2 ; FB: a2=2*b1 ; resonator: d=d/b1/b2
```

## 7. Non-ideality injection (existing patterns to reuse / extend)
- **Thermal noise:** `+ noise_rms*randn` at the chosen summing node (input-referred at int1). Budget: `noise_rms = amplitude*sqrt(fs*nr_steps/4/fb/10^(SNR/10))`, or sweep.
- **DAC finite rise-time:** linear ramp on a -1->+1 transition, instant fall; `wave = -1 + 2*min((0:nr_steps-1),rise_steps)/rise_steps;` (A3/A5).
- **DAC ISI (asymmetric):** 4-row `DAC_wave` lookup keyed on (prev,curr) bit pair (`MOD2_CT_NRZDAC.m`).
- **Element mismatch (multi-bit):** `elem_mis = 1 + mismatch*randn(1,nr_elem)`, `mismatch=0.01`.
- **DEM / DWA:** `thermoDACrnd.m` (randperm) and the DWA pointer in `MOD2_3Bit_ThermoDAC.m`.
- **MASH recombine:** `filter(...)` digital cancellation (`recombine` in A5).
- **MISSING — write from scratch:** **clock jitter** (no phase-noise/edge-timing model exists), a general **ELD** tuner (only an implicit A4 FIR-delay compensation), and any **multistage/CIC decimator** (decimation is always a single weighted-average window). The FIR-DAC paper needs all three.

## 8. Decimation (existing style)
```
sinc1 = ones(1,Ndec); sinc2 = window(@triang,Ndec);
out = sum(y.*filt)/sum(filt);     % weighted average of the bitstream
```
`filter()` is used only twice (A4 FIR-DAC impulse response, A5 MASH recombine). No `designfilt`/`dfilt`/CIC objects — for the exam's sinc^L decimator, cascade box-cars or use `filter` then downsample.

## 9. Plotting & saving
- `figure;` or `figure('Position',[100 100 900 600])`. Time plots black `'k','LineWidth',1.5`; spectra `semilogx(...,'-r','LineWidth',1)`. **No `set(gca,'FontSize',...)`** — defaults only; just set `LineWidth`. **`grid on;` on every plot.**
- Signature spectrum overlay: full PSD + in-band band green (LineWidth 3) + main tone red (LineWidth 3) + `legend`, `xlabel`, `ylabel`, `title`.
- Multi-panel time: `subplot(3,1,1..3)` for w1/w2/y + `sgtitle(sprintf(...))`. Limits via `ylim`, `axis([...])`, markers via `xline`, `yline`.
- **Save:** newer code uses `print(gcf, fullfile('results',NAME), '-dpng','-r110')`; older uses `saveas(gcf,'results/NAME.png')`. Never `exportgraphics`. Names: `<Prefix>_<desc>.png`, often `sprintf`'d.

## 10. File conventions
- Submission scripts: `A<N>_Daniel_5714699_Jiahui_6551998.m` with a big `%` header block (title, both authors, prose answers) before the code. For the exam, MATLAB is submitted separately from slides — use clear `FIRDSM_*.m` names (see `04_matlab_requirements.md` §4).
- Helper functions either local at the bottom (after `%% functions used`) or standalone (`mbq.m`, `thermoDAC.m`).
- Practicals keep a markdown `ANSWERS.md` write-up; assignments put the write-up in the `.m` header.
- **Seed RNG** (`rng(1)`, `rng(7)`) before mismatch/DEM/jitter runs for reproducibility.
