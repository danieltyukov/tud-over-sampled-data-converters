# Course theory & canonical wording — ET4278 Over-Sampled Data Converters

Use this for **general ΔΣ questions** (the 20% oral component) and to phrase every answer in the course's own words. Equations in Unicode. Ordered by concept. The last section is ready-made Q&A.

---

## 1. Fundamentals

- **ADC chain:** anti-alias filter → sampler (Fs) → quantizer (Vref) → digital post-filter → sample-rate converter. Post-filter + rate converter = the **decimation filter**.
- **Nyquist:** BW ≤ Fs/2; sampling repeats the spectrum at n·Fs ± fin. A tone at Fs − fin aliases onto fin. Oversampling **relaxes the anti-alias filter** (gentle roll-off).
- **Quantization noise:** uniform error in ±Δ/2 → q²_rms = Δ²/12. For a full-scale sine, N-bit: **SNR = 6.02·N + 1.76 dB** (+6 dB per bit). For N > 5 bits, q ≈ white.
- **OSR = Fs/(2·fb) = Fs/FN.** In-band noise (no shaping) = q²_rms/OSR → **−3 dB per doubling of OSR** (+0.5 ENOB).
- **Feedback insight:** for y = q + A(x−y), y = x·A/(A+1) + q/(A+1) → large loop gain suppresses q. Foundation of ΔΣ.

---

## 2. Noise shaping — 1st, 2nd, high order

- **1st-order:** y(z) = z⁻¹·x + (1−z⁻¹)·q. **STF = z⁻¹** (delay, |STF|=1), **NTF = 1−z⁻¹** (high-pass, **zero at DC**, +20 dB/dec). In-band noise = (π²/3)·q²_rms/OSR³ → **−9 dB per 2× OSR (+1.5 ENOB)**. Pathologies: tonal noise, dead zones → rarely used alone.
- **2nd-order:** NTF = (1−z⁻¹)² (+40 dB/dec). In-band noise = (π⁴/5)·q²_rms/OSR⁵ → **−15 dB per 2× OSR (2.5 bits/oct)**. Pure 2nd-order is **unstable** — needs a stabilising zero (coefficient a; typical a=1-2).
- **n-th order:** NTF slope = 20·n dB/dec (4th → **80 dB/dec**). Higher order + optimised zeros = steeper SQNR-vs-OSR, but stability gets harder (no formal proof above 1st order — designed empirically).
- **This paper:** 4th-order, so 80 dB/dec shaping, two optimised zeros, OBG 1.5.

---

## 3. Stability & Lee's rule

- **Stability (z-plane):** all poles inside |z| = 1 (s-plane: Re(s) < 0). Pole at z=1 → DC oscillation; z=−1 → Fs/2; z=j → Fs/4.
- **Quantizer as signal-dependent gain κ:** κ = output/input power, **shrinks as internal swing grows** → poles drift toward/out of the unit circle. Root locus shows the migration.
- **Maximum stable amplitude (MSA):** largest input keeping states bounded. Aggressive NTF (high OBG) → better shaping but **lower MSA**. Fundamental trade-off.
- **Lee's rule (design heuristic):** keep **|NTF|max ≲ 1.5** for a stable single-bit loop. Multi-bit allows larger OBG (more stable) → push order/BW harder. *This paper uses OBG = 1.5 — the 1-bit limit.*
- **Recovery:** 1st-order recovers from overload unconditionally; ≥2nd-order is *conditionally* stable → add a **limiter/clamp** to guarantee recovery (sets κ_min).

---

## 4. Topologies: CIFB vs CIFF, scaling, resonators

- **CIFB (chain of integrators, feedback):** DAC feeds every integrator input. First integrator is **low-pass of the input → carries full signal swing**. STF mild low-pass (no peaking) → good anti-aliasing.
- **CIFF (chain of integrators, feed-forward):** integrator outputs fed forward to the quantizer, single outer DAC. First integrator is **high-pass → carries only shaped noise, no signal → relaxed first-opamp linearity/swing**. Cost: **STF peaking** (~+6 dB).
- **Equivalence:** same NTF; c1=a2, c2=a1.
- **This paper = modified CIFB + input feed-forward:** it takes CIFB's decoupled fast/precise paths *and* borrows the feed-forward small-swing/small-cap benefit — which is why it also inherits STF peaking (Fig 9, slide 10).
- **Coefficient scaling:** split integrator gains bi → H'(z) = (Πbi)·H(z), **NTF/STF unchanged for a 1-bit quantizer** (sign block is scale-invariant). Choose bi to fit swings in the supply. Multi-bit is harder (references may also scale).
- **Resonator (local feedback d):** moves NTF zeros off DC to a notch at f_notch ≈ √d/(2π); optimal single notch at **fb/√3** → ~+3 dB SQNR, costs some MSA. This paper uses two resonator gains g1, g2 → two notches.

