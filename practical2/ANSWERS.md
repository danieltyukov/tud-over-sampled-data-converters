# Practical 2 - Theoretical Answers

2nd-order ΣΔ modulators: feedback, feed-forward, local feedback, noise, and CT. Figures live in `results/`.

## Exercise 2.1 - 2nd-order modulator, time domain (`MOD2.m`)

Difference equations (delay-free 1st accumulator):

```
w2(i) = w2(i-1) + w1(i-1) - a·y(i-1)
y(i)  = sign(w2(i))
w1(i) = w1(i-1) + x(i-1) - y(i)
```

**Bitstream average and quantization error, sinc1 vs sinc²:**
For x = 50 mV the sinc1 filter already gets the right average to 6 digits. For x = 34.6 mV (an awkward non-integer ratio) sinc1 leaves ~1.4e-3 V of residual, while sinc² gets down to ~8e-6 V. So sinc² is much better. It matches the 2nd-order noise shape (40 dB/dec) closer than the flat sinc1.

**nr_periods from 100 to 1000 (10x more samples):**
Per the linear model, in-band noise of MOD2 scales as 1/OSR⁵, so q_rms ∝ OSR⁻⁵ᐟ². A 10x increase in N should drop q-error by 10²·⁵ ≈ 316x. Measured ratio with sinc² is ~75x, with sinc1 only ~3.86x. Sinc1 just does not cut deep enough to reveal the shaping.

```
   N        Q-err(sinc1)     Q-err(sinc²)
  100       +5.4e-3          +6.0e-4
 1000       +1.4e-3          +8e-6
 ratio       3.86             75.00
```

**Linear-model factor:** if OSR doubles, in-band noise drops by 4·√2 ≈ 5.7x (~15 dB). Equivalently ΔSNR = 10·log10(ΔOSR⁵) = 2.5·(20·log10(ΔOSR)).

**Reducing the stabilizing coefficient "a":**
Smaller a moves the NTF zeros off DC (a = 1 keeps NTF = (1-z⁻¹)²), so noise leaks into the band and q-error grows. The accumulators swing harder too: max|w2| explodes from ~2.6 at a = 1 to ~95 at a = 0.

At a = 0 the modulator is unstable (no feedback gain on y), w2 runs away. A 1-bit modulator is a clocked oscillator, so "stable" here means the internal states stay bounded by the sample-by-sample re-quantization, not the textbook pole-in-unit-circle sense.

## Exercise 2.2 - SNR vs stabilizing coefficient `a` (`MOD2_SNR.m`)

Baseline (a = 1, delay-free 1st acc, A = 0.7, fin = 2 kHz, fb = 4 kHz, fs = 1000 kHz):

```
SNR = 85.62 dB
```

**As "a" drops below 1, the SNR drops.** Reason: NTF = (1 - z⁻¹)² only has its zero at DC when a = 1. Move a, and the zero leaves z = 1, so quantization noise leaks into the band. Reduce a too far and the integrators overload, dumping wideband noise everywhere.

**Delayed 1st accumulator** (w1 update uses (i-1) values on both sides):
Theory predicts a* = 2·a keeps the loop filter shape intact. The script sweep confirms:

```
delay-free  a  = 1     SNR = 85.62 dB
delayed     a* = 2.15  SNR = 86.43 dB  (max of sweep)
```

So switching to a delayed integrator with a* ≈ 2 reproduces the same NTF, with one extra clock cycle of latency. The 1-2 dB gap is variance from limit-cycle behavior, not a real architectural difference.

## Exercise 2.3 - feedback topology scaling (`MOD2_FB.m`)

Unscaled coefficients: b1 = b2 = 1, a1 = 1, a2 = 2.
With those, max|w1| ≈ 3.16 V, max|w2| ≈ 6.18 V at A = 0.7. Way too big for a real opamp.

**Scaled** to keep both swings under 0.2 V:

```
b1* = 0.063,  b2* = 0.51,  a2* = a2·b1 = 0.126   (a1 stays = 1)
```

These come from b1* = 0.2 / max|w1|, then b2* = 0.2 / (b1*·max|w2|). The slide-17 rule a* = a·b1 keeps H*(z) = b1·b2·H(z), so the loop filter has the same shape, only its gain is rescaled.

**STF and NTF after scaling:** with a 1-bit quantizer the comparator only sees the sign, so internal gain scaling does not change which side of zero w2 lands on. NTF and STF stay unchanged. SNR before and after scaling agrees (~82 dB in both cases).

## Exercise 2.4 - feed-forward topology (`MOD2_FF.m`)

**Why does w1 look different in FF vs FB?**
In the FB topology, w1 sees the low-frequency input directly, so its waveform tracks the input sine plus shaped noise. In the FF topology, the input only reaches w1 through (x - y), and the bitstream y is the input plus high-frequency q-noise. So w1 ends up as a high-pass-filtered version of x. The big low-frequency content disappears, w1 looks like pure shaped noise.

