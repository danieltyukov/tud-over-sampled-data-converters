# Practical 3 - Theoretical Answers

Week 5 material: continuous-time recap (2.7/2.8), multi-bit DACs with DEM and DWA,
1-1 MASH, and band-pass modulators. Figures live in `results/`.

Note: this MATLAB install has no Deep Learning Toolbox, so `mbq.m` no longer calls
`quant()`. It now rounds to the level grid directly (`δ·round((in/Vref+1)/δ) - 1`),
which is exactly what `quant` did.

## Exercise 2.7 / 2.8 - CT modulators (carry-over)

These are the continuous-time exercises from Week 3 and are already written up in
`practical2/ANSWERS.md` (2.7 = FB→FF CT modulator sized for Assignment 3, 2.8 = NRZ
DAC with asymmetric rise/fall and the ISI it causes). The starter files
`MOD2_CT.m` and `MOD2_CT_NRZDAC.m` here are the same ones. Short version:

- 2.7: over-sample each clock period `nr_steps` times, step the CT integrators
  forward, quantize once per sample. ω1 = 2π·fs/(fs·nr_steps), c1 = 4π, b1 = 0.05,
  b2 = 0.055 keeps the integrators under 0.5 V at A = 0.7 and OSR = 250.
- 2.8: asymmetric DAC pulse area depends on the previous bit ⟹ intersymbol
  interference, which mixes shaped q-noise back into the band and raises the
  low-frequency floor. RZ/DRZ DACs fix it.

## Exercise 3.1 - multi-bit DAC, mismatch and DEM (`MOD2_3Bit_ThermoDAC.m`)

8-level (3-bit) 2nd-order feedback modulator, OSR = 60, A = 0.7. With perfectly
matched unit elements the thermometer DAC is linear and you get the full

```
matched elements           SNDR = 91.5 dB
```

The DAC sits in the feedback path, so its error is subtracted straight from the
input and is **not** noise-shaped (unlike the quantizer noise). Add 1% random
element mismatch and use a static thermometer DAC (always elements 1..index):

```
1% mismatch, static (no DEM)  SNDR = 47.8 dB
```

The mismatch is correlated with the code, so it shows up as harmonic tones. The
in-band zoom shows HD2 ≈ −68 dB, HD3 ≈ −72 dB, HD4 ≈ −83 dB, plus a bit of DC
offset. That is why SNDR (signal vs noise + distortion) is the honest metric here,
not SNR.

**DEM by randomization** (`thermoDACrnd.m`, a fresh `randperm` of which elements go
to +1 every sample) breaks the code-to-element correlation:

```
1% mismatch + DEM (random)    SNDR = 63.9 dB
```

About +16 dB. The tones are gone (figure `..._inband.png`), turned into a white
noise floor sitting around −100 dB across the band. Randomization does **not**
shape the mismatch, it only whitens it, so the floor is flat and still limits SNDR.

How much it improves and what happens to the tones: tones → white noise, SNDR up by
~16 dB. Why: the error per sample is now uncorrelated with the input code, so its
power spreads evenly instead of folding onto harmonics of the tone.

Figures: `MOD2_3Bit_matched_vs_mismatch.png`, `MOD2_3Bit_DEM_DWA_spectrum.png`,
`MOD2_3Bit_DEM_DWA_inband.png`.

## Exercise 3.2 (extra) - Data Weighted Averaging (`MOD2_3Bit_ThermoDAC.m`)

DWA picks `index` consecutive elements starting from a pointer, then advances the
pointer by `index` (wrapping mod 7). The pointer is kept between cycles, that memory
is the whole point. After one full lap through the elements the accumulated mismatch
error returns to ~0, so the error sequence `e[n] = s[n] - s[n-1]` is the first
difference of a bounded, roughly white `s[n]`. That is **1st-order high-pass
shaping** of the mismatch:

```
1% mismatch + DWA             SNDR = 91.6 dB
```

DWA recovers essentially the matched-element performance. In `..._spectrum.png` the
DWA curve (green) has a clear 20 dB/dec rising slope: the mismatch energy is pushed
out of the 20 kHz band. With OSR = 60 the shaped mismatch sits well below the
quantization floor, so SNDR is back to the ~91.5 dB limit.

Ranking is exactly what the theory predicts:

```
static  47.8 dB   tones, mismatch unshaped and correlated
random  63.9 dB   no tones, mismatch white
DWA     91.6 dB   no tones, mismatch 1st-order shaped
```

