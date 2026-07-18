# Slide-by-slide context — say the slide number, get the answer

Each block: **On the slide** (what is literally shown) · **Say this** (first-person spoken answer, lead with it) · **Mechanism** (why it is true) · **If pushed** (examiner follow-ups) · **Numbers/wording**. Course terms are defined in `theory.md`.

Presentation = 4th-order single-bit CT ΔΣ with an 8-tap semi-digital FIR feedback DAC + analog FIR-delay compensation. fs 3.6 GS/s, BW 36 MHz, OSR 50, OBG 1.5. Measured 70.9 dB SNDR / 83 dB DR, 15 mW, 90 nm.

---

## Slide 1 — Title

**On the slide:** "Design Techniques for Wideband Single-Bit Continuous-Time Delta-Sigma Modulators with FIR Feedback DACs." Shettigar & Pavan, IEEE JSSC vol. 47 no. 12, 2012. Daniel Tyukov, 5714699 — ET4278.

**Say this:** This is a 2012 JSSC paper from Shanthi Pavan's group at IIT Madras. It shows that a single-bit continuous-time delta-sigma modulator can compete with multi-bit designs at tens-of-MHz bandwidth by filtering the 1-bit feedback through an FIR DAC. I reproduced its key results in MATLAB.

**Numbers/wording:** Continuous-time (CT), single-bit, FIR feedback DAC, wideband (36 MHz). Same group later extended this idea (time-interleaved FIR, FIR-MASH, dual return-to-open DAC).

---

## Slide 2 — Q1: Introduction (issues + main techniques) · maps to Q1 · Figs 1, 5, 7

**On the slide — issues addressed:**
- Single-bit NRZ feedback: full-scale steps every cycle → high clock-jitter sensitivity.
- Comparator metastability adds data-dependent jitter → in-band SNR collapses.
- Full-scale single-bit feedback demands a very linear loop filter.
- Multi-bit avoids these but costs quantizer power/area + DAC mismatch → DEM/calibration.
- An FIR feedback DAC adds group delay (excess loop delay) that destabilises the loop.

**On the slide — main techniques:**
- 1-bit ADC + 8-tap semi-digital FIR feedback DAC (multi-bit-like waveform, 2-level linear, no DEM).
- First FIR tap = 0 (explicit 1-cycle delay) to dodge metastability.
- Analog FIR-delay compensation: E(z) FIR DAC + bandpass H1(s) restores the target NTF.
- RZ DAC0 for ELD compensation (no summer around the quantizer).
- Modified CIFB + input feed-forward, active-RC integrators, assisted opamp.
- **Conclusion:** FIR feedback gives a 1-bit loop the jitter/linearity of a multi-bit loop; the price is loop delay, solved by an analog compensation path.

**Say this:** The paper attacks the single-bit-versus-multi-bit trade-off. Single-bit gives you a trivial ADC and an inherently linear 2-level DAC with no DEM, but its full-scale NRZ feedback is very jitter-sensitive, suffers comparator metastability, and needs a very linear loop filter. Multi-bit fixes those but costs quantizer power and area and needs DEM for DAC mismatch. Their answer is a 1-bit quantizer with an 8-tap semi-digital FIR feedback DAC: the FIR smooths the 1-bit stream into a small-step, multi-level waveform, so the loop gets multi-bit jitter tolerance and relaxed linearity while the DAC stays 2-level linear. The catch is that the FIR adds group delay that would destabilise the loop, so they add an analog bandpass compensation path to restore the target NTF.

**Mechanism:** Jitter error per edge is `e[n] ≈ (v[n]−v[n−1])·Δt/Ts` — proportional to the **step height** of the feedback. Full-scale 1-bit steps → worst case. The FIR staircase has small steps (≈2/N), so the injected jitter error collapses toward a 4-bit DAC's. Same for linearity: the error the first integrator processes, `vin − v1(t)`, is small, so the integrator's weak nonlinearity is excited at small amplitude. The FIR's group delay is the excess loop delay the compensation path must cancel.

**If pushed — "why not just use multi-bit?":** Power and area of the flash grow roughly exponentially with bits (comparators multiply, tolerable offset shrinks, ADC input cap and clock loading rise), and you need DEM for DAC mismatch which adds delay you cannot afford at 3.6 GS/s. Going 8→16 levels only cuts the required fs by ~25% for 95 dB SQNR — not worth the extra comparators. Turned around: drop to 1 bit and recover SQNR by raising fs (×3 here) at lower power.

**If pushed — "list the five issues":** (1) jitter sensitivity of single-bit NRZ, (2) data-dependent jitter from comparator metastability, (3) loop-filter linearity demand, (4) multi-bit's quantizer power/area + DAC mismatch/DEM, (5) the FIR DAC's own excess loop delay — a problem the paper creates and then solves.

**Numbers/wording:** NRZ, semi-digital FIR DAC, DEM (dynamic element matching), excess loop delay (ELD), metastability, Lee's rule (OBG ≲ 1.5). Cherry & Snelgrove [ref] is the jitter/metastability model.

---

## Slide 3 — Q2: Model and coefficients · maps to Q2 · Figs 5, 6, 7, 8

**On the slide — coefficients:**
- F(z) main FIR, 8 taps: [0.07 0.12 0.15 0.16 0.16 0.15 0.12 0.07], sum = 1.
- E(z) compensation FIR, 7 taps (derived): [0.93 0.81 0.66 0.50 0.34 0.19 0.07].
- CIFB feedback gains a = [0.0060 0.0457 0.1933 0.5547].
- Resonator gains g1 = 8.35e-4, g2 = 3.13e-3 (NTF zeros at 0.46, 0.89 of fb).
- Input feed-forward kff = 1.2 into last integrator (STF peaking); H1(s) bandpass ~100 MHz.
- fs = 3.6 GS/s, fb = 36 MHz, OSR = 50, order = 4, OBG = 1.5.

**On the slide — derivation:**
- Synthesise 4th-order OBG-1.5 NTF (Butterworth-HP poles bisected for OBG) + 2 optimised zeros.
- Match the loop characteristic polynomial → CIFB coefficients a, g.
- F(z) from Eq.(1); E(z) = (1 − F(z))/(1 − z⁻¹); 1−F has a DC zero so comp stays out-of-band.
- Fit H1(s) to the replica path by impulse invariance.
- **Conclusion:** F(z) is taken from the paper; E(z), a, g and H1(s) were derived. The model reproduces the OBG-1.5 NTF (Fig 8).

**Say this:** F(z) is the only coefficient set the paper prints — the 8 symmetric taps summing to one. Everything else I derived. I synthesised a 4th-order maximally-flat NTF with out-of-band gain 1.5 and two optimised in-band zeros, matched the loop characteristic polynomial to get the CIFB feedback gains and the two resonator gains, then built the compensation FIR E(z) as (1 − F(z)) divided by (1 − z⁻¹). Because 1 − F(z) has a zero at DC, the compensation path carries no in-band or DC content, which is exactly what keeps the FIR's jitter advantage. I fit the analog bandpass H1(s) to the replica path by impulse invariance.

**Mechanism:** The FIR path F(z)→DAC→I4→I3 has DC gain 1 but rolls off at −40 dB/dec, so it under-delivers at high frequency versus the intended loop. The compensation path supplies exactly that high-frequency deficit: conceptually [1 − F(z)] through replica integrators. Folding one integrator into it gives the 7-tap FIR E(z) = M1(z) = (1 − F(z))/(1 − z⁻¹), DC gain zero; replacing the second replica integrator with the bandpass H1(s) rejects offset (low DC gain) and keeps a 1/s roll-off. Coefficients are set by impulse invariance accounting for the finite opamp bandwidths.

**If pushed — "why OBG 1.5?":** Lee's rule: a stable single-bit loop needs |NTF|max ≲ 1.5. Pushing OBG higher shapes noise harder but drops the maximum stable amplitude. 1.5 is the standard 1-bit compromise.

**If pushed — "why optimised zeros?":** Moving the two NTF zeros off DC to notches inside the band (here at ~0.46 and ~0.89 of fb) spreads the zeros and lowers the average in-band noise — a few dB of SQNR versus zeros-all-at-DC. Optimal single-notch placement is fb/√3.

**If pushed — "did you use the delsig toolbox?":** No. Everything is hand-rolled — NTF, STF, loop and SNR are built by hand, per the course convention.

