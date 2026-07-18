# Presentation Structure — slide-by-slide

Built from `Final oral exam templete 2026.pptx/.pdf`. **Rules from the template's slide 1:** do not change slide order, do not delete slides, put your answer/conclusion on each slide, and if a question needs more than one slide duplicate it and suffix A/B/C (e.g. Q2.6A, Q2.6B). The footer is "Over-Sampled Data Converters – ET4278 – Final Exam – 2026".

Each entry below = the template slide, what the template literally asks, and exactly what to put on it (content, figures from `figures/`, MATLAB plot, and the one-line conclusion). "Paper fig" = the published result for the left/"Published result" box; "Your fig" = your MATLAB reproduction for the right/"Your result" box.

---

### Slide 1 — Title
- Paper Title; "Daniel Tyukov, 5714699"; ET4278.
- (Template remarks already on the slide — leave them or remove cleanly.)

### Slide 2 — Q1. Introduction (5 pts)
- **Issues** (bullets): single-bit jitter sensitivity; comparator metastability; loop-filter linearity; multi-bit quantizer power/area + DAC mismatch/DEM; FIR group delay → ELD.
- **Techniques** (bullets): 1-bit ADC + 8-tap semi-digital FIR DAC; first tap = 0; analog FIR-delay compensation path; RZ ELD comp; CIFB + feed-forward, active-RC, assisted opamp.
- Figures: `fig01...` (FIR DAC concept) + `fig07...` (architecture).
- **Conclusion line:** "FIR feedback gives a 1-bit loop the jitter/linearity of a multi-bit loop; the price is loop delay, solved by an analog compensation path."

### Slide 3 — Q2. MATLAB model & list of coefficients
- Block diagram of the modulator (redraw `fig07...` or use it).
- **List coefficients:** F(z) 8 taps `[0.07 0.12 0.15 0.16 0.16 0.15 0.12 0.07]`; E(z) (7-tap, derived); ω₁…ω₄; k₀,k₁,k₂,k₃,k_f,k_c1,k_c2; H₁(s) poles/zeros.
- **How derived:** synthesise 4th-order OBG-1.5 NTF with two optimised zeros → CIFB → CT via impulse invariance → scale swings; F(z) from Eq.(1); E(z) = useful part of [1−F(z)]; H₁(s) by impulse-invariance match (see `04_matlab_requirements.md`).
- **Conclusion line:** state which coefficients came from the paper vs which you derived, and that the model reproduces the OBG-1.5 NTF.

### Slide 4 — Q2.1 Proposed technique (enable/disable)
- Table/plots quantifying SQNR/SNR with each technique ON vs OFF:
  - FIR DAC on/off (vs plain single-bit) — expect large jitter/linearity difference.
  - First-tap-zero on/off — metastability (Fig 4: ~52 → ~91 dB).
  - Compensation path on/off — stable vs unstable / NTF restored (Figs 6, 8).
- Paper fig: `fig04...`. Your fig: your on/off PSDs + a small results table.
- **Conclusion line:** quantify each technique's dB contribution.

### Slide 5 — Q2.2 Voltage scaling
- State assumptions: internal full-scale = ±1 (Vref normalised), quantizer output ∈ {−1,+1}; integrator outputs scaled so each stays below ~0.45–0.5 (first-order path saturates last, per paper); map to the 1.2 V supply / Vref if showing volts.
- Your fig: histogram or max-|state| bar chart per integrator before/after scaling.
- **Conclusion line:** scaling preserves NTF/STF (1-bit), keeps swings within MSA.

### Slide 6 — Q2.3 Thermal noise & output spectrum
- Add input-referred thermal noise; choose σ to make the in-band noise floor match DR ≈ 83 dB (36 MHz).
- Your fig: output PSD with thermal noise, dBFS-scaled, signal/in-band/noise bins marked (course style).
- **Conclusion line:** state the noise level used and the resulting DR.

### Slide 7 — Q2.4 Decimation filter
- Explain the decimation filter (sinc/CIC; course uses weighted-average sinc1/sinc2; a sinc^L with L = order+1 is the textbook choice). Plot **output spectrum before and after decimation** + **transient waveforms** (bitstream, integrator states, decimated output sine).
- Your figs: PSD pre/post-decimation; time-domain transient.
- **Conclusion line:** decimation removes out-of-band shaped noise; SNR in band preserved.

### Slide 8 — Q2.5 List of simulation results
- Table of paper's simulated + measured results (from Tables I/II and Figs) and which you reproduced (✓) vs not (with reason — e.g. survey scatter Figs 23/24 are not reproducible).
- Summary of MATLAB assumptions (fs, OSR, N_fft, window, coherent tone, nr_steps, RNG seed).
- **Conclusion line:** "Reproduced: NTF, STF, jitter (Figs 2/26/27), metastability (4), nonlinear integrator (3), PSD (22), SNDR-vs-A (21), ISI corr (29/30)."