Catch with DWA: for small / DC inputs the pointer walks in a near-periodic way, so
the "noise" becomes tonal again (the lecture's low-amplitude DWA tones). Random DEM
avoids tones but pays a higher flat floor.

## Exercise 3.3 - 1-1 MASH (`MOD1_for_MASH.m`)

Two 1st-order loops. Stage 2 digitizes the quantization error of stage 1, then a
digital filter recombines:

```
w1(i) = α·w1(i-1) + in(i-1) - y1(i-1)      first stage
y1(i) = sign(w1(i))
q1(i) = y1(i) - w1(i)                        stage-1 quant error
w2(i) = α·w2(i-1) + q1(i-1) - y2(i-1)      second stage
y2(i) = sign(w2(i))
y(i)  = y1(i-1) - (y2(i) - y2(i-1))          digital cancellation
```

In z-domain with α = 1: Y1 = z⁻¹X + (1−z⁻¹)Q1, Y2 = z⁻¹Q1 + (1−z⁻¹)Q2, and the
recombination Y = z⁻¹Y1 − (1−z⁻¹)Y2 cancels Q1 exactly:

```
Y(z) = z⁻²·X(z) − (1−z⁻¹)²·Q2(z)
```

So the output is a delayed input plus **2nd-order** shaped quantization noise, built
from two unconditionally stable 1st-order loops.

**Noise shaping (Y, Y1, Y2):** `MASH_Y_Y1_Y2.png`. Y1 and Y2 each fall at 20 dB/dec
(1st order). The recombined Y falls at 40 dB/dec (2nd order) and has the lowest
in-band floor. Y2 sits highest because its "signal" is the tiny q1, so its relative
noise is large.

**Sizing for the Assignment-3 specs** (SQNR = 100 dB, SNR = 90 dB in 20 kHz BW):
OSR = 200 ⟹ fs = 2·20k·200 = 8 MHz. Noiseless run at A = 0.7:

```
MASH  A=0.7  OSR=200   SQNR = 100.5 dB
```

Thermal noise added at the first integrator input, white over the whole band so
total rms = in-band rms · √OSR:

```
noise_rms = A/√2 / 10^(90/20) · √OSR
MASH  A=0.9  with thermal noise   SNR = 89.9 dB
```

**Optimum amplitude:** `MASH_SNR_vs_amplitude.png`. With a fixed thermal noise the
SNR is signal-limited, so it climbs monotonically from ~71 dB at A = 0.1 to ~90 dB,
peaking near full scale (A ≈ 0.95). Best to run the MASH as close to full scale as
the loops stay clean.

**Difference vs a single-loop 2nd-order modulator:** same OSR, A = 0.7:

```
MASH single stages (1-bit each)   SQNR = 100.5 dB
single-loop MOD2 (1-bit)          SQNR =  95.4 dB
```

Both give 2nd-order shaping, but the MASH wins a few dB and, more importantly, is
built from two 1st-order loops that can never go unstable, so it tolerates a higher
input than a single-loop 2nd-order 1-bit modulator. The price: its output is
multi-level (`y ∈ {−3, −1, 1, 3}`, occasionally 0) instead of 1-bit, and it needs
the analog NTF1 to match the digital filter.

**Integrator leakage** (lower α): `MASH_leakage.png`.

```
α = 1.00    SQNR = 102.7 dB
α = 0.99    SQNR =  70.7 dB
```

A 1% leak costs 32 dB. Reason: the cancellation only works if the analog NTF1 = (1−z⁻¹)
matches the digital filter. With α < 1 the real NTF1 = (1−α·z⁻¹), so Q1 no longer
cancels and leaks through 1st-order shaped. That 1st-order leftover dominates the
band and flattens the floor to ~0 dB (the α = 0.99 curve). MASH is far more sensitive
to integrator gain than a single-loop modulator, which just re-quantizes its own
error and does not rely on cancellation.

## Exercise 3.5 - band-pass modulator (`MOD2_BP.m`)

The BP modulator is the LP feedback modulator with z⁻¹ → −z⁻², which moves the NTF
notch from DC to fs/4. Each 1/(z−1) integrator becomes −1/(z²+1), a resonator at
fs/4, and the difference equations pick up a 2-sample delay:

```
w2(i) = −w2(i-2) − (w1(i-2) − a·y(i-2))
w1(i) = −w1(i-2) − (in(i-2) − y(i-2))
y(i)  = sign(w2(i))
```

**Notch at fs/4:** `MOD2_BP_spectrum.png` shows a deep symmetric notch at
fs/4 = 250 Hz, with the input tone (250.003 Hz) spiking out of it. The noise rises
on both sides (2nd-order band-pass shaping). The notch is at fs/4 because z⁻¹ → −z⁻²
maps the DC zero (z = 1) to z = ±j, i.e. ±π/2, which is fs/4.

**SNR in a band around fs/4 (the fix):** the original code measured the band at DC
(`inband_bins = [1:fb/fres]`), which is wrong for a BP modulator (no notch there).
The band must straddle fs/4: `[fs/4 − fb/2, fs/4 + fb/2]`. With fb = 4 Hz:

```
band-pass (band at fs/4)   SNR = 85.9 dB
low-pass  (band at DC)     SNR = 87.1 dB
difference (LP − BP)        1.2 dB
```

**Difference between LP and BP SNR:** basically none. The z⁻¹ → −z⁻² transform keeps
the same shaping order and notch depth, it only relocates the notch to fs/4. So for
the same bandwidth fb the BP modulator gives the same SNR as the LP prototype (the
~1 dB is the usual limit-cycle variance). Useful when you want to digitize a signal
already centered near fs/4 (IF sampling) without first mixing it down to baseband.
Figures: `MOD2_BP_band_zoom.png`, `MOD2_BP_vs_LP.png`.
