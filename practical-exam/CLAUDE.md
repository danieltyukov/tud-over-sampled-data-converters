# CLAUDE.md — ET4278 practical-exam (FIR-DAC single-bit CT ΔΣ)

This folder is the **fully-prepped workspace for the ET4278 final oral exam**. A previous session read the paper, extracted every figure, mined the course notes and the existing assignment/practical code, and researched related work. Your job (the executor) is to **produce the MATLAB model, reproduce the paper's results, and build the presentation** per the specs here. Inherit the parent `../../CLAUDE.md` (Unicode-math rule, SPICE tooling) and `~/.claude/CLAUDE.md` (git identity).

## The task in one line
Model + simulate Shettigar & Pavan, JSSC 2012 ("single-bit CT ΔΣ with FIR feedback DAC"), reproduce its key plots in MATLAB, and answer the 50-point rubric on the official slide template.

## Read these first (in order)
1. `02_exam_requirements_and_grading.md` — the 50-pt rubric + deliverables (the contract).
2. `01_paper_analysis.md` — full paper + every figure analysed (`figures/figNN_*`).
3. `04_matlab_requirements.md` — the MATLAB build spec (what to plot, how to scale, the knobs).
4. `08_coding_practices.md` — match the student's existing MATLAB style.
5. `03_presentation_structure.md` — slide-by-slide.
6. `05_theory_reference.md`, `06_literature_review.md`, `07_references_ieee.md` — lingo, Q5/Q6/Q7, PDF links.
7. `09_reference_notes.md` — **precise models mined from the `refs/` PDFs** (jitter/metastability/weak-nonlinearity/assisted-opamp + the compensation closed-form to derive E(z)/coefficients + exact comparison numbers). The 13 source PDFs are in `refs/`.

## Key paper facts (defaults for the model)
4th-order single-bit CT ΔΣ, modified CIFB + input feed-forward; **8-tap FIR DAC** `[0.07 0.12 0.15 0.16 0.16 0.15 0.12 0.07]`; fs=3.6 GS/s; BW=36 MHz; **OSR≈50**; **OBG=1.5**; analog FIR-delay compensation (E(z) 7-tap → bandpass H₁(s)); RZ DAC ELD comp. Measured: SNDR 70.9 / SNR 76.4 / DR 83 dB; 15 mW @ 1.2 V; 90 nm; FoM 72.7 fJ/lvl. Opamp: DC gain ≈55 dB, UGB ≈2 GHz.

## HARD RULES (do not violate)
- **MATLAB `.m` files: ASCII-only.** No Unicode in code/comments. Unicode math only in `.md`.
- **No Schreier delsig toolbox** and **no `addpath`** — the whole repo is hand-rolled. Build NTF/STF/loop by hand. Do NOT call `synthesizeNTF/simulateDSM/calculateSNR`.
- **No `quant()` / Deep Learning Toolbox** (errors here) — use `2*(w>=0)-1` and `q*round(x/q)`.
- **Spectra:** `kaiser(N,20)`, coherent tone, dBFS via `A*N/2`. **SNR/SNDR by hand-rolled bin sum** (signal_bins = maintone±7; inband_bins = 1:round(fb/fres)). See `08_coding_practices.md`.
- **Headless:** run `matlab -nodisplay -batch "name"` (or the `matlab` MCP `run_matlab_file`); save every figure to `results/`. Guard `if ~exist('results','dir'), mkdir('results'); end`.
- **Every script opens with a parameter block** so any knob can be changed live at the oral.
- **Verify by simulation before claiming a result.** Never assert a number you didn't run. Match the targets in `04_matlab_requirements.md` §5.
- **Edit in place**; prefer extending existing helpers over new files; `git mv` to rename. Seed RNG (`rng(1)`).
- **Comment voice:** terse, lower-case, student style, no em-dashes, no AI-isms (a `humanizer` skill exists).

## Figures
All paper figures are individual images in `figures/` (`fig01_*` … `fig30_*`, `tableI_*`, `tableII_*`). Full-page renders in `figures/pages/`, raw extracts in `figures/embedded/`. Put the paper figure next to your MATLAB reproduction on each Q2.6 slide.

## What to deliver
1. MATLAB scripts under `practical-exam/matlab/` (suggested split in `04_matlab_requirements.md` §4) + `results/` PNGs.
2. The filled-in presentation from `Final oral exam templete 2026.pptx` (do not reorder/delete slides; one conclusion per slide).
3. Email both to `yliu73@tudelft.nl` ≥24 h before the slot (the user sends it — do not send mail yourself).

## Tooling
- `matlab` MCP: `run_matlab_file`, `evaluate_matlab_code`, `check_matlab_code`, `detect_matlab_toolboxes`. Use it to run/verify.
- IEEE PDFs: TU Delft proxy links in `07_references_ieee.md` (user is logged in).
