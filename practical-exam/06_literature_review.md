# Literature Review — strengths/weaknesses, comparison, improvements

Covers exam **Q5** (strengths/weaknesses vs SoTA), **Q6** (compare + extend Table II), **Q7** (propose + verify improvements). Citations/links in `07_references_ieee.md`.

---

## 1. Strengths & weaknesses of the paper's techniques (Q5)

| Technique | Strength | Weakness / cost | Verdict vs today |
|---|---|---|---|
| 1-bit ADC + **FIR feedback DAC** | multi-bit-like jitter tolerance + relaxed loop-filter linearity, with a 2-level **inherently linear** DAC (no DEM/calibration); simple low-power quantizer | adds **group delay** → needs loop compensation; FIR taps add area/routing | **Still the dominant idea** — adopted widely after 2012 (audio, biomedical, RF). Validated. |
| **Analog FIR-delay compensation path** (E(z)+H₁(s)) | restores target NTF; bandpass shape keeps the path's own jitter/offset out of band; mostly analog (no extra fast summer) | complex to design (impulse-invariance + finite-BW); extra opamp (I₅) + matched replicas; sensitive to RC spread | partly **superseded** by simpler digital ELD compensation (Zhang–Temes '15) and dual-RZ/R2O DACs (Theertham '22). |
| **First FIR tap = 0** (metastability) | ~40 dB floor recovery for ~free | costs one tap of filtering depth | clean, still used. |
| **RZ DAC ELD compensation** | no power-hungry summer around quantizer | RZ adds jitter sensitivity on that path | standard practice. |
| **CIFB + input feed-forward, active-RC, assisted opamp** | decoupled fast/precise paths, small caps, low opamp power | STF peaking (Fig 9) → needs input pre-filter; many DAC feed-ins | typical for high-speed CT ΔΣ. |
| **High-initial-current comparator latch** | beats CML power at 3.6 GS/s | custom timing | fine. |
| **Digital ISI correction (post-facto)** | recovers ~3–4 dB SNDR, confirms ISI origin | done off-line in software, single fixed α, not adaptive/on-chip | the obvious **improvement target** (make it in-loop/adaptive, or use dual-RZ/R2O). |

**Does the paper solve its stated problems?** Yes for jitter, loop-filter linearity, and DAC linearity/DEM. The **residual weakness is ISI-induced HD2** (limits measured SNDR to 70.9 dB vs ~95 dB SQNR target), only fixed in post-processing — this is where it's beaten by newer work.

---

## 2. Comparison & extended table (Q6)

The paper's **Table II** (`figures/tableII_performance_comparison.png`) compares This Work vs [1] Mitteregger '06, [2] Kauffman '11, [3] Dhanasekaran '09, [4] Malla '08, [5] Park–Perrott '09, [6] Bolatkale '11. **Extend it** with post-2012 designs. Numbers below were read from each paper's performance-summary table (PDFs in `refs/`; details in `09_reference_notes.md` §C). FoM_W = Walden fJ/conv-step, FoM_S = Schreier dB; "~" = derived from P/BW/DR.

| Design (year) | Tech / Vdd | f_s | BW | DR | pk SNDR | Power | FoM_W | FoM_S | Key feature |
|---|---|---|---|---|---|---|---|---|---|
| **This work '12** | 90 nm /1.2 V | 3.6 GS/s | 36 (25) MHz | 86@25M | 71@36M; 73.3@25M | 15 mW | 72.7 (79.4) | 176.8 (178.2) | 1-bit, **8-tap FIR + analog ELD comp** |
| Bolatkale '11 [6] | 45 nm /1.1+1.8 V | 4 GS/s | **125 MHz** | 70 | 65 | 260 mW | ~400 | ~157 | **4-bit** CT, cap-FF, direct ELD (no FIR) |
| Sukumaran '14 | 180 nm /1.8 V | 6.144 MS/s | 24 kHz | 103 | 98.2 (A:101.5) | 280 µW | 88 | 182.3 | 1-bit FIR audio + ISI cal + dither |
| Zhang-Temes '15 | 65 nm /1.0 V | 1.2 GS/s | 15 MHz | 79.4 | 74.3 | 6.96 mW | 58.6 | ~172.7 | **2-bit, 3-tap FIR + digital ELD comp** + DWA |
| Jain-Pavan '18 | 65 nm /1.4 V | 6 GS/s | 60 MHz | 76 | 67.6 | 13.3 mW | **56.5** | 172.5 | 1-bit **2× time-interleaved FIR** |
| Billa '20 | 180 nm /1.8 V | 6.144 MS/s | 24 kHz | 104 | 100.9 | 265 µW | — | 180.5 | **1-X FIR-MASH**, chopping |
| Theertham '22 | 180 nm /1.8 V | 48 MS/s | 250 kHz | 104 | 103.2 | 17.7 mW | ~300 | 174.7 | 1-bit, 12-tap FIR + **dual return-to-open DAC** + chop |
| Pavan-Baskaran '18 | 65 nm /1.2 V | (audio) | 24 kHz | — | 98.6 | 260 µW | — | 178.3 | tutorial: 1-bit + FIR + chopping (180→65 nm) |
| Mokhtar/Ortmanns '22 | 28 nm /0.9 V | (2 MS/s) | — | — | (97 dB SFDR) | — | — | — | DAC-calibration-free incremental ΔΣ — *verify numbers in PDF* |
| Runge/Gerfers '21 | 22 nm FDSOI | (18 MS/s) | — | 76 SNDR | 76 | — | — | — | shared FIR DAC + Gm-VC filter — *verify numbers in PDF* |

Plot the standard **energy plot** (FoM_Schreier or P/Fnyq vs SNDR/BW) and place this work among the newer points. Use Murmann's ADC survey [16] for the SoTA cloud — Figs 23/24 in the paper are exactly that survey up to 2012.

---

## 3. Proposed improvements + how to verify in MATLAB (Q7)

Pick 1–2, draw the updated architecture, and verify the gain in MATLAB.

1. **Make ISI correction in-loop / adaptive (or use a dual-RZ / return-to-open DAC).**
   - *Why:* the paper's HD2 (the SNDR limiter) is only removed off-line with a fixed α. Adams' dual-RZ [17] or Theertham's R2O DAC [JSSC '22] removes ISI at the circuit level; an adaptive digital α tracks process/temperature.
   - *Verify:* extend `FIRDSM_isi_correction.m` — sweep α to null HD2 across amplitudes/frequencies (paper used one α); or model an RZ main DAC and show HD2 vanishes with the jitter trade-off. Target: reproduce/beat Figs 29/30 (HD2 −15 dB, peak SNDR → 74+ dB).

