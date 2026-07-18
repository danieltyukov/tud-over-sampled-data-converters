# Final Oral Exam — Requirements, Deliverables & Grading

Source: `Final oral exam requirement 2026.pdf` (the official rubric) + `Final oral exam templete 2026.pptx`. This file is the contract: everything we produce must map to a numbered item here.

---

## 1. What the exam is

Study + simulate a **state-of-the-art ΔΣ modulator** from an assigned paper; show you understand the architecture and its design considerations; reproduce the paper's key results in **MATLAB**; present and defend it orally.

**Our paper:** Shettigar & Pavan, JSSC 2012, single-bit CT ΔΣ with FIR feedback DAC (see `01_paper_analysis.md`). Confirmed/assigned (TA Yang Liu, `yliu73@tudelft.nl`).

## 2. Grade weighting

| Component | Weight |
|---|---|
| Project (this presentation + MATLAB) | **50 %** |
| General course questions at the oral | 20 % |
| Weekly assignments (already done) | 30 % |

The project's 50 % is scored out of the **50 points** below.

## 3. The 50-point rubric (what must be produced)

| Q | Points | Requirement | Our mapping |
|---|---|---|---|
| **Q1** | 5 | Identify the **issues** addressed by the paper and the **main techniques** used. Support with figures/block diagrams. | `01_paper_analysis.md` §1–2; Figs 1, 5, 7 |
| **Q2** | **15** | **Simulate the architecture in MATLAB and reproduce the paper's main results.** Show paper result *and* your result side by side. Sub-items below. | `04_matlab_requirements.md`; Figs 2,3,4,8,9,21,22,26,27,29,30 |
| Q2 a | — | **Enable/disable** the proposed techniques; quantify & compare. | FIR DAC on/off; compensation on/off; first-tap-zero on/off; ISI-corr on/off |
| Q2 b | — | **Scale the voltage levels** to match the paper; state assumptions. | full-scale = ±1 internal, integrator swings scaled < ~0.45–0.5 |
| Q2 c | — | **Add thermal noise**, scale the **output spectrum** to match; plot spectrum **before & after decimation**; include **transient waveforms**. | noise budget to hit DR≈83 dB; sinc/CIC decimation |
| **Q3** | 5 | Introduce circuit **non-idealities** and show their effect: finite **amp gain & BW**, **DAC mismatch**, **ELD**, **clock jitter**, **integrator non-linearity**. | one slide each; see Q3 notes below |
| **Q4** | 5 | Describe the **circuit implementation** of the blocks (DAC, amplifier, comparator, sample/hold). 1 block/slide; for SC draw the phases. | `01_paper_analysis.md` §4; Figs 10,12,13,16,18 |
| **Q5** | 5 | Identify main techniques; discuss **strengths/weaknesses vs current state of the art** (table). | `06_literature_review.md` |
| **Q6** | 5 | **Compare** techniques to modern ΔΣ modulators; **extend Table II** with other notable designs. | `06_literature_review.md` + `07_references_ieee.md` |
| **Q7** | 5 + 5 | **Propose improvements** (5) and **verify them in MATLAB** (5). Include an updated architecture/circuit drawing. | `06_literature_review.md` §improvements; verify in MATLAB |

## 4. Q3 non-idealities — what the template asks on each slide

Each Q3 slide has a plot box + bullet prompts. We must answer the bullets:

- **Q3.1 Finite amplifier gain & BW** — "What gain & BW does the paper report? What did you use? How does the non-ideality impact performance?" → Paper: **DC gain ≈ 55 dB, UGB ≈ 2 GHz** (Fig 12). Model leaky integrator (DC gain) + 1-pole opamp (BW); show in-band noise rise / NTF leakage.
- **Q3.2 DAC mismatch** — "How did you choose the mismatch? Impact?" → Subtlety for a **single-bit** design: the 2-level DAC itself has no level mismatch, but the **8-tap FIR DAC has unit-element (resistor) mismatch** → perturbs F(z) coefficients (a *linear* change), changing the realised NTF slightly, **not** adding harmonic distortion. Model σ ≈ 0.5–1 % per tap; show F(z) zeros shift → jitter-null shift (Fig 26).
- **Q3.3 ELD** — "How did you model it? Impact?" → add a fractional-clock delay in the quantizer→DAC path; show NTF degradation/instability; show the RZ DAC₀ compensation restoring it.
- **Q3.4 Clock jitter** — "How did you model it? Impact? Any jitter-reduction technique?" → white + sinusoidal-FM jitter on the sampling/DAC edges; show in-band noise vs jitter; show the **FIR DAC's jitter filtering** (Figs 2, 26, 27).
- **Q3.5 Integrator non-linearity** — "What non-linearity does the paper report? Which integrator dominates? How modelled? Impact?" → input integrator I₄, weak cubic i = G_m·v_d − G₃·v_d³ (Fig 3, Pavan [14]); show in-band floor rise from out-of-band-noise demodulation.

## 5. Final deliverables (hard requirements)

1. **Presentation file** following `Final oral exam templete 2026.pptx` — slides numbered, **do not change slide order or delete slides**; if a question needs >1 slide, **duplicate** and suffix the number (Q2.6A, Q2.6B, …); put your **answer/conclusion on every slide**.
2. **MATLAB code**, submitted **separately** from the slides.
3. **Submit by email to `yliu73@tudelft.nl` at least 24 h before the slot** (missing this cancels the exam).
4. Bring the presentation **and a laptop** to the oral (the simulated results are run/discussed live).

## 6. The lecturer's stated emphasis (what they actually grade you on)

From the lecturer's brief:
- Be able to **analyze the plots, reproduce them, show understanding**, and **see how they can be malleably changed** — i.e. you must be able to *vary a parameter live and predict/explain the result*, not just show a static match.
- **Literature review / comparison** of the chosen paper: how the design can be improved, the primary points, whether there are **better topologies/approaches in newer papers**.
- A clear **PowerPoint structure** (follow the template).
- The paper is a **sigma-delta ADC** (the primary ADC architecture of the course) — expect general ΔΣ questions too.

> Practical consequence for the MATLAB: every script must expose its key parameters (fs, OSR, OBG, tap count, jitter, gain, ELD, mismatch, …) as variables at the top so a value can be changed during the oral and the effect shown immediately. See `04_matlab_requirements.md`.

## 7. Oral-exam general-question readiness (20 %)

Be ready to answer course-level questions tied to the paper's topics (use `05_theory_reference.md`): SQNR vs OSR vs order; NTF/STF & Lee's rule; CIFB vs CIFF; CT↔DT mapping & impulse invariance; NRZ/RZ DAC & ISI; ELD & compensation; clock jitter (white vs accumulated); comparator metastability; single-bit vs multi-bit; DEM/DWA; MASH; decimation/sinc filters; thermal/kT-C noise; FoM definitions.