**Scaling** for A = 0.7, |w1|, |w2| < 0.2 V:

```
b1* = 0.110,  b2* = 0.299,  c1* = c1·b2* = 0.597,  c2* = 1
```

Same logic as FB: c* = c·b2 keeps H(z) shape (slide 22), so STF and NTF survive scaling.

**Delay-less 2nd accumulator:**
"Delay-less" means w2 uses w1 of the *current* sample, not (i-1). The loop is one cycle faster, which makes it less stable. The FF gain c* has to come down (halving works in practice) to keep the modulator bounded. NTF and STF reshape, but at low signal frequencies the difference is minor.

## Exercise 2.5 - local feedback / resonator (`MOD2_FB_localFB.m`)

Adding the d-feedback path turns the second accumulator into a resonator. The NTF zeros move off DC, creating a notch inside the signal band:

```
fnotch ≈ √d · fs / (2π)
```

Schreier's rule of thumb: the optimum notch is at fnotch = fb/√3, which for fs = 5600 kHz, fb = 20 kHz lands near d ≈ 1.7e-4. Measured sweep:

```
   d         SNR [dB]
   0           87.31    (no notch, plain MOD2)
 5e-5          87.96
 1e-4          89.57
 1.5e-4        90.27
 1.7e-4        90.28    <- maximum
 2e-4          89.49
 3e-4          87.26
 5e-4          82.21    (notch outside fb, gets worse)
```

About 3 dB of free SNR vs d = 0. The catch: putting the notch where the band needs it also lowers the max stable amplitude, so you trade dynamic range for in-band SNR.

**Scaled coefficients** for A = 0.5, |w1|, |w2| < 0.2 V:

```
b1* = 0.073,  b2* = 0.65,  a2* = 2·b1* = 0.146,  d* = d / (b1·b2) = 3.6e-3
```

After scaling: SNR = 89.94 dB, basically unchanged from the unscaled 90.3 dB.

## Exercise 2.6 - thermal noise (`MOD2_noise.m`)

Thermal noise is white with one-sided PSD Sn. With oversampling, only Sn·fb of it lands in the signal band, so in-band noise is OSR-times smaller than total noise.

**Where you inject the noise matters.** Each summing node sees a different NTF:

- 1st integrator input: STF = 1 in-band, so noise is **not shaped**. Flat into the band (0 dB/dec).
- 2nd integrator input: one integrator of shaping = 20 dB/dec rise.
- Quantizer input: full 2nd-order shaping = 40 dB/dec rise.

That ranking sets the noise budget. To hit SNR = 90 dB with A = 0.7 V:

```
n1_rms ≈ 200 µV   (1st integrator)
n2_rms ≈ 30 mV    (2nd integrator)  -- ~43 dB looser
nq_rms ≈ 0.6 V    (quantizer)       -- ~70 dB looser
```

Simulated SNRs at those operating points come out near 91 dB each. So thermal noise is dominated by the **first** integrator. That is the opamp you have to spend power on. Practical numbers come from kT/Cs: in switched-cap, sampling noise = 2kT/Cs per opamp, so the first stage's Cs sets the analog area and power.

## Exercise 2.7 - continuous-time modulator (`MOD2_CT.m` / `MOD2_CT1.m`)

MATLAB is discrete, but the CT loop filter is continuous. Trick: over-sample each sampling period nr_steps times, advance the continuous integrators forward in tiny steps, then evaluate the quantizer once per sampling period.

For a CT integrator with transfer function ω/s, applying a unit input for a calculation step of duration T = 1/(fs·nr_steps) produces a ramp of height ω·T. So inside the MATLAB loop:

```
omega1 = (2π·ft1) / (fs · nr_steps)
```

Pick ft1 = fs/something to land the integrator's unity-gain frequency where you want. For the Assignment 3 specs (SQNR = 100 dB, SNR = 90 dB in 20 kHz BW, OSR = 250, fs = 10 MHz) the slide says omega1 = 2π·fs/(fs·nr_steps), c1 = 4π, b1 = 0.05, b2 = 0.055. Those keep the integrator outputs under 0.5 V at A = 0.7.

## Exercise 2.8 - DAC asymmetric rise/fall (`MOD2_CT_NRZDAC.m`)

A real single-bit DAC has different rise and fall slopes. The **area under the pulse** depends on the previous output bit, so a 0, 1, 1, 1, 0 sequence has different energy than 1, 0, 1, 0, 1. That is intersymbol interference (ISI) in CT modulators.

ISI mixes shaped quantization noise with the input data, so harmonics of the input show up inside the band, and the noise floor at low frequency rises. The output spectrum gets messy near DC.

The script switches between an asymmetric DAC (default) and a symmetric one (uncomment the second block). With asymmetric DAC and a 10 kHz input you lose SNR compared to ideal; the exact loss depends on how much the rise and fall differ. Defense against ISI: return-to-zero (RZ) or dual-return-to-zero (DRZ) DACs that force every pulse to look the same regardless of neighbors. CT modulators routinely use those.
