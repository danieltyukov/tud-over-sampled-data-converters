# FINAL AGENT PROMPT — paste this to launch the executor

Copy everything in the box below into a fresh Claude Code session started in
`/home/danieltyukov/workspace/tud/tud-over-sampled-data-converters/practical-exam`.
It is self-contained and points at the prepared docs.

---

```
You are completing the ET4278 "Over-Sampled Data Converters" final oral exam project for
Daniel Tyukov (5714699). This directory (practical-exam/) is fully prepped: read CLAUDE.md
first, then the numbered .md files. Do NOT re-research the paper — everything you need is here.

PAPER: Shettigar & Pavan, "Design Techniques for Wideband Single-Bit Continuous-Time
Delta-Sigma Modulators With FIR Feedback DACs," IEEE JSSC 47(12), Dec 2012.

GOAL: produce (1) the MATLAB model + all reproduction plots, and (2) the filled-in
PowerPoint, answering the 50-point rubric in 02_exam_requirements_and_grading.md.

START BY READING (in order):
  CLAUDE.md, 02_exam_requirements_and_grading.md, 01_paper_analysis.md,
  04_matlab_requirements.md, 09_reference_notes.md, 08_coding_practices.md,
  03_presentation_structure.md, 05_theory_reference.md, 06_literature_review.md,
  07_references_ieee.md.
Paper figures to reproduce/compare against are individual images in figures/ (fig01..fig30,
tableI, tableII). 13 source-paper PDFs are in refs/ (Shettigar2012 = the paper itself).
09_reference_notes.md already mined the precise models from those PDFs -- use them:
jitter error-per-edge + sigma_dy table, metastability equivalent-jitter shortcut, the
weak-nonlinearity two-run method (Gm=1000,G3=20), assisted-opamp gain/BW model, and the
compensation closed-form (DT path equivalents -> solve k1..k4 from 1/NTF-1; keep the
highest-order khat=k, then E(z)=M1(z) from 1-F(z)=M1(z)(1-z^-1) [7 taps for N=8, DC gain 0]
and re-tune the inner gains to hold the NTF; H1(s) = bandpass peaking ~100 MHz). NOTE: the
khat2=k2+(k3/2)(N-1) formula in 09 is Sukumaran's THIRD-order template -- the chosen paper is
4th-order, so apply the same method (match 1/NTF-1, then re-derive the analogous relations),
do not copy the 3rd-order formula literally.

NON-NEGOTIABLE RULES (full list in CLAUDE.md):
  - MATLAB .m files ASCII-only; no Unicode in code. Unicode math only in .md.
  - NO Schreier delsig toolbox, no addpath, no quant(), no Deep Learning Toolbox.
    Build NTF/STF/loop by hand; quantise with 2*(w>=0)-1 and q*round(x/q).
  - Spectra: kaiser(N,20), coherent tone, dBFS via A*N/2; SNR/SNDR by hand-rolled bin sum
    (signal_bins = maintone+-7, inband_bins = 1:round(fb/fres)). Match 08_coding_practices.md.
  - Every script: parameter block at top (all knobs), runs headless
    (matlab -nodisplay -batch, or the matlab MCP run_matlab_file), saves every figure to
    results/. Seed rng(1). Terse lower-case comments, no em-dashes.
  - VERIFY BY SIMULATION before claiming any number. Hit the targets in
    04_matlab_requirements.md section 5. Edit in place; do not send any email yourself.

EXECUTION PLAN:

Phase 1 - Model & coefficients (Q2 model slide):
  - In practical-exam/matlab/, derive the 4th-order OBG-1.5 NTF with two optimised zeros
    (notch ~ fb/sqrt(3)); map to a CT modified-CIFB + input-feedforward loop via impulse
    invariance accounting for the z^-0.5 delay; scale integrator swings < ~0.45.
  - F(z) = [0.07 0.12 0.15 0.16 0.16 0.15 0.12 0.07]; derive E(z) (7-tap = useful part of
    1-F(z)) and the bandpass H1(s) with the closed-form method in 09_reference_notes.md sec B.
    Shettigar's own MS thesis is NOT public (confirmed), so DERIVE the coefficients -- do not
    wait on it. Sanity-check Sukumaran2014 in refs/ for the procedure.
  - Plot realised |NTF| vs f/Fs (reproduce fig08) and |STF| (reproduce fig09).

Phase 2 - Core reproduction (Q2.6 slides): output PSD -4 dBFS @10 MHz (fig22, with HD2/HD3,
  SNR/SNDR), SNR/SNDR vs amplitude incl. the ISI kink (fig21), metastability with/without the
  first-tap delay (fig04: ~52 -> ~91 dB), nonlinear-integrator floor rise (fig03, Pavan [14]
  weak-cubic method), jitter PSD (fig02), jitter-filtering nulls (fig26, at F(z) zeros),
  jitter tolerance (fig27, ~10x vs plain single-bit).

Phase 3 - Enable/disable (Q2.1): FIR DAC on/off, compensation path on/off (off => unstable),
  first-tap-zero on/off; quantify each in dB in a table.

Phase 4 - Scaling, thermal noise, decimation (Q2.2-2.4): scale swings + state assumptions;
  add input-referred thermal noise to hit DR ~83 dB; build a sinc^(order+1) decimator and plot
  PSD before/after decimation + transient waveforms.

Phase 5 - Non-idealities (Q3, one slide each): finite gain/BW (leaky integrator + 1-pole,
  paper 55 dB/2 GHz), FIR-tap DAC mismatch (perturbs F(z) zeros, no new harmonics), ELD
  (fractional feedback delay; show RZ DAC0 restores), clock jitter (white + sinusoidal-FM),
  integrator non-linearity (weak cubic on I4). Show the effect of each.

Phase 6 - Circuit blocks (Q4): one slide per block using figures/fig10,fig12,fig13,fig16,fig18
  with the descriptions from 01_paper_analysis.md section 4 (draw comparator sampling/regen
  phases).

Phase 7 - Lit review + improvements (Q5/Q6/Q7): strengths/weaknesses table; EXTEND Table II
  with post-2012 designs from 06_literature_review.md/07_references_ieee.md; propose >=1
  improvement (in-loop/adaptive ISI correction or dual-RZ/R2O DAC; or more/time-interleaved
  FIR taps; or FIR-chopping) WITH an updated block diagram AND a MATLAB verification
  (e.g. reproduce figs 29/30: HD2 -15 dB, peak SNDR -> ~74 dB).

Phase 8 - Presentation: fill 'Final oral exam templete 2026.pptx' following
  03_presentation_structure.md. Do NOT reorder or delete slides; duplicate + suffix A/B/C if a
  question needs more than one; put the answer/conclusion on every slide; paper figure left,
  your MATLAB plot right on Q2.6 slides. Build the .pptx (e.g. python-pptx) keeping the TU Delft
  template layout/footer.

DELIVERABLES: practical-exam/matlab/*.m + results/*.png, and the completed .pptx. Tell the user
to email both to yliu73@tudelft.nl at least 24 h before the slot (you do not send mail).

Work in phases, run/verify each script with the matlab MCP, compare each plot against the
matching figures/figNN_* before moving on, and report the dB agreement. Ask me only if a needed
coefficient cannot be derived from 09_reference_notes.md sec B + Eq.1.
```

---

### Tips for whoever launches this
- Start the session **in this folder** so `CLAUDE.md` auto-loads.
- The `matlab` MCP is available (`run_matlab_file`, `check_matlab_code`); MATLAB has **no Deep Learning Toolbox** here.
- The 13 source PDFs are **already downloaded** in `refs/` (the paper + [6][7][13][14][15] + the newer FIR-DAC papers), and `09_reference_notes.md` already distilled them — no need to re-fetch. Only the Mokhtar '22 / Runge '21 comparison rows lack full specs; the executor can pull those two from IEEE if it wants them in the table.
- Consider running Phases 1-7 first (MATLAB), reviewing the `results/` PNGs, then Phase 8 (slides) so the figures are final before they go on slides.