---

## 5. Continuous-time (CT) ΔΣ — the paper's domain

- **Design by impulse invariance:** choose H(s) so the sampled open-loop impulse response matches the target DT loop: L⁻¹{H(s)·H_DAC(s)}|_{t=nT} = Z⁻¹{H(z)}.
- **CT advantages:** (i) loop filter gives **implicit anti-alias filtering** (no separate AAF); (ii) **resistive input** → easy to drive, no input kT/C sampling; (iii) relaxed sampler/opamp speed (sampling is inside the loop → errors shaped).
- **CT penalties (the three to name):**
  1. **Excess loop delay (ELD):** DAC/comparator latency adds loop phase → NTF degrades, can go unstable (~>0.25 Ts). Fix: **direct/fast feedback tap around the quantizer** (here an **RZ DAC0**).
  2. **Clock jitter:** fed-back charge per cycle depends on **DAC edge timing** → jitter modulates feedback → injects in-band noise. **Dominant CT ΔΣ limitation.** e[n] ≈ (v[n]−v[n−1])·Δt/Ts, ∝ step height.
  3. **STF peaking (CIFF/feed-forward):** out-of-band lift lets blockers through → overload. Fix: direct input feed-forward c0, or pre-filter.
- **DAC pulse shapes:** NRZ (full period, least jitter-sensitive, most ELD), RZ (half period, more jitter-sensitive), HRZ. Jitter step-variance: **NRZ ≈ 2.8, RZ ≈ 8.0, RZ+HRZ ≈ 24.1** → design uses NRZ for main + FIR, RZ only for the small ELD DAC0.

---

## 6. NRZ/RZ, ISI, waveform asymmetry (the paper's SNDR limiter)

