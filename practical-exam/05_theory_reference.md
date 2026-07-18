# Theory Reference — ET4278 lingo mapped to the paper

Distilled from `tud-notes/Q4/ET4278/Over-Sampled Data Converters.md` and the lecture set. Use **this vocabulary** in the slides and oral so it matches the course. Math is Unicode (no LaTeX). The course even has a dedicated **guest lecture by Shanthi Pavan on FIR-DAC feedback** (`FIR_DAC_Shanthi.pdf`) — i.e. the paper's own author taught this; lean on that framing.

---

## 1. Glossary (course phrasing → meaning, and where it appears in the paper)

| Term | Course meaning | In this paper |
|---|---|---|
| **OSR** | OSR = fs/(2·f_b) = fs/F_N | 50 (3.6 GHz / 72 MHz) |
| **Quantization noise q** | uniform in ±Δ/2, q²_rms = Δ²/12; white for N>5 bits | 1-bit q is highly correlated → tones/metastability matter |
| **SQNR** | 6.02·N + 1.76 dB (full-scale sine) | design target ~95 dB |
| **SNR / SNDR / DR** | SNR (noise only), SNDR (incl. distortion/HD2,HD3), DR (input range to SNR=0) | 76.4 / 70.9 / 83 dB @ 36 MHz |
| **NTF** | q→output transfer; high-pass; nth-order slope 20n dB/dec | 4th-order, OBG 1.5, 2 optimised zeros (Fig 8) |
| **STF** | input→output transfer | peaks +12 dB from feed-forward (Fig 9) |
| **OBG (out-of-band gain)** | high-f value of |NTF|; aggressive NTF = better shaping, lower MSA | **1.5** (Lee's rule for 1-bit) |
| **MSA** | max stable amplitude (states stay bounded) | scaled so first-order path saturates last |
| **Lee's rule** | ‖NTF‖∞ ≲ 1.5 for a stable 1-bit loop | the reason OBG=1.5 (not higher) |
| **CIFB / CIFF** | chain of integrators feedback / feed-forward; FB first integrator carries full signal, FF carries only shaped noise | modified CIFB + input feed-forward (Figs 5,7) |
| **NTF-zero optimisation / resonator** | local feedback moves NTF zeros off DC to ±f_notch; optimum f_notch = f_b/√3 (~3 dB gain) | two optimised zeros (in-band notches, Fig 8) |
| **CT vs DT** | CT loop filter H(s) analog; only quantizer/sampler at fs; DAC reconstructs (ZOH) | CT, active-RC integrators |
| **Impulse invariance / loop mapping** | choose H(s) so sampled open-loop impulse response = target H(z) | coefficients set "using impulse invariance and accounting for finite opamp bandwidths" |
| **NRZ / RZ / HRZ DAC** | NRZ full period (least jitter-sensitive *pulse*, max ELD); RZ half period (kills ISI, more jitter-sensitive) | main+comp DACs NRZ; ELD DAC₀ is RZ |
| **ELD (excess loop delay)** | DAC/comparator latency → extra loop phase → NTF degrades / instability; fix with a fast direct path (extra DAC) | FIR group delay is the big ELD; RZ DAC₀ + compensation path fix it |
| **Clock jitter** | feedback charge ∝ ∫i_DAC dt depends on edge timing; jitter injects in-band noise; worst for full-scale NRZ; error e[n] ≈ (V_out[n]−V_out[n−1])·Δt_n/Ts | FIR makes steps small → e[n] small (Figs 2,26,27) |
| **Comparator metastability** | data-dependent regeneration delay (signal-dependent gain κ) → DAC pulse-width error | first tap zeroed to dodge it (Fig 4) |
| **ISI** | asymmetric DAC rise/fall → energy per pulse depends on transition pattern → even-order distortion + noise folding; unique to CT | residual HD2 + SNDR kink (Figs 17,21); corrected digitally (Figs 28-30) |
| **DAC element mismatch / DEM / DWA** | multi-bit DAC mismatch → INL (not shaped); DEM/DWA randomise/rotate to shape it (∝ 1−z⁻¹) | avoided entirely: 1-bit DAC is 2-level-linear, **no DEM needed** |
| **Multi-bit vs single-bit** | +6 dB/bit; multi-bit = jitter/linearity friendly but needs DEM + power; 1-bit = simple, linear DAC, but jitter/linearity hungry | paper gets multi-bit *behaviour* from 1-bit + FIR DAC |
| **Assisted opamp** | inject a replica of the integrator input current at the opamp output → less opamp burden for a given speed/power [15] | used on I₁, I₂ (Fig 10) |
| **Decimation / sinc (CIC)** | digital filter removes out-of-band shaped noise then downsamples; sinc^L, notches at k·fs/N | required for Q2.4 |
| **Thermal / kT/C noise** | input-referred, flat (un-shaped) in band; v²_inband = S_n·f_b | sets the DR floor |
| **FoM** | Walden FoM_xx = P/(2·BW·2^((xx−1.76)/6.02)); Schreier = DR + 10log(BW/P) | 72.7 fJ/lvl, 176.8 dB |

---

## 2. Key relations (Unicode, as the notes write them)

- In-band quant. noise, order L: n²_rms ≈ (π^(2L)/(2L+1))·q²_rms / OSR^(2L+1). → +1.5 ENOB/octave (1st), +2.5 ENOB/octave (2nd), slope 20L dB/dec.
- NTF zero placement: f_notch = tan⁻¹(√d₁)/(2π) ≈ √d₁/(2π); optimum **f_notch = f_b/√3**.
- 1-bit input-stage distortion: HD₃ = (h₁/h₃)·(2/Â²); HD₃[dB] = 20·log₁₀(that).
- Jitter error per cycle: e[n] ≈ (V_out[n] − V_out[n−1])·Δt_n/Ts → **proportional to the feedback step height** (the whole point of the FIR DAC).
- CT integrator step (sub-stepped sim): ω·Ts/nr_steps per sub-step; quantise once per clock.
- Thermal: v²_inband = v²_total/OSR → −3 dB per OSR doubling.
- Decimation sinc: |H₁(f)| = |sin(πNf)/(N·sin(πf))|; sinc²: H₂ = H₁².
- Multi-bit jitter advantage: a 4-bit modulator tolerates ≈ 15× more rms white jitter than a 1-bit design (steps ~1/15 of full scale) — the FIR DAC closes most of this gap (Fig 27).

---

## 3. Concept map — the paper's topics in course terms

- **Single-bit vs multi-bit (guest lecture's "central question"):** "how to get multi-bit benefits (jitter tolerance, relaxed loop filter) while keeping single-bit benefits (low-power ADC, inherently linear DAC). Answer: 1-bit quantizer + FIR feedback DAC." This *is* the paper.
- **FIR feedback DAC:** "the 1-bit output v is filtered by F(z) … output v₁(t) is a multi-level, smoothed staircase that closely tracks u(t)." Semi-digital → "tap mismatch only changes the FIR coefficients (a linear filter) → does NOT create DAC non-linearity." Tap-count: "broad minimum ≈ 10–18 taps" (paper uses 8).
- **Jitter & NRZ:** "DAC clock jitter modeled as additive error injected at the DAC output: e[n] ≈ (V_out[n]−V_out[n−1])·Δt_n/Ts" → small steps ⇒ small error.
- **Metastability:** quantizer = "comparator modeled as a signal-dependent gain κ"; latency → ELD → fixed here by zeroing the first FIR tap.
- **ELD:** "real DAC/comparator latency delays the feedback pulse → extra loop phase → degrades NTF … Compensate by adding a fast direct feedback path around the quantizer (extra DAC tap)." FIR group delay is the dominant ELD; the paper's compensation path + RZ DAC₀ are the fix.
- **ISI:** "asymmetric rise/fall edges … energy per pulse depends on the transition pattern" → "even-order distortion + noise folding"; "unique to CT." Mitigation in course = RZ; in paper = differential cancellation + digital correction.
- **CIFB & anti-aliasing:** "CIFB … high-speed path around the quantizer decoupled from the high precision path"; feedback loop filters give better alias rejection (−40 dB/dec).
- **OBG ≈ 1.5:** "Lee's rule: stable 1-bit limits ‖NTF‖∞ ≲ 1.5; multi-bit allows larger." The paper sits exactly at this 1-bit limit.

---

## 4. Lecture / attachment index (where to find each topic)

**Most relevant lectures for this paper:**
- `FIR_DAC_Shanthi.pdf` — **guest lecture by the paper's author** on FIR-DAC feedback (read first).
- `2026_Lecture_week4_Tuesday.pdf` — CIFB/CIFF, CT↔DT (impulse invariance), ELD, STF peaking, jitter.
- `2026Lecture_week5_Tursday.pdf` — multi-bit, DAC mismatch, DEM/DWA, input-stage non-linearity, MASH.
- `2026Lecture_week6_Tuesday.pdf` — jitter/ISI/waveform asymmetry (even-order distortion), dither, RZ mitigation.
- `Lecture_week3_Friday_Practical_MOD2.pdf` — CT sim of a DT modulator, ω mapping, DAC-ISI, scaling, NTF-zero optimisation.

**Useful attachment figures** (`tud-notes/.../attachments/`): `GPfir_fir_dac_feedback_structure.png`, `GPfir_3rd_order_ciffb_dual_firdac.png` (FIR-DAC structures), `L3_isi_asymmetric_dac-51.png`, `L4_stf_ff_vs_fb.png`, `L4_ntf_zeros_optimized.png`, `L4_ct_sd_ct_dt_loop.png`, `L6_waveform_asym_imd.png`, `L5_dac_mismatch_inl.png`, `L5_dwa_rotation.png`.

> Note: the guest-lecture FIR-DAC example is a **3rd-order CIFF-B, ~12-tap, OSR-128 audio** illustration; the JSSC paper is a **4th-order, 8-tap, OSR-50, 36 MHz** wideband design. Same principle, different operating point — say so if asked.
