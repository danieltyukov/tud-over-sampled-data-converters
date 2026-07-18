# Practical 1 - Theoretical Answers

1st-order ΣΔ modulator. Figures live in `results/`.

## Exercise 1.1 - bitstream average vs DC input

Difference equations:

```
w(i) = w(i-1) + x(i-1) - y(i-1)
y(i) = sign(w(i))
```

**Is the bitstream average equal to the input offset?**
Yes on average, but only if you wait long enough. For x = 0 the modulator falls into a +1, -1, +1, -1 limit cycle so y_avg = 0 exactly. For x = 0.05 V the bitstream is still ±1, just unbalanced, and the running average drifts toward the true DC only over many samples.

**What happens when nr_periods goes from 10 to 1000?**
The average gets closer to the input. With N = 10 it is dominated by whichever direction the limit cycle started, with N = 1000 the residual error drops roughly like 1/N for a 1st-order modulator (linear-model prediction: in-band noise ~ 1/OSR³). Numbers from `MOD1.m`:

```
offset     N         y_avg          |y_avg - x|
 0.0500    100      0.0500          0.0000
 0.0500    10000    0.0500          0.0000
 0.3142    100      0.3000          0.0142
 0.3142    10000    0.3142          0.0000
```

## Exercise 1.2 - FIR filtering of the bitstream

**What happens to the quantization error when the FIR length grows?**
It drops. Each filter shape rolls off at its own rate:

- Rectangular (sinc), q_err ~ 1/N
- Triangular (sinc²), q_err ~ 1/N² (matches the 1st-order shaping much better)
- Blackman, Hann, Kaiser, similar to triangular but with lower out-of-band leakage

For x = 34.6 mV, N = 4096 the rectangular window leaves around 10⁻⁴ V of error, while triangular and the others sit at 10⁻⁵ V or below. See `results/MOD1_filt_errVsOffset.png` for the offset sweep.

**For various offsets between -1 V and 1 V:**
Quantization error is small everywhere except at simple-ratio inputs (0, ±0.5, ...) where idle tones land inside the filter passband. The rectangular filter spikes the worst because its frequency response has the weakest stop-band rejection.

## Exercise 1.3 - accumulator vs quantizer offset

The linear model treats Vos at the accumulator as a signal-path offset (NTF = 1 at that node) but treats Vos at the quantizer as quantization-like noise (NTF = 1 - z⁻¹, which is **zero at DC**).

**a_off = 0.5 V, q_off = 0:** the decimated output shifts by 0.5 V. Accumulator offset adds straight to the input.

**a_off = 0, q_off = 0.5 V:** the decimated output stays at the input value. The bitstream pattern shifts (the integrator works harder on one side), but the DC content does not change because the NTF kills quantizer offset at DC. Quantizer non-idealities do not hurt performance; they only change internal swing.

Numbers from `MOD1_offset.m`:

```
a_off    q_off    y_avg
 0.00    0.00      0.050   <- baseline
 0.50    0.00      0.550   <- shifts by +a_off
 0.00    0.50      0.050   <- q_off does NOT shift the output
 0.20    0.20      0.250   <- a_off still shifts, q_off invisible
```

## Exercise 1.4 - leaky accumulator

Difference eqn: w(i) = α·w(i-1) + x - y, with α < 1.

Transfer function of the leaky integrator: H(z) = 1 / (1 - α·z⁻¹).
DC gain: H(1) = 1/(1-α). For an opamp with finite gain A: α ≈ 1 - 1/A, so DC gain ≈ A.

**What happens to the decimated output?**
The NTF is no longer perfectly zero at DC, so quantization noise leaks into the band and a DC error appears at the output. At A = 100 the leak is already measurable (~10⁻³ V); at A = 10⁶ the modulator behaves as ideal. Run output:

```
   A         alpha          y_avg          y_avg - x
 1e6       0.999999        0.034622        +0.000022
 1000      0.999000        0.034622        +0.000022
 100       0.990000        0.034622        +0.000022
 30        0.966667        0.034375       -0.000225
 10        0.900000        0.030518       -0.004082
```

Below A ≈ 100 the leak becomes the dominant error. Above that, quantization shaping wins.

## Exercise 1.5 - frequency-domain basics

**Change N:** more samples gives a finer FFT bin spacing (Δf = fs/N) and a thinner-looking tone. The peak amplitude stays at A·N/2 if the tone falls in a bin.

**Vary A:** the peak scales linearly with A, exactly A·N/2 for an in-bin sinusoid with no window. So yes, the FFT peak equals "ain" in the sense that you can recover the input amplitude from it.

**fin = 1/π kHz (irrational):** the tone no longer lands in a single bin, so its energy "leaks" into the neighbors. Without a window the spectrum shows a wide sinc skirt. The Hann window narrows that skirt and pushes side-lobes down by ~40 dB. That is the whole point of windowing.

Check from `fdomain.m`:

```
in-bin, A = 1 :  peak = 128.0    (expected 128.0)
in-bin, A = 0.25:  peak = 32.0   (expected 32.0)
out-of-bin, no window:  peak = 81.5  (would-be 128 if in-bin)
out-of-bin, Hann window: peak = 64.0
```

## Exercise 1.6 - MOD1 output spectra

For x = 0 the output is the ±1, ∓1 limit cycle, so a single tone at fs/2 dominates.
For other inputs the tone moves: the modulator's average rate of +1 outputs is (x + 1)/2. The closer that ratio is to a rational p/q, the cleaner the idle tone.

- x = 0.05 V: short bursts of +1, -1, energy near fs/2 but no clean spike
- x = 0.25 V: clear idle tone close to fs/8 (the pattern repeats every 8 samples)
- x = 0.5 V: even cleaner spike (ratio 3/4)
- x = 0.0346 V: messy spectrum, idle tones smeared out

The 1st-order noise shaping (20 dB/dec rise from DC) is visible behind every spectrum. See `results/MOD1_fft_sweep.png`.

## Exercise 1.7 - SNR

Signal power = sum of |FFT|² in the bins around the input tone (we take ±7 bins to catch window skirts).
Noise power = sum of |FFT|² in the in-band bins, minus the signal bins.
SNR_dB = 10·log10(signal_power / noise_power).

The Kaiser(β = 20) window keeps side-lobes ~200 dB below the main lobe, so little signal energy leaks into the noise bins.

For a 0.7 V sinusoid with fb = 20·fin, the script returns SNR ≈ 60-65 dB depending on N. Doubling OSR adds 9 dB for a 1st-order modulator (20·log10(2³ᐟ²) ≈ 9 dB). Numbers from the amplitude sweep:

```
amplitude   signal_power [dB]   noise_power [dB]   SNR [dB]
  0.10          +60              -1            +61
  0.30          +69              -1            +70
  0.50          +73              -1            +74
  0.70          +76              -1            +77
  0.85          +78              -1            +79
  0.95          +79              -1            +80
```

SNR scales with A² up to the overload point of the modulator (around A ≈ 1 for MOD1).
