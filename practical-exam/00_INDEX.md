# ET4278 Final Oral Exam — Workspace Index

Everything needed to complete the ET4278 final exam project for the paper:
**Shettigar & Pavan, "Design Techniques for Wideband Single-Bit Continuous-Time ΔΣ Modulators With FIR Feedback DACs," IEEE JSSC, Dec 2012** (DOI 10.1109/JSSC.2012.2217871).

This folder was organised so a fresh agent can execute the whole project. To launch it, paste `FINAL_AGENT_PROMPT.md` into a new session started **in this directory** (so `CLAUDE.md` auto-loads).

## Files
| File | What it is |
|---|---|
| `CLAUDE.md` | Auto-loaded rules for the executor agent (hard constraints, paper facts, deliverables). |
| `00_INDEX.md` | This index. |
| `01_paper_analysis.md` | **The paper, fully analysed** — issues, techniques, architecture walk-through, and **every figure** (`figures/figNN_*`) described for individual analysis. FIR coefficients (Eq. 1). |
| `02_exam_requirements_and_grading.md` | The official **50-point rubric**, deliverables, submission rules, Q3 prompts. |
| `03_presentation_structure.md` | **Slide-by-slide** plan against the `.pptx` template (numbering rules, what goes on each slide, which figure pairs with which). |
| `04_matlab_requirements.md` | **MATLAB build spec** — every model block, what to plot, how to scale to match the paper, the knobs, reproduction targets, iteration plan. (No code — rules only.) |
| `05_theory_reference.md` | Course **lingo/glossary + key equations + concept map** mapped to the paper (use the course's voice). |
| `06_literature_review.md` | **Q5/Q6/Q7**: strengths/weaknesses vs SoTA, extended comparison table, proposed improvements to verify. |
| `07_references_ieee.md` | **PDF links** (TU Delft IEEE proxy) for the paper, its 17 references, the thesis, and post-2012 related work. |
| `08_coding_practices.md` | The student's **existing MATLAB conventions** to match (no delsig, Kaiser(20), hand-rolled SNR, ...). |
| `09_reference_notes.md` | **Precise detail mined from the downloaded PDFs** — jitter/metastability/weak-nonlinearity/assisted-opamp models, the **compensation closed-form** to derive E(z), and the extended comparison table with exact numbers. |
| `FINAL_AGENT_PROMPT.md` | **Copy-paste prompt** to launch the executor agent. |
| `refs/` | **13 downloaded reference PDFs** (the paper + [7][13][14][15][6] + Sukumaran/Jain/Billa/Theertham/Zhang-Temes/Pavan-Baskaran + IIT-Madras thesis). |
| `figures/` | All 30 figures + 2 tables as **individual images** (`figNN_*`, `tableI/II_*`), plus full-page renders (`pages/`) and raw extracts (`embedded/`). See `figures/FIGURE_MAP.md`. |
| original PDFs | `Design_Techniques_..._FIR_Feedback_DACs.pdf` (the paper), `Final oral exam requirement 2026.pdf`, `Final oral exam templete 2026.pdf/.pptx`. |

## The 50 points at a glance
Q1 issues+techniques (5) · **Q2 MATLAB reproduction (15)** · Q3 non-idealities (5) · Q4 circuit blocks (5) · Q5 strengths/weaknesses (5) · Q6 comparison/extend table (5) · Q7 improvements + verify (5+5). Project = 50 % of the grade.

## Paper in one line
A 1-bit quantizer with an **8-tap semi-digital FIR feedback DAC** gets multi-bit-like jitter tolerance and loop-filter linearity from a 2-level (inherently linear) DAC; the FIR's group delay is cancelled by a mostly-analog bandpass **compensation path**. 3.6 GS/s, 90 nm, 36 MHz BW, 70.9 dB SNDR, 83 dB DR, 15 mW, 72.7 fJ/lvl.

## Status / what's left
Done: paper read + all figures extracted, theory + coding conventions mined, related work found + **13 reference PDFs downloaded to `refs/` and mined into `09_reference_notes.md`**, all planning docs written.
To do (executor): write the MATLAB (`practical-exam/matlab/`), run + verify against `figures/`, fill the `.pptx`, then the user emails both to `yliu73@tudelft.nl` ≥24 h before the slot.
