# MATLAB Model — Rules & Requirements (no code here, just the spec)

This is the build spec for the MATLAB that reproduces Shettigar & Pavan 2012. It says **what must exist, what each script must plot, how to scale it to match the paper, and how to iterate it** — it deliberately does **not** contain the code. Write the code to the conventions in `08_coding_practices.md` (which mirrors the student's existing assignment/practical style). Math here is Unicode; the `.m` files must be **ASCII-only**.

---

## 0. Hard environment rules (from the repo's established practice + memory)

1. **No Schreier `delsig` toolbox.** None of the 38 existing `.m` files use it, and there is no `addpath`. Build NTF/STF, loop filter and simulation **by hand** (difference equations + analytic transfer functions). Do **not** introduce `synthesizeNTF/realizeNTF/simulateDSM/calculateSNR`.
2. **No Deep Learning Toolbox / `quant()`** — it errors on this machine. Quantise with `sign()` or `2*(w>=0)-1` (1-bit) and `q*round(x/q)` (multi-bit, see `mbq.m`).
3. **ASCII-only** in every `.m` file (comments, strings). Unicode math only in `.md` write-ups.
4. **Headless-friendly:** scripts run top-to-bottom and **save every figure** to `results/`; run with `matlab -nodisplay -batch "scriptname"`. Guard the dir: `if ~exist('results','dir'), mkdir('results'); end`.
5. **Seed RNG** before any random run (`rng(1)` etc.) so results are reproducible and live-demoable.
6. **Comment voice:** terse, lower-case, student style; no em-dashes; no AI-isms.
7. **Every script starts with a parameter block** (see §2) so any value can be changed **live during the oral** and the effect shown — this is the lecturer's explicit "see how they can be malleably changed" requirement.

---

## 1. Global spectral / SNR conventions (match existing code exactly)

- **Window:** `kaiser(N, 20)` always (the repo standard). The paper used 32-K Blackman–Harris; note the difference on the slide but use Kaiser for consistency with the course.
- **Coherent sampling:** pick an integer number of input periods so the tone lands in one bin (`nr_points = round(nr_periods*fs/fin)` or CT `N = ceil(fs/fres)`).
- **dBFS scaling:** normalise the FFT magnitude by the full-scale-sine peak `A*N/2` so the spectrum reads in true dBFS (the CT-assignment convention), **not** peak-normalised — this is what lets your PSD overlay the paper's.
- **SNR/SNDR by hand-rolled bin summation** (no `calculateSNR`):
  - `fres = fs/N`; `maintone = round(fin/fres)` (or `nr_periods+1` in CT scripts).
  - `signal_bins = maintone-7 : maintone+7` (15 bins ≈ Kaiser(20) main lobe).
  - `inband_bins = 1 : round(fb/fres)`; `noise_bins = setdiff(inband_bins, signal_bins)`.
  - `SNR = 10*log10(sum(P(signal_bins)) / sum(P(noise_bins)))`.
  - **SNDR**: keep harmonics in the noise sum. **SNR** (floor only): also exclude `harm_bins` (k·maintone ± 3, k=2..5). Report **HD2/HD3** in dBc as in Figs 21/22.
- **Frequency axis:** `(1:N/2)*fres` with `semilogx`; scale to Hz if the unit base is kHz.
- **Signature spectrum plot:** full PSD (semilogx) + in-band band overdrawn in green (LineWidth 3) + main tone in red (LineWidth 3) + `grid on`, `xlabel('Frequency (Hz)')`, `ylabel('Amplitude (dBFS)')`, `legend`.

---

## 2. Model parameters (top-of-file block; the "knobs")

Expose at least these as named variables (with the paper's values as defaults):

```
fs        = 3.6e9          % sampling rate
fb        = 36e6           % signal bandwidth (also run 25e6)
OSR       = fs/(2*fb)      % ~50
order     = 4              % NTF order
OBG       = 1.5            % out-of-band gain (Lee's rule, 1-bit)
Ntap      = 8             % FIR DAC taps
firtaps   = [0.07 0.12 0.15 0.16 0.16 0.15 0.12 0.07]
fz_notch  = fb/sqrt(3)     % optimised NTF zero placement (Schreier rule)
nr_steps  = 20             % CT integrator sub-steps per clock (existing CT convention)
fin       = ...            % coherent input tone (e.g. ~10 MHz, adjusted to a bin)
amplitude = 0.7            % default test amplitude (full scale = 1)
% non-ideality knobs (default = ideal/off):
jitter_rms = 0; jitter_fmod = 0;     % clock jitter (white & FM)
A_dc = inf; ugb = inf;               % opamp DC gain & unity-gain BW
eld   = 0;                           % excess loop delay (fraction of Ts)
tapmismatch = 0;                     % FIR unit-element sigma
g3 = 0;                              % integrator weak-cubic coefficient
noise_rms = 0;                       % input-referred thermal noise
isi_dtr = 0; isi_dtf = 0;            % DAC rise/fall asymmetry; isi_corr = 0/1
```

Setting all non-ideality knobs to off must give the **ideal** curves (Figs 8/9 NTF/STF, clean PSD).

---

## 3. Modelling rules per block

> **Precise, paper-sourced models for the starred blocks below are in `09_reference_notes.md`** (extracted from the downloaded PDFs): jitter error-per-edge + σ_δy² table (A.1), metastability equivalent-jitter shortcut (A.2), the weak-nonlinearity two-run method + "1k,20,20" (A.3), assisted-opamp finite-gain/BW model (A.4), and the **compensation closed-form** to derive E(z)/k̂₂/F_c (B.2–B.3). Use those numbers rather than approximating.

### 3.1 NTF / loop-filter coefficients (derive, don't toolbox)
- Target: 4th-order, **OBG = 1.5**, **two NTF zeros optimised** off DC (notch ≈ f_b/√3, the course's resonator rule) → in-band notches like Fig 8.
- Build the NTF by hand (place 4 zeros: 2 at/near DC region as a complex pair at the notch + the maximally-flat highpass shape; poles from the Butterworth/inverse-Chebyshev-style OBG-1.5 denominator). Map the discrete prototype to the **CT CIFB** integrators ω₁…ω₄ via **impulse invariance** (the course's CT mapping), accounting for the z⁻¹ᐟ² loop delay.
- **Scale** integrator coefficients so each state stays < ~0.45–0.5 (first-order path saturates last). Scaling must not change NTF/STF (1-bit).
- Plot the realised **|NTF| vs f/Fs** (reproduce Fig 8: with and without the H₁(s) kink) and **|STF|** (reproduce Fig 9: ~+12 dB peak ~100 MHz from feed-forward).
- **Derivation method (since Shettigar's thesis is unavailable — see `09_reference_notes.md` §B.2/B.3):** map the CT paths with the exact DT equivalents [1/s→z⁻¹/(1−z⁻¹); 1/s²→½(z⁻¹+z⁻²)/(1−z⁻¹)²; 1/s³→(z⁻¹+4z⁻²+z⁻³)/6/(1−z⁻¹)³; 1/s⁴→(z⁻¹+11z⁻²+11z⁻³+z⁻⁴)/24/(1−z⁻¹)⁴]; solve k₁H₁+…+k₄H₄ = 1/NTF − 1 for the prototype gains; then for the FIR loop keep the highest-order k̂₄=k₄ and re-derive the inner gains so the NTF is held, and add E(z)=M₁(z) where 1−F(z)=M₁(z)(1−z⁻¹) (7 taps for N=8, DC gain 0). (Sukumaran's `k̂₂=k₂+(k₃/2)(N−1)` is the **3rd-order** template — apply the analogous derivation for this 4th-order loop, don't copy it literally.) Fit H₁(s)=k_h1(1+s/ω_c)/[(1+s/ω_a)(1+s/ω_b)] (bandpass, peak ≈100 MHz) to the replica path by impulse invariance. Verify against Fig 8.

### 3.2 1-bit quantizer
- `y = 2*(w>=0) - 1;` (never returns 0). Clocked once per sample; in CT, quantise once per outer clock, hold the DAC value over the `nr_steps` inner loop.

### 3.3 FIR feedback DAC (semi-digital) — T1
- Filter the 1-bit output with `firtaps` (tapped delay line) before it drives the main DAC into I₄: feedback waveform = Σ f_k·y[n−k]. This is the multi-level v₁ of Fig 1.
- **On/off knob:** `Ntap=1, firtaps=1` reduces to a plain single-bit NRZ DAC (for the enable/disable comparison, Q2.1).
- Show feedback waveform + histogram of (vin − v₁) (reproduce Fig 1c/d).

### 3.4 First-tap-zero / explicit delay — T2 (metastability)
- Model comparator metastability as a **small data-dependent timing error on the first tap only**, larger when the comparator input is small. Then set `firtaps(1)=0` (explicit 1-cycle delay) and show the floor drop (reproduce Fig 4: ~52 dB → ~91 dB). On/off knob required.

### 3.5 Compensation path — T3
- Implement E(z) (7-tap) → DAC₃, subtract k_c1·vin, through **H₁(s)** bandpass, fanned into I₂ (high-passed) and the pre-I₁ summer (k_c2). **E(z) = (1 − F(z))/(1 − z⁻¹) = M₁(z)** (7-tap, DC gain 0) — derive per `09_reference_notes.md` §B (thesis not public).
- **On/off knob:** with the FIR DAC in but the compensation OFF, the loop should be **unstable / NTF wrong** (reproduce the Fig 6 argument); ON restores Fig 8. This is a key Q2.1 demonstration.

### 3.6 CT integrators (active-RC) — sub-stepped
- Use the existing CT idiom: inner `for b=1:nr_steps` loop, `om = ω·Ts/nr_steps`, integrate every sub-step, quantise once per clock, hold NRZ DAC over the inner loop. `nr_steps=20` default.

### 3.7 NRZ / RZ DAC + ELD — T4 / Q3.3
- DAC₂, DAC₁, DAC₄ are **NRZ**; DAC₀ is **RZ** (return-to-zero half-period) for ELD compensation — model the RZ pulse over the inner sub-steps.
- **ELD knob:** delay the quantizer→DAC feedback by `eld` fraction of Ts (fractional sub-step). Show NTF degradation/instability as `eld` grows; show the RZ DAC₀ coefficient restoring stability. (No general ELD helper exists in the repo — write it.)

### 3.8 Clock jitter — Q3.4 (NOT present anywhere in the repo; write from scratch)
- **White jitter:** perturb each clock edge by `jitter_rms*randn`; the injected error per cycle ≈ (v₁[n] − v₁[n−1])·Δt_n/Ts (the course's jitter model). Small steps (FIR) → small error.
- **Sinusoidal-FM jitter:** edge displacement = sinusoid at `jitter_fmod` (reproduce Fig 25/26 test). Sweep `jitter_fmod` 100 MHz→1.8 GHz at rms = 10 % Ts; plot in-band noise vs jitter freq and overlay |F(z)| → minima at F(z) zeros (Fig 26).
- **Jitter tolerance** (Fig 27): for each jitter freq, find max rms jitter for −80 dBFS in-band noise; compare 1b+FIR vs (emulated) 4-bit-at-fs/3 vs plain 1-bit.
- Also reproduce **Fig 2** (0.3 ps rms white jitter PSD, FIR vs plain vs 4-bit).

### 3.9 Integrator non-linearity — Q3.5
- Weak cubic on the **input integrator I₄**: output current i = G_m·v_d − G₃·v_d³ (Fig 3 inset). Use the **weak-nonlinearity simulation method of Pavan [14]** (perturbational, efficient) or a direct cubic term per sub-step. Show in-band floor rise from out-of-band-noise demodulation; compare 1b+FIR vs 4-bit (both rise ~equally, Fig 3). `g3` knob.

### 3.10 DAC mismatch — Q3.2
- For the single-bit **FIR DAC**: perturb each unit element `firtaps .* (1 + tapmismatch*randn(1,Ntap))`. This changes F(z) (a **linear** filter) → realised NTF shifts slightly + the F(z) zeros (jitter nulls in Fig 26) move; it does **not** add harmonic distortion. Emphasise on the slide that a 2-level DAC has no level mismatch. σ ≈ 0.5–1 %.

### 3.11 Finite opamp gain & BW — Q3.1
- **DC gain** → leaky integrator: `p = 1 - 1/A_dc; w = p*w_prev + ...` (course idiom). **BW** → add a 1-pole roll-off at `ugb` to each integrator (extra state per integrator). Paper values: `A_dc ≈ 10^(55/20)`, `ugb ≈ 2e9`. Sweep both; show in-band noise / NTF leakage; find the minimum gain/BW for negligible penalty.

### 3.12 Thermal noise — Q2.3
- Add input-referred Gaussian noise at I₄'s summing node; size `noise_rms` (sweep, or use the analytic budget `noise_rms = amplitude*sqrt(fs*nr_steps/4/fb/10^(SNR/10))`) so the in-band floor gives **DR ≈ 83 dB** (36 MHz). Show its un-shaped (flat) contribution.

### 3.13 Decimation filter — Q2.4
- Decimate the bitstream with a **sinc/CIC** filter. Course style = weighted-average window (sinc1 = rect, sinc2 = triang); a **sinc^(order+1)** (i.e. sinc⁵ for 4th-order) is the textbook choice — implement as cascaded box-car averages or `filter()` then downsample to ~Nyquist (decimation factor ≈ OSR). Plot **PSD before and after decimation** + **transient waveforms** (bitstream, integrator states, recovered sine). Show in-band SNR preserved.

### 3.14 ISI + correction — Q7 (improvement to verify)
- Model NRZ DAC rise/fall asymmetry (`isi_dtr ≠ isi_dtf`) using a (prev,curr)-bit lookup on the sub-step DAC waveform (the existing `MOD2_CT_NRZDAC.m` idiom). Show the **2nd-harmonic + floor rise** and the **SNDR kink** (Figs 17, 21).
- **Correction:** add a digital pulse α at every rising edge of the bitstream, α chosen to null HD2 (Fig 28 model). Reproduce **Figs 29/30**: kink removed, HD2 down ~15 dB, peak SNDR → ~74 dB. This is the headline Q7 verification.

---

## 4. Required scripts (suggested split) and their outputs

Keep scripts modular so each maps to one or two slides. Suggested files (names follow the course pattern):

| Script | Produces (figures to `results/`) | Exam slide(s) |
|---|---|---|
| `FIRDSM_design.m` | NTF (Fig 8), STF (Fig 9), coefficient printout | Q2 model, Q2.6A/B |
| `FIRDSM_sim.m` | output PSD −4 dBFS @10 MHz (Fig 22), SNR/SNDR/HD2/HD3 | Q2.6C |
| `FIRDSM_snr_vs_amp.m` | SNR/SNDR vs amplitude incl. ISI kink (Fig 21) | Q2.6I |
| `FIRDSM_techniques_onoff.m` | FIR on/off, compensation on/off, first-tap on/off table+PSD | Q2.1 |
| `FIRDSM_jitter.m` | jitter PSD (Fig 2), in-band noise vs FM freq (Fig 26), tolerance (Fig 27) | Q2.6D/E/F, Q3.4 |
| `FIRDSM_metastability.m` | with/without first-tap delay (Fig 4) | Q2.6G, Q2.1 |
| `FIRDSM_nonlin_integrator.m` | weak-cubic floor rise (Fig 3) | Q2.6H, Q3.5 |
| `FIRDSM_nonideal.m` | gain/BW sweep, DAC-tap mismatch, ELD sweep | Q3.1/3.2/3.3 |
| `FIRDSM_thermal_decimation.m` | thermal-noise PSD, pre/post-decimation PSD, transients | Q2.3/Q2.4 |
| `FIRDSM_isi_correction.m` | ISI on/off + correction (Figs 29/30) | Q7 |
| helpers | `mbq.m` (multi-bit quant for the 4-bit reference), FIR/DAC/decimation functions | — |

Every plot must be saved (`print(gcf, fullfile('results', NAME), '-dpng', '-r110')` or `saveas`) and titled/labelled so it can sit next to the paper figure on a slide.

---

## 5. Reproduction targets (numbers to hit)

| Quantity | Paper | Tolerance to aim for |
|---|---|---|
| Peak SQNR (ideal, 36 MHz) | ~95 dB design target / 71 dB SNDR measured | within a few dB of the SQNR target |
| NTF in-band notch depth | ~ −90 dB (Fig 8) | shape + notch positions match |
| STF peak | ~+12 dB @ ~100 MHz | within ~1–2 dB / right frequency |
| Output PSD HD2/HD3 | 73.5 / 79.7 dB (Fig 22) | order-of-magnitude + trend (HD2 limits) |
| Metastability recovery | 52 → 91 dB (Fig 4) | ~40 dB improvement |
| Jitter nulls | ~600 & 800 MHz (Fig 26) | nulls at F(z) zeros |
| Jitter tolerance | ~10× vs plain 1-bit (Fig 27) | ~10× |
| ISI correction | HD2 −15 dB, SNDR→74.3 (Figs 29/30) | HD2 drop + kink removed |
| Thermal-noise DR | 83 dB (Table I) | set floor to match |

---

## 6. Iteration / "malleability" plan (the oral demo)

For each knob, be ready to change it live and predict the result:
- **OBG ↑** → lower in-band noise but lower MSA / instability (Lee's rule). 
- **Ntap ↑** → better jitter filtering but more group delay → harder compensation (broad optimum ~8–18 taps).
- **first-tap zero off** → floor jumps ~40 dB (metastability).
- **compensation off** → loop unstable / NTF wrong.
- **jitter_rms ↑** → in-band floor rises; FIR keeps it ~10× lower than plain 1-bit.
- **A_dc / ugb ↓** → in-band leakage / floor rise; find the minimum.
- **eld ↑** → NTF droops then instability; RZ DAC₀ coefficient restores.
- **tapmismatch ↑** → F(z) zeros (jitter nulls) move, NTF shifts; no new harmonics.
- **g3 ↑** → in-band floor rises (out-of-band noise demodulation).
- **isi asymmetry ↑** → HD2 + kink; correction removes it.

**Workflow:** run each script headless (`matlab -nodisplay -batch`), inspect the saved PNG, compare against the matching `figures/figNN_*` from the paper, tweak coefficients until the numbers in §5 are hit, then lock the parameter block and capture the final PNGs for the slides.