### Slides 9.x — Q2.6-X MATLAB simulation comparison (one per simulation)
Use the template's two-box layout: **Published result | Your result**, then **quantify your comparison** in the dashed box. **One page per simulation, do not change the layout.** Recommended set (duplicate the slide per item, number Q2.6A…):
| Slide | Paper fig (left) | Your reproduction (right) |
|---|---|---|
| Q2.6A NTF | `fig08...` | your |NTF| vs f/Fs, OBG=1.5, 2 zeros |
| Q2.6B STF | `fig09...` | your |STF|, ~+12 dB peak ~100 MHz |
| Q2.6C Output PSD | `fig22...` | your PSD, −4 dBFS @10 MHz, HD2/HD3, SNR/SNDR |
| Q2.6D Jitter PSD | `fig02...` | your PSD with 0.3 ps rms jitter, FIR vs plain |
| Q2.6E Jitter filtering | `fig26...` | in-band noise vs FM jitter freq, nulls at F(z) zeros |
| Q2.6F Jitter tolerance | `fig27...` | tol vs jitter freq, 1b+FIR vs 4b vs 1b |
| Q2.6G Metastability | `fig04...` | with/without first-tap delay |
| Q2.6H Nonlinear integrator | `fig03...` | weak-cubic integrator floor rise |
| Q2.6I SNDR vs amplitude | `fig21...` | sweep incl. ISI kink |
- **Conclusion line per slide:** the dB/number agreement and any discrepancy + why.

### Slides 10–14 — Q3 Non-idealities (5 pts; one per slide; keep the plot-box aspect ratio)
- **10 Q3.1 Finite amp gain & BW:** paper 55 dB / 2 GHz; your sweep of DC gain and UGB → in-band floor. Conclusion: minimum gain/BW for negligible penalty.
- **11 Q3.2 DAC mismatch:** FIR-tap σ; show F(z) zero shift / jitter-null shift; note 1-bit DAC has no level mismatch. Conclusion: mismatch perturbs F(z) (linear), not linearity.
- **12 Q3.3 ELD:** fractional delay in feedback; NTF degradation/instability; RZ comp restores. Conclusion: ELD must be compensated; how much delay tolerated.
- **13 Q3.4 Clock jitter:** white + FM jitter model; in-band noise vs jitter; FIR filtering. Conclusion: FIR DAC reduces jitter sensitivity ~10×.
- **14 Q3.5 Integrator non-linearity:** weak cubic on I₄; floor rise; dominant integrator = input I₄. Conclusion: FIR relaxes I₄ linearity vs plain single-bit.

### Slides 15.x — Q4 Circuit implementation (5 pts; 1 block/slide)
Recommended blocks (duplicate slide per block, number Q4.1, Q4.2…):
- **Q4.1 Loop filter / active-RC integrator** (`fig10...`) — RC integrator, virtual-ground summing, assisted opamp.
- **Q4.2 Semi-digital FIR feedback DAC** (`fig01...`, `fig16...`) — tapped delay + switched-resistor unit elements; reference- vs virtual-ground-side switching.
- **Q4.3 Two-stage feed-forward opamp** (`fig12...`) — 55 dB / 2 GHz, ac-coupled FF path.
- **Q4.4 Comparator** (`fig13...`,`fig14...`,`fig15...`) — high-initial-current latch; sampling/regeneration phases (draw the two phases).
- **Q4.5 (optional) LC-PLL/VCO** (`fig18...`).
- **Conclusion line per slide:** the block's role + key spec.

### Slide 16 — Q5 Strengths & weaknesses (5 pts)
- Table: technique → strength → weakness vs current SoTA (from `06_literature_review.md`).
- Motivate whether the FIR-DAC technique solves the original issues (yes for jitter/linearity/DEM; residual ISI = remaining weakness).
- **Conclusion line:** net assessment.

### Slide 17 — Q6 Comparison (5 pts)
- **Extended Table II:** original 7 columns + added modern designs (Sukumaran '14, Bolatkale '11 already in, Theertham '22, plus 1–2 recent wideband). Highlight where this work leads/lags.
- **Conclusion line:** where the paper sits in 2012 vs today.

### Slide 18 — Q7 Proposed improvements (5+5 pts)
- Proposal(s): e.g. (a) **in-loop/automatic ISI correction** (dual-RZ or digital, ref [17]/Theertham '22) to recover the 74.3→ peak SNDR without post-processing; (b) **more FIR taps / time-interleaved FIR** (Jain–Pavan '18) for more jitter margin; (c) **chopping for free** with FIR (Pavan '18) for 1/f noise. Show an updated architecture drawing.
- **Verify in MATLAB:** implement the chosen improvement and show the SNDR/PSD gain (e.g. ISI correction reproducing Figs 29/30; or more taps → lower jitter floor).
- **Conclusion line:** quantified improvement.

### Slide 19 — Summary
- Conclude your overall assessment of the paper (what it achieves, residual limits, relevance today).

---

## Slide-count budget (typical)
1 title + 1 (Q1) + 1 (Q2 model) + 4 (Q2.1–2.4) + 1 (Q2.5) + ~9 (Q2.6 comparisons) + 5 (Q3) + ~5 (Q4) + 1 (Q5) + 1 (Q6) + 1 (Q7, maybe 2) + 1 summary ≈ **30–32 slides**. Keep each slide single-message with its conclusion line.