**Numbers/wording:** OBG (out-of-band gain), maximally-flat / Butterworth high-pass NTF, optimised zeros, resonator, CIFB, impulse invariance, characteristic polynomial. E(z) taps and a, g are derived (Shettigar's thesis is not public).

---

## Slide 4 — Q2.1: Techniques on/off · maps to Q2a

**On the slide:** "Each technique enabled then disabled, quantified in-band (36 MHz)":

| Technique | OFF | ON |
|---|---|---|
| Compensation path | unstable (~ −45 dB) | ~94 dB |
| First-tap = 0 (metastability) | ~52 dB | ~94 dB |
| FIR DAC (jitter floor) | plain 1-bit | ~25 dB lower |
| Ideal SQNR (all on) | — | ~94 dB |

**Conclusion:** compensation = stability, first-tap-zero = +42 dB (metastability), FIR DAC = ~25 dB jitter-floor reduction.

**Say this:** I toggled each technique to isolate what it buys. With the compensation path off, the loop is unstable — the FIR's group delay destabilises it, in-band goes to about −45 dB. Turn compensation on and I get the full ~94 dB ideal SQNR. Zeroing the first FIR tap recovers the metastability floor from about 52 dB back to 94 dB, roughly +42 dB. And the FIR DAC itself drops the jitter noise floor about 25 dB versus a plain single-bit loop.

**Mechanism:** This is the "malleably change a parameter and predict the result" demonstration the examiner wants. Compensation restores the NTF the FIR delay would otherwise wreck (stability). First-tap-zero removes the metastability-exposed tap (see slide 15). FIR small steps cut jitter-injected error (slide 12).

**If pushed — "what is the 94 dB?":** That is the ideal SQNR — quantisation-noise-only, no jitter/nonlinearity/thermal. The measured SNDR is 70.9 dB because thermal noise and DAC ISI dominate once you add them.

**If pushed — "why does turning off compensation give −45 dB, not just worse noise?":** Because it is not a noise problem, it is instability — the loop poles leave the unit circle, the states saturate, and the noise floor collapses. That is qualitatively different from the graceful degradation you get from finite gain or jitter.

**Numbers/wording:** SQNR (signal-to-quantisation-noise ratio), instability vs floor rise, +42 dB metastability recovery, ~25 dB jitter reduction.

---

## Slide 5 — Q2.2: Voltage scaling · maps to Q2b

**On the slide — assumptions:**
- Internal full scale = ±1; quantizer output in {−1, +1}.
- FIR DAC makes I4 see only the small shaped error (vin − v1): I4 has the smallest swing (~0.03).
- Swing grows toward the sign-only quantizer node I1; the first-order (input) path saturates last.
- States map to the 1.2 V supply / Vref; scaling redistributes gain, loop transfer unchanged.
- **Conclusion:** the input integrator (most linearity-critical) has the smallest swing; scaling preserves the NTF/STF.

**Say this:** I set the internal full scale to ±1 with the quantizer output in {−1, +1}, then scaled the integrator gains so each state fits the 1.2 V supply. The key point is that the FIR DAC makes the first integrator, I4, see only the small shaped error vin − v1, so it has the smallest swing, about 0.03. Swing grows as you move toward the quantizer. Because the quantizer is sign-only, scaling internal signals just redistributes gain — the NTF and STF are unchanged.

**Mechanism:** For a 1-bit quantizer, scaling every integrator input by bi and compensating downstream leaves the loop transfer H'(z) = (Πbi)·H(z) with the same NTF/STF — the sign block is scale-invariant. You choose bi to keep swings inside the opamp linear range and maximise dynamic range. The FIR's tiny first-stage error is *the reason* I4, the linearity-critical stage, is relaxed.

**If pushed — "why does the input integrator matter most?":** Its nonlinearity acts on the full unfiltered error and is *not* loop-suppressed (input-stage nonlinearity is not shaped). Later integrators see already-shaped signals, so their linearity is far less critical. Small swing on I4 is exactly what protects linearity.

**If pushed — "would scaling change a multi-bit design?":** Yes — with a multi-bit quantizer the reference levels may also need scaling, so it is not free; the sign-only 1-bit case is the easy one.

**Numbers/wording:** full scale ±1, coefficient scaling, NTF/STF invariance under 1-bit scaling, "first-order path saturates last", swing budget.

---

## Slide 6 — Q2.3: Thermal noise & spectrum · maps to Q2c

**On the slide:**
- Input-referred Gaussian noise added at the I4 summing node.
- σ sized so the in-band floor sets the dynamic range (Table I target 83 dB).
- Noise is unshaped (flat): it sets the floor, separate from the shaped quantisation noise.
- Output PSD in true dBFS so it overlays the paper.
- **Conclusion:** with the chosen input-referred noise the modulator reaches DR ~ 80 dB over 36 MHz (paper 83).

**Say this:** I add input-referred Gaussian noise at the first-integrator summing node and size its sigma so the in-band floor gives the target dynamic range — the paper's 83 dB. This noise is white and unshaped: because it enters at the input it rides through with the STF, so it sets the SNR floor independently of the shaped quantisation noise. I plot the PSD in true dBFS using A·N/2 so it overlays the paper. My simulated DR is about 80 dB versus the paper's 83.

**Mechanism:** Input/thermal noise enters at the same node as the signal, so its transfer to the output is the STF, not the NTF — you cannot noise-shape it away. Oversampling only spreads it over fs, buying −3 dB per octave of OSR. It is dominated by the first integrator's kT/C; later stages are attenuated by the preceding gain, so you spend power on a low-noise first stage.

**If pushed — "why 80 vs 83?":** It is a budgeting choice for the input-referred sigma; with a slightly lower noise density I would hit 83. The mechanism and slope are correct; the exact floor is a single knob.

**If pushed — "why does noise placement matter?":** Noise added later in the loop is shaped: 2nd-integrator input sees 20 dB/dec, quantizer input sees the full 40 dB/dec. So the RMS budget for 90 dB is ~200 µV at the input but ~0.6 V at the quantizer — three orders of magnitude. Budget the first integrator.

**Numbers/wording:** input-referred noise, unshaped/flat, STF (not NTF), kT/C, dynamic range, dBFS = A·N/2, −3 dB/octave of OSR for white noise.

---

## Slide 7 — Q2.4: Decimation filter · maps to Q2c

**On the slide:**
- sinc^(order+1) = sinc^5 CIC, implemented as cascaded box-car averages.
- Decimation factor ~ OSR (50); downsample to ~Nyquist.
- Plot output spectrum before/after decimation + transient waveforms (bitstream, FIR DAC feedback, recovered sine).
- **Conclusion:** decimation removes the out-of-band shaped noise; the in-band SNR is preserved.

**Say this:** I decimate with a sinc-to-the-fifth CIC filter — that is order-plus-one, so five for a 4th-order modulator — built as cascaded box-car averages. The decimation factor is roughly the OSR, 50, bringing it down to about Nyquist. I show the spectrum before and after decimation and the transient waveforms: the raw bitstream, the smooth FIR-DAC feedback, and the recovered sine. Decimation removes the out-of-band shaped noise while preserving the in-band SNR.

**Mechanism:** The sinc^(L+1) rule matches the filter roll-off to the L-th-order noise shaping: a sinc of one order higher than the modulator sufficiently attenuates the rising shaped noise before downsampling so it does not alias back in-band. A single box-car of length N is sinc^1 with H(z) = (1/N)(1−z⁻ᴺ)/(1−z⁻¹) and notches at multiples of fs/N; cascading gives sinc^k.

**If pushed — "why order+1?":** A sinc^k filter falls at k·20 dB/dec; to keep the decimated in-band noise below the shaped floor you need the filter to fall faster than the noise rises, so k = order+1. Fewer stages let out-of-band noise alias in and raise the floor.

**If pushed — "what does the FIR-DAC transient show?":** That v1(t) — the FIR-DAC feedback — is a smooth multi-level staircase that hugs vin, unlike the raw ±1 bitstream. That is the whole point of the FIR: multi-level feedback from a 1-bit stream.

**Numbers/wording:** CIC (cascaded integrator-comb), box-car / sinc, decimation factor = OSR, notches at k·fs/N, sinc^(order+1).

---

## Slide 8 — Q2.5: List of simulation results · maps to Q2 (overview)

**On the slide — paper results and which were reproduced:**

| Result | Paper value | Repro |
|---|---|---|
| NTF (Fig 8) | 4th-order, OBG 1.5, notch ~ −90 dB | yes |
| STF (Fig 9) | +12 dB peak ~100 MHz | yes |
| Output PSD (Fig 22) | SNDR 70.3, SNR 74.9, HD2 73.5 dB | yes |
| SNR/SNDR vs amp (Fig 21) | pk SNR 76.4, SNDR 70.9, DR 83 | yes |
| Jitter PSD (Fig 2) | FIR ~ 4-bit, << plain 1-bit | yes |
| Jitter nulls (Fig 26) | minima at F(z) zeros ~600/800 MHz | yes |
| Jitter tolerance (Fig 27) | ~10× vs plain 1-bit | yes |
| Metastability (Fig 4) | 52 → 94 dB (paper 91) | yes |
| Nonlinear integrator (Fig 3) | floor rise = 4-bit case | yes |
| ISI correction (Figs 29/30) | HD2 −15 dB, SNDR → 74.3 | yes |
| Survey scatter (Figs 23/24) | BW/DR & P/SNDR clouds | no (survey) |

**On the slide — MATLAB assumptions:** fs = 3.6 GS/s, OSR = 50; Nfft = 2^16; window kaiser(N, 20); coherent input tone; ns = 20 CT sub-steps/clock; rng(1) seeded.

**Conclusion:** reproduced NTF, STF, PSD, SNR/SNDR-vs-A, jitter (2/26/27), metastability (4), nonlinear integrator (3), ISI (29/30); survey scatter (23/24) not reproducible.

**Say this:** This is my scoreboard. I reproduced every system-level figure — the NTF, STF, output PSD, SNR/SNDR versus amplitude, all three jitter figures, metastability, the nonlinear-integrator floor rise, and the ISI correction. The only things I did not reproduce are the two survey scatter plots, Figs 23 and 24, because those are literature surveys of other chips, not simulations of this modulator. My common assumptions are fs 3.6 giga-samples, OSR 50, a 2-to-the-16 FFT with a Kaiser-20 window, a coherent tone, twenty continuous-time sub-steps per clock, and a fixed rng seed.

**Mechanism:** ns = 20 sub-steps per clock is how a discrete MATLAB models the CT loop filter — the inner loop updates the CT integrator states, the outer loop fires the quantizer once per sample. Coherent tone + Kaiser window + A·N/2 scaling is the course's spectral recipe so bins land exactly and dBFS is meaningful.

**If pushed — "why can't you reproduce 23/24?":** They plot published BW-vs-DR and power-vs-SNDR for dozens of other converters. There is nothing to simulate; I address them qualitatively on the Q6 comparison slide instead.

**If pushed — "why 20 sub-steps?":** Enough to resolve the CT integrator dynamics and the DAC edge within a clock period without excessive runtime; jitter and ISI need sub-sample edge resolution, which the sub-steps provide.

**Numbers/wording:** coherent sampling, Kaiser(N,20), CT sub-steps, "system-level reproducible vs survey".

---

## Slide 9 — Q2.6A: NTF · maps to Q2 · Fig 8

**On the slide:** Realised |NTF| vs f/Fs: 4th-order, OBG = 1.5, two optimised in-band notches. Published (Fig 8) next to my MATLAB result. **Conclusion:** same 4th-order high-pass shape as Fig 8: OBG = 1.5 plateau, two in-band notches (~ −100 dB).

**Say this:** This is the realised noise transfer function. It is a 4th-order high-pass with the out-of-band gain plateau at 1.5 and two optimised notches inside the band down around −100 dB. It matches Fig 8. There is a small kink near f/fs ≈ 0.03 from the bandpass compensation filter H1(s), but the paper shows — and I confirm — that the in-band quantisation noise and the maximum stable amplitude are the same as the maximally-flat OBG-1.5 NTF, so the kink is harmless.

**Mechanism:** NTF = 1/(1+L(z)) where L is the loop gain. Fourth order gives an 80 dB/dec high-pass slope; the two zeros placed off DC create the notches; OBG 1.5 caps the out-of-band plateau per Lee's rule. The H1(s) compensation slightly perturbs the shape near the band edge (the kink) without changing the in-band integral or MSA.

**If pushed — "what sets the notch depth/positions?":** The resonator gains g1, g2 place the zeros (here at 0.46 and 0.89 of fb); deeper/closer notches trade against out-of-band gain and MSA.

**If pushed — "why does the kink not matter?":** Because SQNR is set by the in-band area under |NTF|² and by the MSA — both unchanged. The kink is out at the band edge where it costs nothing.

**Numbers/wording:** NTF, out-of-band gain (OBG), optimised zeros/notches, 80 dB/dec (4th order), Lee's rule, MSA.

---

## Slide 10 — Q2.6B: STF · maps to Q2 · Fig 9

**On the slide:** |STF| magnitude from the input feed-forward. Published (Fig 9) vs my MATLAB. **Conclusion:** same bandpass shape as Fig 9: ~ +12 dB peak then rolls off (peak ~200 MHz vs ~100 MHz); needs input pre-filter.

**Say this:** The signal transfer function peaks about +12 dB and then rolls off — a mild bandpass. That peaking comes from the extensive input feed-forward, which the paper uses to keep the integrating caps small. My peak sits near 200 MHz versus the paper's 100 MHz, a coefficient-tuning difference, but the shape and the +12 dB are right. The practical consequence is that out-of-band blockers must be pre-filtered before the modulator, or the peaking lets them through and overloads the loop.

**Mechanism:** Feed-forward paths add a numerator zero to the STF, lifting the response before the loop filter rolls it off — classic CIFF/feed-forward STF peaking. It buys small caps and low opamp power at the cost of anti-alias/blocker rejection.

**If pushed — "why is my peak at a different frequency?":** The peak frequency is set by the feed-forward coefficient kff and the integrator unity-gain frequencies; since those are derived, not printed, my kff = 1.2 lands the peak higher. The magnitude and the qualitative bandpass shape match.

**If pushed — "how would you fix the peaking?":** A direct input feed-forward term c0 to the quantizer flattens the STF, or an explicit input pre-filter. The paper accepts the peaking and pre-filters.

**Numbers/wording:** STF, input feed-forward, STF peaking (+12 dB), pre-filter blockers, small integrating caps.

---

## Slide 11 — Q2.6C: Output PSD · maps to Q2 · Fig 22

**On the slide:** Output PSD, −4 dBFS 10 MHz tone, 2^16-pt FFT. Published (Fig 22) vs my MATLAB. **Conclusion:** SNDR 71.4 (paper 70.3), SNR 76.5 (74.9), HD2 −73.0 (−73.5) dB.

**Say this:** This is the canonical output spectrum, a −4 dBFS 10 MHz tone with a 2-to-16 FFT. I get SNDR 71.4 dB versus the paper's 70.3, SNR 76.5 versus 74.9, and HD2 at −73.0 versus −73.5. The important qualitative feature is that the SNDR is limited by HD2 — the second harmonic — which comes from DAC intersymbol interference, not from quantisation noise.

**Mechanism:** The gap between SNR (76.5) and SNDR (71.4) is the distortion, dominated by HD2. HD2 is even-order, which points to DAC rise/fall asymmetry (ISI) in the continuous-time feedback, not to the odd-order nonlinearity of the 1-bit quantizer. The shaped quantisation noise rises out-of-band at 80 dB/dec; the in-band floor is thermal.

**If pushed — "why HD2 and not HD3?":** HD2 is even-order → a waveform asymmetry, i.e. unequal rise/fall of the differential DAC pulses (ISI). Odd-order HD3 would come from a symmetric nonlinearity like the integrator cubic. The even harmonic is the ISI signature.

**If pushed — "why is your SNDR slightly better than the paper?":** My model has the ideal loop plus the dominant nonidealities; the measured chip carries extra parasitics and mismatch. A ~1 dB optimistic gap on a system-level model is expected and honest.

**Numbers/wording:** SNDR vs SNR (the difference = distortion), HD2 (even-order → ISI), dBFS, coherent −4 dBFS 10 MHz tone.

---

## Slide 12 — Q2.6D: Jitter PSD · maps to Q2, Q3.4 · Fig 2

**On the slide:** In-band PSD with 0.3 ps rms white clock jitter: FIR vs plain 1-bit vs 4-bit. Published (Fig 2) vs my MATLAB. **Conclusion:** FIR jitter floor ~25 dB below plain 1-bit, similar to 4-bit.

**Say this:** With 0.3 picoseconds rms of white clock jitter I compare three feedbacks: plain single-bit, the single-bit-plus-FIR, and a 4-bit modulator. The single-bit-plus-FIR jitter floor sits about 25 dB below the plain single-bit and essentially on top of the 4-bit curve. So the FIR gives a 1-bit loop the jitter immunity of a multi-bit one.

**Mechanism:** Jitter injects an error `e[n] ≈ (v1[n]−v1[n−1])·βn/Ts` at the DAC — proportional to the feedback step height and non-zero only at transitions. The plain 1-bit feedback steps full scale (±2) every edge; the 8-tap FIR staircase steps by ≈2/N, so var(diff(v1)) collapses toward the 16-level DAC's. Jitter suppression scales roughly as 20·log10(N).

**If pushed — "why is white jitter the right model here?":** White jitter models the clock's high-frequency phase noise / thermal jitter. The paper also does an FM-jitter sweep (slide 13) to expose the FIR's frequency-selective filtering. Both matter.

**If pushed — "does the FIR relax linearity too?":** Yes for the loop-filter linearity (small error into I4), but note the nonlinear-integrator slide shows the FIR does *not* by itself relax the integrator's intrinsic cubic — that is a separate effect. The FIR's headline win is jitter.

**Numbers/wording:** white clock jitter (0.3 ps rms), step height, e[n] = Δv·Δt/Ts, 20·log10(N) suppression, "similar to a 4-bit modulator at fs/3".

---

## Slide 13 — Q2.6E: Jitter filtering (FM nulls) · maps to Q2, Q3.4 · Fig 26

**On the slide:** In-band jitter noise vs FM jitter frequency, overlaid with |F(z)|. Published (Fig 26) vs my MATLAB. **Conclusion:** in-band jitter noise nulls fall at the zeros of F(z).

**Say this:** Here I fix the rms jitter and sweep the modulating frequency of a sinusoidal-FM jitter, then overlay the FIR magnitude response |F(z)|. The in-band jitter noise shows minima exactly where F(z) has its zeros — around 600 and 800 MHz. That is direct proof that the FIR DAC filters the jitter-induced error, not just reduces its amplitude.

**Mechanism:** The jitter error passes through the same F(z) that shapes the feedback, so error components at the FIR's zero frequencies are nulled. F(z)'s taps were optimised assuming the jitter spectrum falls as 1/f², so the zeros are placed to attenuate where jitter power is expected.

**If pushed — "so the taps are not equal — why?":** Right. Sukumaran's audio version uses equal taps for layout ease, but here the taps are jitter-weighted (1/f² assumption) to buy margin at high speed / lower OSR. Equal taps would put the nulls elsewhere.

**If pushed — "how did you model FM jitter?":** A sinusoidal timing error on the clock edges at the sweep frequency, injected as Δt in the per-edge error term, then measured in-band and plotted against |F(z)|.

**Numbers/wording:** FM (sinusoidal) jitter, zeros of F(z), nulls at ~600/800 MHz, 1/f² jitter weighting, "jitter filtering".

---

## Slide 14 — Q2.6F: Jitter tolerance · maps to Q2, Q3.4 · Fig 27

**On the slide:** Max tolerable rms jitter vs jitter frequency: 1-bit+FIR vs 4-bit vs plain 1-bit. Published (Fig 27) vs my MATLAB. **Conclusion:** 1-bit+FIR tolerates ~10× more rms jitter than plain 1-bit.

**Say this:** This flips it around and asks, for a fixed idle-channel noise target, how much rms jitter each design tolerates versus jitter frequency. The single-bit-plus-FIR tolerates roughly ten times more rms jitter than a plain single-bit design, and it is comparable to a 4-bit modulator at a third of the clock rate.

**Mechanism:** Same step-height mechanism as slide 12 but expressed as a tolerance: since injected jitter error ∝ step height, and the FIR shrinks the step by ≈N/2, the tolerable jitter grows by roughly the same factor (~10× ≈ 20 dB, consistent with 20·log10(N) for N≈8-12).

**If pushed — "what is the noise target?":** The paper uses −80 dBFS idle-channel in-band noise as the pass/fail line for "tolerable" jitter.

**Numbers/wording:** jitter tolerance, ~10× (≈20 dB), idle-channel noise −80 dBFS, comparable to 4-bit at fs/3.

---

## Slide 15 — Q2.6G: Metastability · maps to Q2, Q2.1 · Fig 4

**On the slide:** In-band PSD with vs without the first-tap explicit delay. Published (Fig 4) vs my MATLAB. **Conclusion:** first-tap-zero recovers ~52 → ~94 dB (paper 91).

**Say this:** Comparator metastability behaves like a signal-dependent jitter on the feedback edge. Without protection the in-band SNR is about 52 dB. Setting the first FIR tap to zero — an explicit one-clock delay — lets the later flip-flops re-time a large signal, so regeneration is fast and metastability noise disappears, recovering to about 94 dB. The paper reports 91; I get 94.

**Mechanism:** A regenerative latch grows its output as exp(t/τ); a small comparator input resolves late, so the feedback edge crosses at a data-dependent time — exactly clock jitter, but signal-dependent, worst near zero-crossings. The first tap is the one most exposed. Zeroing it (f1 = 0) means the metastability-sensitive tap injects nothing; the downstream flip-flops always see a resolved, large signal. In MATLAB I model it as a data-dependent delay τd ≈ τ·ln(VFS/|vx|) on the first tap only, and the mitigation is simply d0 = 0.

**If pushed — "why does an extra delay not hurt the loop?":** It adds to the loop delay, which is precisely what the compensation path already handles. So you get the metastability fix effectively for free, costing only one tap of FIR filtering depth.

**If pushed — "difference between metastability and clock jitter?":** Clock jitter is a random timing error on the clock; metastability is a *signal-dependent* timing error from finite regeneration. Cherry & Snelgrove model metastability as equivalent jitter with σβ = σms/√2 (one edge perturbed instead of two).

**Numbers/wording:** metastability, regeneration time constant τ, exp(t/τ), first-tap-zero / explicit 1-cycle delay, ~40 dB recovery, Cherry & Snelgrove.

---

## Slide 16 — Q2.6H: Nonlinear integrator · maps to Q2, Q3.5 · Fig 3

**On the slide:** In-band PSD with a weak cubic on the input integrator I4. Published (Fig 3) vs my MATLAB. **Conclusion:** weak cubic on I4 raises the in-band floor (out-of-band noise demodulation).

**Say this:** I make the input integrator weakly nonlinear with a cubic term — output current i = Gm·vd − G3·vd³ — matching the paper's Fig 3. The cubic raises the in-band noise floor. The interesting part is *why*: it is not classic harmonic distortion of the tone, it is the cubic folding out-of-band shaped quantisation noise back into the band.

**Mechanism:** The vd³ term multiplies the large out-of-band shaped noise present at the integrator node with itself, demodulating a portion down in-band — a noise-folding, not a discrete harmonic. The paper's key finding: the 1-bit+FIR (3.6 GS/s) and the 4-bit (1.2 GS/s) curves rise by the *same* amount, so both need comparable loop-filter linearity — the FIR relaxes jitter, not the integrator's intrinsic linearity budget.

**Mechanism (method):** I used Pavan's perturbational two-run method: a linear run (G3 = 0) records the first-integrator node history x1[k]; an injection run drives the linear loop with j[k] = G3·x1[k]³ and input zero; sum the outputs. HD3 = G3·A²/(4·Gm). Fig 3 parameters Gm = 1000, G3 = 20.

**If pushed — "why the input integrator and not the others?":** Because I4 sees the unfiltered error; its nonlinearity is not loop-suppressed. Later integrators process already-shaped signals, so their distortion is attenuated by the preceding loop gain.

**If pushed — "so what does the FIR actually relax?":** The *swing* into I4 (jitter and slewing), not the coefficient of its cubic. The paper is careful about this — Fig 3 exists to show the FIR does not magically fix integrator linearity.

**Numbers/wording:** weak nonlinearity i = Gm·vd − G3·vd³, HD3 = G3·A²/(4Gm), noise folding / demodulation, Pavan two-run perturbation method, Gm=1000/G3=20.

---

## Slide 17 — Q2.6I: SNDR vs amplitude · maps to Q2 · Fig 21

**On the slide:** SNR/SNDR vs input amplitude sweep including the ISI kink. Published (Fig 21) vs my MATLAB. **Conclusion:** peak SNR 75.7, SNDR 71.6, DR ~81 dB; ISI kink near full scale.

**Say this:** Sweeping input amplitude gives the classic SNR and SNDR curves. I get peak SNR 75.7, peak SNDR 71.6, and about 81 dB dynamic range, against the paper's 76.4, 70.9 and 83. The signature feature is the kink where the SNDR curve pulls away from SNR — that is the onset of the DAC ISI noise rise, and it is exactly what the ISI-correction improvement removes.

**Mechanism:** DR is read as the input level where in-band SNR hits 0 dB, extrapolated. SNR keeps climbing with amplitude, but SNDR saturates and kinks because HD2 from ISI grows; transition density (and hence ISI error) is amplitude-dependent, so the distortion turns on near a particular level (~ −55 dBFS in the paper) and the HD2 rolls off again near full scale as transitions become rare.

**If pushed — "why does DR differ from the peak-SNDR number?":** DR (83 dB) is a small-signal / extrapolated metric set by the noise floor; peak SNDR (70.9) is a large-signal metric limited by distortion. They answer different questions — noise-limited vs distortion-limited.

**If pushed — "the kink is your improvement hook?":** Yes — removing ISI (slide 30) removes the kink, lifting peak SNDR toward 74-76 dB. This slide sets that up.

**Numbers/wording:** dynamic range (DR), peak SNR/SNDR, ISI kink, transition-density-dependent HD2, amplitude sweep.

---

## Slide 18 — Q3.1: Finite amplifier gain & BW · maps to Q3 · Fig 12

**On the slide:** Paper: opamp DC gain ~ 55 dB, UGB ~ 2 GHz (Fig 12). Model: leaky integrator (finite DC gain) + 1-pole roll-off at UGB on each integrator; swept A_dc and UGB. Impact: finite gain leaks the NTF notch (in-band floor rises); finite UGB adds excess phase → NTF droop. **Conclusion:** negligible penalty needs ~50 dB DC gain and ~2-4 GHz UGB; the paper's 55 dB / 2 GHz is sufficient.

**Say this:** The paper's opamps are about 55 dB DC gain and 2 GHz unity-gain bandwidth. I model each integrator as a leaky integrator for the finite DC gain plus a one-pole roll-off at the UGB for the finite bandwidth, then sweep both. Finite DC gain leaks the NTF notch so the in-band floor rises; finite UGB adds excess phase that droops the NTF. My sweep shows you need roughly 50 dB gain and 2-to-4 GHz UGB for negligible penalty, so the paper's 55 dB / 2 GHz is sufficient with a little margin.

**Mechanism:** A real integrator is 1/(z−α) with α = 1 − (ωu/A0)/fs < 1, so its DC gain is finite and the NTF is no longer exactly zero at DC — quantisation noise and offset leak in-band. Finite UGB is an extra pole that eats phase margin, adding excess loop delay and drooping the NTF near the band edge. This is the same leaky-integrator idea from the MOD1 practical, applied per stage.

**If pushed — "which integrator is most sensitive?":** The first (I4) — its finite gain leaks the deepest part of the NTF notch and its noise is input-referred. The compensation and later stages tolerate more.

**If pushed — "how does this connect to the assisted opamp?":** The assisted opamp lets the first integrator hit 55 dB / 2 GHz at low bias by offloading the input current, so the design meets this spec without burning power (slide 23/25).

**Numbers/wording:** DC gain 55 dB, UGB 2 GHz, leaky integrator α = 1 − (ωu/A0)/fs, NTF notch leakage, excess phase / NTF droop.

---

## Slide 19 — Q3.2: DAC mismatch · maps to Q3

**On the slide:** A 2-level (1-bit) DAC has NO level mismatch → intrinsically linear. The 8-tap FIR DAC has unit-element (resistor) mismatch; plot shows 2% sigma per tap (exaggerated; realistic ~0.5-1%) to make the zero shift visible. Mismatch perturbs the F(z) coefficients (a LINEAR change) → shifts the F(z) zeros / jitter nulls and the realised NTF slightly. No new harmonics. **Conclusion:** FIR-tap mismatch moves the jitter nulls and perturbs the NTF; it does not add distortion (unlike a multi-bit DAC).

**Say this:** This is the subtle one for a single-bit design. The 2-level DAC has only two levels, so there is nothing to mismatch — it is intrinsically linear. The mismatch lives in the FIR taps, the unit resistors. But because every tap carries a delayed copy of the *same* 1-bit stream, tap mismatch only perturbs the FIR coefficients — a linear change. It shifts the F(z) zeros, so the jitter nulls move and the realised NTF changes slightly, but it adds no new harmonics. I plotted 2% sigma per tap to make the shift visible; realistic is half a percent to one percent.

**Mechanism:** In a semi-digital FIR DAC each switched resistor is gated by z⁻ⁱ of the bitstream, so each element's contribution is independent and linear — errors just re-weight F(z). Contrast a multi-bit thermometer DAC, where element mismatch bends the transfer staircase (INL) and injects harmonic distortion directly at the feedback node, un-shaped, which is why multi-bit needs DEM. Random tap errors give |ΔF(f)| ≈ (√π/2)(δI/IM), frequency-independent, capping stopband attenuation but leaving the passband and linearity intact.

**If pushed — "so mismatch is harmless?":** Practically negligible for linearity — the point of the architecture. It only detunes the jitter nulls and the notch slightly. No DEM needed, which is the headline advantage over multi-bit.

**If pushed — "how did you model it?":** F(z) taps × (1 + σ·randn), recompute the FIR response and the loop, show the null/NTF shift; no harmonic appears.

**Numbers/wording:** unit-element (resistor) mismatch, "mismatch = coefficient error, not nonlinearity", INL, DEM (needed for multi-bit, not here), 0.5-1% realistic sigma, no new harmonics.

---

## Slide 20 — Q3.3: Excess loop delay (ELD) · maps to Q3 · Figs 5, 7, 10

**On the slide:** Modelled as a fractional-Ts delay in the quantizer → DAC feedback path. Impact: the NTF degrades and the loop goes unstable beyond ~0.25 Ts of excess delay. RZ DAC0 (prompt fast feedback into I1) compensates the delay and restores stability. **Conclusion:** ELD must be compensated; the RZ DAC0 path restores the NTF up to the modelled delay.

**Say this:** Excess loop delay is the latency of the comparator plus DAC feedback. I model it as a fractional-clock delay in the quantizer-to-DAC path. As I increase it the NTF degrades and the loop goes unstable beyond roughly a quarter of a clock period. The fix is the RZ DAC0 — a prompt, fast return-to-zero feedback into the first integrator's input — which adds back the missing early feedback and restores the NTF and stability without needing a power-hungry summing amplifier around the quantizer.

**Mechanism:** Extra delay in the feedback rotates the loop phase, moving poles toward and past the unit circle. The standard CT fix is a direct/fast feedback tap around the quantizer that restores the intended discrete-time loop impulse response. Here that is an RZ DAC (DAC0). RZ is chosen because its pulse is prompt (early in the period) — good for compensating delay — even though RZ is more jitter-sensitive, which is acceptable on this small correction path.

**If pushed — "why is the FIR itself an ELD source?":** The FIR's group delay is exactly excess loop delay — the paper adds delay on purpose (for the FIR and for metastability) and then compensates it with both the analog compensation path (for the FIR shape) and the RZ DAC0 (for the raw latency).

**If pushed — "why RZ and not NRZ for DAC0?":** RZ delivers its charge early in the clock period, so it acts as the prompt corrective feedback; an NRZ pulse spans the whole period and cannot provide that early kick. The trade is RZ's higher jitter sensitivity, tolerable on a small path.

**Numbers/wording:** excess loop delay (ELD), fractional-Ts delay, unstable beyond ~0.25 Ts, RZ DAC0, "direct feedback tap restores the DT loop impulse response", no summer around the quantizer.

---

## Slide 21 — Q3.4: Clock jitter · maps to Q3 · Figs 2, 26, 27

**On the slide:** Modelled white + sinusoidal-FM timing error on the clock edges; error per cycle ~ (v1[n]−v1[n−1])·dt/Ts. Impact: the in-band noise floor rises with rms jitter. Reduction: the FIR DAC's small steps cut the jitter error ~10× vs plain 1-bit; in-band nulls appear at the F(z) zeros. **Conclusion:** the FIR feedback DAC reduces jitter sensitivity ~10×, to a level comparable with a 4-bit modulator.

**Say this:** I model clock jitter two ways: white timing error and a sinusoidal-FM sweep on the clock edges. The injected error per cycle is the feedback step times the timing error over the period — proportional to step height. The in-band floor rises with rms jitter. The FIR fixes it: its small steps cut the jitter error about ten times versus plain single-bit, and the sweep shows in-band nulls right at the F(z) zeros. So the FIR takes a single-bit loop to roughly 4-bit jitter performance.

**Mechanism:** This is the summary slide for the three jitter figures — Fig 2 (white, slide 12), Fig 26 (FM nulls, slide 13), Fig 27 (tolerance, slide 14). Core equation e[n] ≈ (v1[n]−v1[n−1])·βn/Ts; error only at transitions, ∝ step height. FIR reduces var(diff(v1)); suppression ≈ 20·log10(N).

**If pushed — "white vs accumulated jitter?":** White (thermal) jitter has a flat phase-noise contribution; accumulated (VCO) jitter integrates and is worse at low offsets. The paper's clean-clock case is dominated by the PLL's phase noise; the modelling here uses white plus a deterministic FM tone to expose the FIR filtering.

**If pushed — "is RZ better or worse for jitter?":** Worse — RZ has more edges per bit, so more jitter-injected charge (σδy² ≈ 8.0 for RZ vs ≈ 2.8 for NRZ). That is why the main and FIR feedback use NRZ; only the small ELD DAC0 is RZ.

**Numbers/wording:** white + FM jitter, e[n] = Δv·Δt/Ts, ∝ step height, ~10× / 20·log10(N), NRZ vs RZ jitter (2.8 vs 8.0).

---

## Slide 22 — Q3.5: Integrator non-linearity · maps to Q3 · Fig 3

**On the slide:** Paper: weak cubic on the input integrator I4: i = Gm·vd − G3·vd³; swept G3 = 0 / 0.1 / 0.3 (Fig 3). The input integrator is the dominant one: its non-linearity acts on the unfiltered input/feedback. Modelled as a cubic on the I4 input; impact: it folds out-of-band shaped noise in-band → floor rises. **Conclusion:** the input integrator sets the linearity budget; G3 raises the in-band floor (SNDR 94 → 76 dB at G3=0.1).

**Say this:** This is the non-ideality version of the nonlinear-integrator study. The paper puts a weak cubic on the input integrator and sweeps its strength. The input integrator dominates because it acts on the unfiltered input and feedback — its nonlinearity is not loop-suppressed. The cubic folds out-of-band shaped noise into the band, so the floor rises: at G3 = 0.1 the SNDR drops from the ideal 94 down to about 76 dB. That is why the input integrator sets the whole linearity budget.

**Mechanism:** Same as slide 16 (they are the same physics — slide 16 is the Q2 reproduction of Fig 3, this is the Q3 non-ideality framing). Cubic vd³ demodulates out-of-band shaped noise in-band (noise folding). Input-stage nonlinearity is *not* attenuated by loop gain because the error contains the full quantisation signal; HD3 = G3·A²/(4Gm).

**If pushed — "why isn't the loop gain suppressing it?":** The common intuition that loop gain suppresses nonlinearity holds for *later* stages, not the input stage: the input nonlinearity acts on e = x − y, and with 1-bit feedback y = ±1 the error carries the full large signal, so the distortion is excited at large amplitude and passes essentially unshaped.

**If pushed — "and multi-bit would help?":** Yes — more levels shrink the error amplitude ê ≈ 2/(n−1) at the nonlinear node, collapsing the cubic term. But that reintroduces DAC mismatch/DEM. The FIR does not shrink this term (Fig 3 shows equal rise for 1-bit+FIR and 4-bit).

**Numbers/wording:** input-stage nonlinearity NOT loop-suppressed, cubic i = Gm·vd − G3·vd³, noise folding, SNDR 94 → 76 dB at G3=0.1, ê ≈ 2/(n−1).

---

## Slide 23 — Q4.1: Loop filter & assisted opamp · maps to Q4 · Fig 10

**On the slide:** Four active-RC integrators (I4..I1); input/feedback resistors set the CIFB coefficients; virtual-ground current summing. Assisted-opamp current DACs inject a replica of the input current at the opamp output → relaxed opamp for fast input currents. Reset switches across the caps as anti-lockup; R and C are digitally trimmable banks. **Conclusion:** active-RC loop filter with assisted opamps gives low-distortion integration with small caps and low opamp power.

**Say this:** The loop filter is four active-RC integrators, I4 down to I1. Input and feedback resistors set the CIFB coefficients and the summing happens as currents into the opamp virtual ground. The clever part is the assisted-opamp technique: a current DAC injects a replica of the known input current directly at the opamp output, so the opamp itself has to source almost nothing, the virtual ground barely moves, distortion collapses, and it can run at low bias. There are reset switches across the caps as anti-lockup, and the R and C are digitally trimmable banks against time-constant variation.

**Mechanism:** Active-RC (resistor in, cap feedback) gives a linear integrator with a true virtual ground — better linearity than Gm-C at these swings. The assisted opamp works because the current the first integrator must supply (from Vin and Vdac) is known, so a feed-forward assistant injects it at the output; cancellation condition Ia ≈ (1 + CL/C)·Iin. The assistant's own distortion is divided by the opamp loop gain GmR, so even 0.5% assistant HD3 gives a near-distortion-free output. Applied to the first integrator, where linearity matters most.

**If pushed — "why CIFB not CIFF here?":** CIFB decouples the fast path (ADC→DAC0→I1) from the precise path (ADC→FIR→I4→…), so each can be optimised independently. The paper calls it a *modified* CIFB with input feed-forward — it borrows CIFF's small-swing benefit via the feed-forward while keeping CIFB's distributed feedback.

**If pushed — "what is the trim for?":** RC time constants vary ±20-30% over process; the trimmable R/C banks re-centre the integrator unity-gain frequencies so the realised NTF matches the design.

**Numbers/wording:** active-RC integrators, virtual-ground current summing, CIFB coefficients from R ratios, assisted opamp (Ia ≈ (1+CL/C)Iin), anti-lockup reset, digitally trimmable RC.

---

## Slide 24 — Q4.2: Semi-digital FIR feedback DAC · maps to Q4 · Figs 1, 16

**On the slide:** Tapped delay line filters the 1-bit output by F(z); each tap drives a switched-resistor unit element into the I4 virtual ground. Switched resistors avoid current-steering distortion. Reference-side switching = constant loop gain (linear); virtual-ground-side = faster but noisier. Resistor (tap) mismatch only perturbs F(z) → stays linear, no DEM needed. **Conclusion:** the semi-digital FIR DAC turns the 1-bit stream into a small-step, inherently linear multi-level feedback.

**Say this:** The FIR DAC is a tapped delay line — flip-flops giving z⁻ⁱ — that filters the 1-bit output by F(z). Each tap gates a switched-resistor unit element into the first-integrator virtual ground, and the sum of the weighted taps is the smooth multi-level feedback current. They use switched resistors, not current steering, to avoid current-source headroom noise and source-node distortion. There are two switching styles: reference-side switching keeps the loop gain constant in time, so it is the most linear, used where linearity is critical; virtual-ground-side switching is faster but noisier. And because each element carries a delayed copy of the same bitstream, tap mismatch only perturbs F(z) — it stays linear, no DEM.

**Mechanism:** Semi-digital = digital shift register drives an analog weighted-current summer (Su & Wooley). H(z) = Σ aᵢz⁻ⁱ; symmetric taps → linear phase. The DAC is inherently linear because element errors are coefficient errors, not staircase INL. Switched resistors into a virtual ground are I→V with the opamp providing the ZOH.

**If pushed — "reference-side vs virtual-ground-side, when?":** Reference-side (switch at the Vref end): loop gain doesn't change as bits switch → preserves linearity, but the large resistor's distributed RC slows it; used for R < ~10 kΩ / linearity-critical DACs (main + compensation). Virtual-ground-side (switch at the opamp end): no distributed-cap charging so faster, but parasitic switching at the virtual ground adds noise/distortion; used where speed dominates.

**If pushed — "why not current-steering?":** Current-steering DACs have headroom-limited output noise and source-node nonlinearity; switched resistors are quieter and more linear at the cost of speed.

**Numbers/wording:** semi-digital FIR DAC, tapped delay line z⁻ⁱ, switched-resistor unit elements, reference-side vs virtual-ground-side switching, "mismatch = coefficient error", no DEM, Su & Wooley.

---

## Slide 25 — Q4.3: Two-stage feed-forward opamp · maps to Q4 · Fig 12

**On the slide:** Two-stage feed-forward-compensated opamp (no Miller cap to charge → power efficient). AC-coupling the feed-forward path raises the output swing → smaller caps, higher integrator gain. DC gain ~ 55 dB, UGB ~ 2 GHz; I4 draws 3 mA, I3/I2/I1 0.5 mA each. **Conclusion:** feed-forward compensation meets the 55 dB / 2 GHz target at low power.

**Say this:** The opamps are two-stage with feed-forward compensation instead of Miller compensation. There is no Miller cap to charge, which is more power-efficient, and the long settling transient that feed-forward normally has is fine in continuous time because the whole waveform is processed, not a settled sample. AC-coupling the feed-forward path raises the output swing, which lets them use smaller integrating caps and higher integrator gain. The spec is about 55 dB DC gain and 2 GHz UGB. The first integrator draws 3 mA; the other three draw half a milliamp each.

**Mechanism:** Feed-forward compensation creates a left-half-plane zero that stabilises the two-stage opamp without a Miller cap; in DT switched-cap you can't tolerate its slow settling, but in CT the integrator processes the continuous output so it is acceptable. The current allocation (3 mA on I4, 0.5 mA elsewhere) reflects that the first integrator is speed- and noise-critical while later stages are relaxed by shaping.

**If pushed — "why is the first opamp 6× the others?":** It sets the input-referred noise and must handle the fastest input currents; the assisted-opamp technique still lets it be far lower power than an unassisted design would need. Later stages are noise- and speed-relaxed by the preceding gain.

**If pushed — "these are the Q3.1 numbers?":** Yes — 55 dB / 2 GHz is exactly what I sweep in the finite-gain/BW non-ideality (slide 18), and my sweep confirms it is sufficient.

**Numbers/wording:** two-stage feed-forward compensation (no Miller cap), AC-coupled feed-forward, DC gain 55 dB, UGB 2 GHz, currents 3 mA / 0.5 mA, "CT tolerates slow settling".

---

## Slide 26 — Q4.4: Comparator latch · maps to Q4 · Figs 13-15

**On the slide:** Single-phase-clocked latch. Sampling phase: input amplified and held on drain parasitics. Regeneration phase: tail grounded → very high initial current → short regeneration time. Rail-to-rail CMOS output drives the latch directly (no CML level-shifters). Regenerative gain ~4 at 3.6 GS/s vs <1 for an equal-power CML latch → low metastability. **Conclusion:** the high-initial-current latch beats CML power at 3.6 GS/s and minimises metastability.

**Say this:** The comparator is a single-phase-clocked latch. In the sampling phase the input is amplified and held on the drain parasitics; in the regeneration phase the tail is grounded so there is a very high initial current, giving a short regeneration time constant. The output swings rail-to-rail CMOS and drives the following latch directly, with no CML level-shifters. At 3.6 giga-samples it reaches a regenerative gain of about 4, versus less than 1 for a CML latch of the same average power — that is what keeps metastability low at this speed.

**Mechanism:** Regeneration time τ ∝ 1/(initial current × gain); the high-initial-current topology makes τ short, so the latch resolves small inputs faster and the data-dependent metastability delay τd ≈ τ·ln(VFS/|vx|) is minimised. Rail-to-rail output avoids the static power and level-shift delay of CML. This is the circuit-level metastability fix; the first-tap-zero (slide 15) is the system-level one — they work together.

**If pushed — "why is CML worse here?":** CML dissipates static current and has limited swing, so for equal average power it cannot regenerate as fast at 3.6 GS/s (gain < 1), leaving comparator outputs unresolved → metastability. The dynamic high-current latch spends its power only during regeneration.

**If pushed — "regenerative gain 4 — meaning?":** The output grows by ~4× per clock during regeneration; enough to resolve to logic levels within the period for all but the smallest inputs, and those smallest inputs are handled by the first-tap-zero delay.

**Numbers/wording:** single-phase-clocked latch, high initial regeneration current, regeneration time constant, regen gain ≈ 4, rail-to-rail CMOS (no CML), metastability.

---

## Slide 27 — Q4.5: Clock — LC-PLL and LC-VCO · maps to Q4 · Fig 18

**On the slide:** On-chip LC-PLL: LC-VCO (cross-coupled NMOS, 2×2 nH, MOS varactor + trimmable MIM, 2.4-3.6 GHz), /128, PFD, charge pump, ~100 kHz loop BW. Supplies the low-jitter 3.6 GHz clock; LC-VCO phase noise (~ −120 dBc/Hz @ 1 MHz class) sets the jitter floor. **Conclusion:** the LC-PLL provides the GS/s clock whose jitter ultimately limits the modulator.

**Say this:** The clock is an on-chip LC-PLL. The core is an LC-VCO — cross-coupled NMOS with two 2-nH inductors, a MOS varactor plus a trimmable MIM bank, tuning 2.4 to 3.6 GHz. It divides by 128 to a low-frequency reference, with a PFD, charge pump, and about 100 kHz loop bandwidth. This supplies the low-jitter 3.6 GHz clock, and the LC-VCO's phase noise — around −120 dBc/Hz at 1 MHz offset — is what sets the modulator's ultimate jitter floor.

**Mechanism:** An LC tank VCO has much lower phase noise than a ring oscillator, which matters because clock jitter is the dominant limit on a wideband CT ΔΣ. The ~100 kHz loop BW is a compromise: wide enough to suppress VCO phase noise close to the carrier via the loop, narrow enough not to pass reference/charge-pump noise. Below the loop BW the reference dominates; above it the VCO dominates.

**If pushed — "why does jitter matter more here than for a DT modulator?":** In CT the fed-back charge per cycle is set by the DAC edge timing, so clock jitter directly modulates the feedback and injects in-band noise. A DT modulator samples voltages and is immune to edge shape. That is why they spend area on a clean LC-PLL — and why the FIR DAC (which reduces jitter sensitivity) is the enabling trick.

**If pushed — "PLL cost?":** ~0.25 mm² and 14.4 mW in the paper — significant, but the low jitter is essential for the wideband target.

**Numbers/wording:** LC-PLL, LC-VCO (cross-coupled NMOS, 2×2 nH, varactor + MIM bank), ÷128, PFD/charge pump, ~100 kHz loop BW, phase noise −120 dBc/Hz @ 1 MHz, jitter sets the floor.

---

## Slide 28 — Q5: Strengths and weaknesses · maps to Q5

**On the slide (table):**

| Technique | Strength | Weakness / cost | Verdict vs today |
|---|---|---|---|
| 1-bit ADC + FIR feedback DAC | multi-bit-like jitter tolerance + relaxed loop-filter linearity, 2-level linear DAC (no DEM) | adds group delay → needs compensation; FIR taps add area/routing | still the dominant idea, widely adopted after 2012 |
| Analog FIR-delay compensation (E(z)+H1(s)) | restores the NTF; bandpass keeps its own jitter/offset out of band; mostly analog | complex to design; extra opamp + matched replicas; RC-spread sensitive | partly superseded by digital ELD / dual-RZ |
| First FIR tap = 0 | ~40 dB metastability-floor recovery for ~free | costs one tap of filtering depth | clean, still used |
| RZ DAC ELD compensation | no power-hungry summer around the quantizer | RZ adds jitter sensitivity on that path | standard practice |
| CIFB + feed-forward, active-RC, assisted opamp | decoupled fast/precise paths, small caps, low opamp power | STF peaking → needs input pre-filter; many DAC feed-ins | typical for high-speed CT DSM |
| High-initial-current comparator latch | beats CML power at 3.6 GS/s | custom timing | fine |
| Digital ISI correction (post-facto) | recovers ~3-4 dB SNDR, confirms the ISI origin | off-line, single fixed alpha, not adaptive/on-chip | the obvious improvement target |

**Conclusion:** the paper solves jitter, loop-filter linearity and DAC linearity/DEM; the residual weakness is ISI-induced HD2, fixed only in post-processing (SNDR 70.9 vs ~95 dB SQNR target).

**Say this:** Technique by technique: the FIR feedback DAC is the big win — multi-bit jitter tolerance and relaxed linearity with a linear 2-level DAC and no DEM — and it is still the dominant idea today. Its cost is group delay, which needs the compensation path, and the compensation path is the main weakness: it is complex, needs an extra opamp and matched replicas, and is sensitive to RC spread — later work replaced it with simpler digital ELD. The first-tap-zero is a clean ~40 dB metastability fix for almost free. The RZ ELD DAC and the assisted-opamp active-RC loop are standard good practice, though the feed-forward causes STF peaking that needs pre-filtering. The real residual weakness is the ISI-induced HD2, which they only fix off-line with a single fixed alpha — that is the obvious improvement target.

**Say this — the one-line verdict:** The paper solves what it set out to — jitter, loop-filter linearity, and DAC linearity without DEM — and the gap from the 70.9 dB measured SNDR to the ~95 dB ideal SQNR is thermal noise plus ISI HD2, the latter only post-corrected.

**If pushed — "does each technique solve its issue?":** Yes: FIR → jitter + linearity (solved); first-tap-zero → metastability (solved, +40 dB); compensation → the FIR's own ELD (solved but complex); RZ DAC0 → raw ELD (solved). The one *not* fully solved on-chip is ISI, hence Q7.

**Numbers/wording:** "solves the initial issue?" verdict per technique, residual weakness = ISI HD2, 70.9 dB measured vs ~95 dB SQNR ceiling.

---

## Slide 29 — Q6: Comparison (extended Table II) · maps to Q6 · Table II, Figs 23/24

**On the slide (table):**

| Design (year) | Tech / Vdd | BW | DR | pk SNDR | Power | FoM_S | Key feature |
|---|---|---|---|---|---|---|---|
| This work '12 [1] | 90 nm / 1.2 V | 36 MHz | 83 | 70.9 | 15 mW | 176.8 | 1-bit, 8-tap FIR + analog ELD comp |
| Bolatkale '11 [9] | 45 nm / 1.1+1.8 V | 125 MHz | 70 | 65 | 260 mW | ~157 | 4-bit CT, cap-FF, direct ELD (no FIR) |
| Sukumaran '14 [10] | 180 nm / 1.8 V | 24 kHz | 103 | 98.2 | 280 µW | 182.3 | 1-bit FIR audio + ISI cal + dither |
| Zhang-Temes '15 [11] | 65 nm / 1.0 V | 15 MHz | 79.4 | 74.3 | 6.96 mW | ~172.7 | 2-bit, 3-tap FIR + digital ELD + DWA |
| Jain-Pavan '18 [12] | 65 nm / 1.4 V | 60 MHz | 76 | 67.6 | 13.3 mW | 172.5 | 1-bit 2× time-interleaved FIR |
| Billa '20 [13] | 180 nm / 1.8 V | 24 kHz | 104 | 100.9 | 265 µW | 180.5 | 1-X FIR-MASH, chopping |
| Theertham '22 [14] | 180 nm / 1.8 V | 250 kHz | 104 | 103.2 | 17.7 mW | 174.7 | 1-bit, 12-tap FIR + dual R2O DAC + chop |

**On the slide — where this work sits:** 2012: best FoM among SNDR>70 dB; highest BW among DR>80 dB designs. Today: beaten in efficiency by later FIR variants (Jain-Pavan, Billa, Theertham) that add time-interleaving, MASH, chopping, and circuit-level ISI fixes. **Conclusion:** foundational architecture; the FIR DAC idea persists, the compensation/ISI handling has moved on.

**Say this:** I extended the paper's Table II with the FIR-DAC lineage that followed. At publication in 2012 this work had the best FoM among converters above 70 dB SNDR and the highest bandwidth among designs above 80 dB DR. Bolatkale 2011 is the multi-bit counter-example: 125 MHz bandwidth but 260 mW and needing DEM — it shows what single-bit-plus-FIR trades away (bandwidth) and avoids (DEM, power). Then the FIR idea propagated: Zhang-Temes added *digital* ELD compensation replacing the analog path; Jain-Pavan time-interleaved the FIR for wider bandwidth; Billa built a FIR-MASH; Theertham added a dual return-to-open DAC that removes the ISI at circuit level. So the FIR DAC persists as the core idea, while the compensation and ISI handling have moved on.

**Mechanism (the framework):** Pavan-Baskaran's decision framework: quantizer levels dominate power → pick 1-bit; 2-level DAC is statically linear → no DEM; the only catch is jitter → FIR feedback shrinks the step to 2/N (jitter ↓ 20·log10(N)) and relaxes loop-filter linearity, at the cost of delay you stabilise by compensation. Each later paper extends one axis of this recipe.

**If pushed — "FoM definitions?":** FoM_Walden = Power/(2·BW·2^((SNDR−1.76)/6.02)) [fJ/conv-step, lower better]; FoM_Schreier = DR + 10·log10(BW/Power) [dB, higher better]. This work: 72.7 fJ/lvl, 176.8 dB.

**If pushed — "what do Figs 23/24 show?":** Literature survey scatter — BW vs DR, and power/Fnyq vs SNDR. This work sits at the high-BW edge for DR>80 dB and the best-FoM edge for SNDR>70 dB. Not MATLAB-reproducible; that is why they are the two figures I do not simulate.

**Numbers/wording:** FoM_S / FoM_W definitions, "best FoM >70 dB SNDR / highest BW >80 dB DR", digital ELD (Zhang-Temes), time-interleaved FIR (Jain-Pavan), FIR-MASH (Billa), dual return-to-open DAC (Theertham), Bolatkale = multi-bit alternative.

---

## Slide 30 — Q7: Improvement & verification · maps to Q7 · Figs 28/29/30

**On the slide — proposal:** in-loop / adaptive ISI correction (or a dual-RZ / return-to-open DAC).
- Why: the paper's HD2 (the SNDR limiter) is removed only off-line with a single fixed alpha.
- An adaptive digital alpha tracks process/temperature; a circuit-level dual-RZ/R2O DAC removes ISI directly.
- Updated architecture: keep the 8-tap FIR DAC, replace the post-facto correction with an in-loop ISI path.
- Verified in MATLAB: ISI on/off + correction, reproducing Figs 29/30.
- PSD: HD2 down ~15 dB (Fig 30). SNDR vs amplitude: kink removed (Fig 29).
- **Conclusion:** ISI correction recovers peak SNDR ~71 → ~76 dB and drops HD2 ~15 dB (reproduces Figs 29/30; paper 74.3).

**Say this:** My proposed improvement targets the one thing the paper leaves open: HD2 from DAC ISI, which is the SNDR limiter and is only removed off-line with a single fixed correction coefficient alpha. I propose making it adaptive and in-loop — a digital alpha that tracks process and temperature, or better, a circuit-level fix like a dual-RZ or return-to-open DAC that removes the ISI directly. The updated architecture keeps the 8-tap FIR DAC and replaces the post-facto correction with an in-loop ISI path. I verified the mechanism in MATLAB: turning ISI correction on drops HD2 about 15 dB and removes the SNDR-versus-amplitude kink, lifting peak SNDR from about 71 to about 76 dB, matching the paper's 74.3.

**Mechanism:** ISI = unequal DAC rise/fall → charge per pulse depends on the transition pattern → a code-dependent, even-order error → HD2 + raised floor. The paper models it as an ideal DAC plus a small pulse alpha injected at every rising edge, and corrects by subtracting a matching digital alpha sequence. A fixed alpha cannot track drift; an adaptive alpha or a return-to-open DAC (which makes every symbol see identical edges) fixes it robustly. Theertham 2022 is the real-silicon proof of the dual-R2O route.

**If pushed — "why is your improvement legitimate, not just re-doing the paper?":** The paper does the correction off-line to *confirm* the ISI origin. My contribution is making it adaptive/in-loop or circuit-level so it works on-chip over PVT — which is exactly the axis later literature (Theertham) validated. I verify the SNDR recovery in simulation.

**If pushed — "how did you model ISI to verify?":** Inject the even-order ISI error (alpha at each rising edge) into the CT DAC waveform, measure HD2 and the SNDR-vs-amplitude kink, then apply the correction sequence and show HD2 down 15 dB and the kink gone (Figs 29/30).

**If pushed — "alternative improvements?":** Digital ELD compensation (Zhang-Temes) to drop the complex analog compensation path; time-interleaved FIR (Jain-Pavan) for wider BW; FIR-MASH (Billa) to beat the OBG-1.5/MSA ceiling. ISI is the strongest because it directly lifts the *measured* SNDR limiter.

**Numbers/wording:** ISI, HD2 (even-order), fixed vs adaptive/in-loop alpha, dual-RZ / return-to-open (R2O) DAC, HD2 −15 dB, peak SNDR 71 → 76 (paper 74.3), Theertham 2022.

---

## Slide 31 — Summary / overall assessment

**On the slide:** In 2012 this paper made the case that a single-bit CT delta-sigma could compete with multi-bit at tens-of-MHz bandwidths by borrowing the multi-bit feedback waveform via an FIR DAC. The idea proved durable: FIR feedback is now standard across audio, biomedical and RF CT delta-sigma designs, and the same group extended it with time-interleaved FIR, FIR-MASH, chopping, and return-to-open DACs. Where the original is now beaten is in the details it left open: its analog FIR-delay compensation is complex and its ISI correction is off-line, both addressed by simpler digital-ELD and circuit-level dual-RZ/R2O techniques in later work. **Conclusion:** single-bit + FIR feedback solved the 1-bit jitter/linearity problem and remains relevant; the compensation and ISI blocks are where modern designs improve on it.

**Say this:** To sum up: in 2012 this paper showed a single-bit CT delta-sigma could compete with multi-bit at tens of MHz by borrowing the multi-bit feedback waveform through an FIR DAC. The idea proved durable — FIR feedback is now standard across audio, biomedical and RF converters, and Pavan's own group extended it with time-interleaving, MASH, chopping and return-to-open DACs. Where a 2025 redesign would improve it is exactly the two blocks it left rough: the analog compensation path, now done more simply with digital ELD, and the off-line ISI correction, now done at circuit level with a dual-RZ or return-to-open DAC. The FIR DAC itself I would keep — it solved the core 1-bit jitter and linearity problem and remains the right choice.

**Numbers/wording:** foundational + durable, keep the FIR DAC, replace compensation (→ digital ELD) and ISI handling (→ circuit-level R2O).

---

## Slide 32 — References

**On the slide (key ones):**
- [1] Shettigar & Pavan, JSSC 47(12), 2012 — the paper.
- [2] Cherry & Snelgrove, TCAS-II 46(6), 1999 — clock jitter & quantizer metastability (the jitter/metastability model).
- [3] Su & Wooley, JSSC 28(12), 1993 — current-mode semi-digital reconstruction filter (the semi-digital FIR DAC origin).
- [4] Pavan, TCAS-I 57(8), 2010 — efficient simulation of weak nonlinearities (the Fig-3 method).
- [5] Pavan & Sankar, JSSC 45(7), 2010 — assisted-opamp technique.
- [6] Adams & Nguyen, JSSC 33(12), 1998 — segmented noise-shaped scrambling.
- [7] Lee, MIT MS thesis, 1987 — higher-order interpolative modulator (Lee's rule).
- [8] Mitteregger et al., JSSC 41(12), 2006 — 20-MHz-BW CT ΔΣ.
- [9] Bolatkale et al., JSSC 46(12), 2011 — 4 GHz CT ΔΣ, 125 MHz BW (multi-bit counter-example).
- [10] Sukumaran & Pavan, JSSC 49(11), 2014 — single-bit audio FIR feedback.
- [11] Zhang et al., TCAS-I 62(7), 2015 — digital ELD + FIR.
- [12] Jain & Pavan, TCAS-I 65(2), 2018 — time-interleaved FIR feedback.
- [13] Billa, Dixit & Pavan, JSSC 55(10), 2020 — 1-X FIR-MASH.
- [14] Theertham et al., JSSC 57(11), 2022 — dual return-to-open DACs.

**Say this:** The load-bearing references are Cherry & Snelgrove for the jitter and metastability model, Su & Wooley for the semi-digital FIR DAC origin, Pavan 2010 for the weak-nonlinearity simulation method, and Pavan & Sankar for the assisted opamp. The later works — Zhang-Temes, Jain-Pavan, Billa, Theertham — are the ones I use for the comparison and improvement slides.