- **ISI (intersymbol interference):** a real CT DAC has **unequal rise/fall** → charge per pulse depends on the **transition pattern**, not just the bit. `1010` ≠ `1100` in fed-back area. CT-specific (DT settles fully → immune).
- **Effect:** code-dependent, **even-order (2nd-harmonic) distortion + noise folding** (out-of-band shaped noise intermodulated in-band). Transition density is amplitude-dependent → distortion turns on at a level → the **SNDR-vs-amplitude kink** (Fig 21).
- **Fixes:** **RZ** (every symbol sees identical edges → code-independent charge), current-steering, symmetric/**dual-RZ / return-to-open (R2O)** DAC (Theertham 2022), differential to cancel even order, or digital ISI correction (this paper, off-line).
- **Why HD2 not HD3:** HD2 = even-order = waveform asymmetry (ISI); HD3 = odd-order = symmetric nonlinearity (e.g. integrator cubic).

---

## 7. Single-bit vs multi-bit; DEM/DWA

- **Multi-bit pros:** +6.02 dB/bit; κ ≈ 1 → aggressive NTF, smaller OSR; **small feedback step → low jitter + relaxed loop-filter linearity**; lower OOB NTF gain → more stable.
- **Multi-bit cons:** quantizer power/area ~exponential in bits; comparator offset tightens; **feedback-DAC element mismatch → INL → un-shaped harmonic distortion** at the input node → needs **DEM**.
- **Single-bit pros:** trivial ADC, inherently linear 2-level DAC, **no DEM**, low ELD → higher fs.
- **Single-bit cons:** needs higher OSR; **full-scale NRZ feedback → worst jitter + metastability + loop-filter linearity demand**; Lee's rule caps OBG ≈ 1.5.
- **DEM / DWA:** rotate/scramble unit-element selection so mismatch error is 1st-order high-passed out of band (∝ 1−z⁻¹, 20 dB/dec). **DWA** advances a pointer through the array (needs memory). Gotcha: **tonal at small/DC inputs**.
- **Key single-bit insight (this paper):** the FIR DAC gives multi-bit's small-step feedback *without* multi-bit's DAC mismatch/DEM burden — because a semi-digital FIR's tap mismatch is a *linear coefficient error*, not INL.
- **1-bit input-stage nonlinearity is NOT loop-suppressed:** HD3 = (h1/h3)·2/Â²; the error e = x−y carries the full large signal. Multi-bit shrinks the error amplitude ê ≈ 2/(n−1).

---

## 8. MASH, bandpass, decimation, noise, dither

- **MASH:** cascade stable low-order stages; digitally cancel stage-1 quantization noise (H1 = STF1, H2 = NTF1) → high-order shaping (2-2 → 4th-order, 80 dB/dec) with **unconditional stability**. Limited by **noise leakage** from finite opamp gain (α = 1−1/A) → residual (2/A)(1−z⁻¹)q1 → needs high 1st-stage DC gain. (Billa 2020 = FIR-MASH.)
- **Bandpass:** z⁻¹ → −z⁻² moves the NTF notch DC → Fs/4 (poles at ±j) → digitize IF/RF directly; SNR over the passband.
- **Decimation / sinc:** box-car = sinc¹, H(z) = (1/N)(1−z⁻ᴺ)/(1−z⁻¹), notches at k·Fs/N. Cascade → sinc^k (CIC). Rule: **sinc^(order+1)** so the filter falls faster than the noise rises. (This paper: sinc⁵ for 4th-order.)
- **Thermal / kT/C noise:** enters at the input → **not shaped** → sets the SNR floor, −3 dB/oct from OSR, dominated by the **first integrator's kT/C = 2kT/Cs**. Noise added later is shaped (2nd-int input 20 dB/dec, quantizer 40 dB/dec) → budget the first stage.
- **Idle tones & dither:** low-order 1-bit + small DC input → correlated error → discrete in-band **tones**; f_tones = n·Fs·|Voff|/(2Δ). **Dither** (~Δ/4 at the quantizer input) whitens the quantizer; it is **NTF-shaped** (y/d = NTF) → small in-band cost.
- **Loop-internal distortion is suppressed by the loop gain at that frequency** (e.g. HD3 = 14.6 − 113 = −98.4 dB). Input-stage and feedback-DAC errors are the exceptions (not shaped).

---

## 9. FIR-DAC feedback — the guest-lecture framing (this paper's core)

- **Idea:** 1-bit output filtered by an N-tap FIR F(z) before the DAC → **multi-level, smoothed staircase** v1(t) that tracks vin. Combines 1-bit simplicity with multi-bit-like feedback.
- **Jitter:** error ∝ step height; FIR shrinks steps → **jitter suppression ≈ 20·log10(N) dB** (8-tap ≈ 18 dB, 12-tap ≈ 21 dB). "Similar to a 4-bit modulator."
- **Linearity:** vin − v1 is small → tiny first-integrator swing → relaxed loop-filter linearity/slewing (but NOT the integrator's intrinsic cubic — Fig 3).
- **Semi-digital → inherently linear:** taps are switched unit elements carrying delayed copies of the same 1-bit stream; **tap mismatch = coefficient error (linear)**, not DAC INL → **no DEM**. |ΔF| ≈ (√π/2)(δI/IM), frequency-independent.
- **Cost:** FIR **group delay/phase distorts the loop transfer/NTF** → must re-tune + add a **compensation path**. Tap-count optimum is a broad minimum (~10-12 for CIFF-B; 8 here at OSR 50).
- **Compensation (this paper):** E(z) = (1−F(z))/(1−z⁻¹) (7-tap, DC gain 0) → **bandpass H1(s)** (low DC gain rejects offset, 1/s roll-off, peaks ~100 MHz) → fed into the *inner* integrator, not the first, so its non-idealities are attenuated by two integrators and it re-injects no in-band jitter/offset.

---

## 10. FoM definitions & the comparison lineage

- **FoM_Walden = Power / (2·BW·2^((SNDR−1.76)/6.02))** [fJ/conv-step, lower = better]. This work: **72.7 fJ/lvl**.
- **FoM_Schreier = DR + 10·log10(BW/Power)** [dB, higher = better]. This work: **176.8 dB**.
- **Lineage (extend Table II):** Bolatkale '11 (4-bit, 125 MHz, 260 mW — the multi-bit road not taken) · Sukumaran '14 (1-bit FIR audio, ISI cal + dither) · Zhang-Temes '15 (**digital ELD** + FIR + DWA) · Jain-Pavan '18 (**time-interleaved FIR**, best Walden) · Billa '20 (**FIR-MASH** + chopping) · Theertham '22 (**dual return-to-open DAC** — the circuit-level ISI fix).
- **Pavan-Baskaran decision framework:** levels dominate power → 1-bit ADC; 2-level DAC is linear → no DEM; only catch is jitter → FIR feedback (step 2/N, jitter ↓ 20·log10(N)) + relaxed linearity; stabilise the added delay by compensation. Each modern paper extends one axis (digital ELD / TI-FIR / MASH / R2O).

---

## 11. Glossary (say it right)

- **NTF / STF** — noise / signal transfer function. NTF is high-pass with zero(s) in-band; STF ≈ flat or peaking.
- **OBG (out-of-band gain)** — the NTF plateau above the band; ≲ 1.5 for 1-bit (Lee's rule).
- **OSR** — oversampling ratio Fs/(2·fb) = 50 here.
- **CIFB / CIFF** — chain-of-integrators feedback / feed-forward.
- **ELD** — excess loop delay.
- **ISI** — intersymbol interference (DAC rise/fall asymmetry → even-order distortion).
- **DEM / DWA** — dynamic element matching / data-weighted averaging (multi-bit DAC mismatch shaping).
- **MSA** — maximum stable amplitude.
- **SQNR / SNR / SNDR / DR** — quantization-noise-only ratio / signal-to-noise / incl. distortion / dynamic range.
- **NRZ / RZ / R2O** — non-return-to-zero / return-to-zero / return-to-open DAC pulse shapes.
- **Assisted opamp** — feed-forward injection of the known input current at the opamp output → low-power first integrator.
- **Semi-digital FIR DAC** — digital shift register driving an analog weighted-current summer.
- **Impulse invariance** — CT↔DT mapping by matching sampled loop impulse responses.
- **kT/C noise** — sampled thermal noise; input-referred 2kT/Cs.

---

## 12. Ready-made general Q&A (the 20% oral)

- **"Why oversample?"** — Spreads quantization noise over a wide Fs so an in-band digital filter removes most of it; noise-shaping then pushes in-band noise out of band. Gains far more than the −3 dB/oct of plain oversampling.
- **"Why is a 1-bit quantizer attractive?"** — Trivial ADC, and a 2-level DAC is *inherently linear* (only two points define a line) → no DEM/calibration. The cost is jitter/metastability sensitivity and OBG limited to ~1.5.
- **"Why is jitter worse in CT than DT?"** — CT feeds back charge = ∫i·dt over a clock-timed pulse, so edge-timing jitter modulates the fed-back charge directly; DT samples a settled voltage, immune to edge shape.
- **"What is Lee's rule?"** — A stability heuristic: keep |NTF|max ≲ 1.5 for a single-bit loop; higher OBG shapes better but lowers MSA and risks instability.
- **"CIFB vs CIFF?"** — Same NTF; CIFB's first integrator carries the full signal (good anti-aliasing, no STF peaking), CIFF's carries only shaped noise (relaxed first-opamp linearity, but STF peaks).
- **"How do you compensate ELD?"** — Add a fast/direct feedback tap around the quantizer (often RZ) to restore the intended DT loop impulse response; or digital ELD compensation in newer designs.
- **"Multi-bit downside and its fix?"** — Feedback-DAC element mismatch → INL → un-shaped harmonic distortion; fix with DEM/DWA (mismatch shaped to 1st-order high-pass), which goes tonal at small inputs.
- **"What limits this paper's SNDR?"** — HD2 from DAC ISI, plus thermal noise. Not quantization noise (ideal SQNR ~94 dB) and not the quantizer's own nonlinearity (odd-order, loop-shaped).
- **"Why an FIR DAC and not just multi-bit?"** — It buys the small-step feedback (jitter + linearity) *without* the multi-bit DAC mismatch/DEM burden, because a semi-digital FIR's tap mismatch is a linear coefficient error, not INL.
- **"How does the FIR filter jitter *frequency-selectively*?"** — The jitter error passes through F(z), so error at F(z)'s zero frequencies is nulled — the Fig-26 minima at ~600/800 MHz prove it.
- **"What is impulse invariance / how do you get CT coefficients?"** — Synthesise the target DT NTF, then choose the CT loop filter so its sampled open-loop impulse response matches the DT one; solve for integrator ωi and feedback gains, accounting for the DAC pulse and finite opamp BW.
- **"Decimation filter order?"** — sinc^(modulator order + 1), so the filter roll-off exceeds the noise rise; here sinc⁵.