2. **More FIR taps / time-interleaved FIR feedback (Jain–Pavan '18).**
   - *Why:* more taps → deeper jitter filtering and smaller steps, but more group delay; time-interleaving the FIR gets the taps without the full delay penalty.
   - *Verify:* sweep `Ntap` 8→16/24 and show the jitter floor (Fig 2/26) drop and the SQNR vs the compensation difficulty; quantify the broad optimum.

3. **Chopping "for free" with the FIR DAC (Pavan, TCAS-II '18) for 1/f noise.**
   - *Why:* a precision/low-frequency variant; chopping at f_ch = fs/(2N) reuses the FIR structure.
   - *Verify:* add a 1/f noise source to I₄ and show chopping moves it out of band; report in-band noise before/after.

4. **Digital ELD compensation instead of the analog compensation path (Zhang–Temes '15).**
   - *Why:* the analog E(z)+H₁(s) path is the most complex/fragile block; a digital ELD scheme is simpler and process-robust.
   - *Verify:* replace the H₁(s) path with a digital correction term and show the same NTF (Fig 8) with fewer analog states.

For each, the slide needs: **updated block diagram** + **before/after MATLAB plot** + a **one-line quantified conclusion** (e.g. "peak SNDR 70.9 → 74.3 dB", "jitter floor −X dB", "1/f corner moved below f_b").

---

## 4. The one-paragraph "is this paper still relevant?" answer (for the Summary slide)

> In 2012 this paper made the case that single-bit CT ΔΣ could compete with multi-bit at tens-of-MHz bandwidths by borrowing the multi-bit feedback waveform via an FIR DAC. The idea proved durable: FIR feedback is now standard across audio, biomedical and RF CT ΔΣ designs, and the same group (Pavan et al.) extended it with time-interleaved FIR, FIR-MASH, chopping, and return-to-open DACs. Where the original is now beaten is in the *details it left open*: its analog FIR-delay compensation is complex and its ISI correction is off-line — both addressed by simpler digital-ELD and circuit-level dual-RZ/R2O techniques in later work. So the architecture is foundational and still cited, but a 2025 redesign would keep the FIR DAC and replace the compensation/ISI handling.
