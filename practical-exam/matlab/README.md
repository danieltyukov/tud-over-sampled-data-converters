# FIR-DAC CT ΔΣ MATLAB model (Shettigar & Pavan, JSSC 2012)

Hand-rolled 4th-order single-bit CT ΔΣ with an 8-tap FIR feedback DAC. No
Schreier delsig toolbox, no `quant()`. Run headless:
`matlab -nodisplay -batch run_all` (or run any `FIRDSM_*.m` on its own). Every
figure is saved to `results/`.

## Architecture

- 4th-order modified CIFB + input feed-forward, 1-bit quantiser, OBG = 1.5
  (Lee's rule), two optimised NTF zeros at f_b·{0.46, 0.89} (notches near f_b/√3).
- fs = 3.6 GS/s, f_b = 36 MHz, OSR ≈ 50, ns = 20 sub-steps/clock.
- 8-tap FIR DAC F(z) = [0.07 0.12 0.15 0.16 0.16 0.15 0.12 0.07] (Eq. 1).
- Compensation: the comparator output is filtered by F(z) to make the smooth
  multi-level feedback; the deficit (1−F(z)) = E(z)(1−z⁻¹) is injected promptly
  (E(z) = 7-tap, DC gain 0). Modelled analog bandpass H₁(s) peaks ≈ 100 MHz.
- RZ DAC₀ keeps the fast last-integrator feedback prompt for ELD compensation.

## Files

| file | purpose |
|---|---|
| `firdsm_coeffs.m` | synthesise the OBG-1.5 NTF + solve the CIFB coefficients |
| `firdsm_params.m` | default parameter block (all knobs) |
| `firdsm_run.m`    | core CT sub-stepped engine, all non-idealities as knobs |
| `firdsm_spec.m`   | kaiser(N,20) dBFS spectrum + bin-sum SNR/SNDR/HD2/HD3 |
| `mbq.m`           | multi-bit quantiser (4-bit reference) |
| `FIRDSM_design.m` | NTF (Fig 8), STF (Fig 9), F(z)/E(z)/H₁(s) |
| `FIRDSM_sim.m`    | output PSD at −4 dBFS, 10 MHz (Fig 22) |
| `FIRDSM_snr_vs_amp.m` | SNR/SNDR vs amplitude, DR (Fig 21) |
| `FIRDSM_techniques_onoff.m` | Q2.1 enable/disable each technique |
| `FIRDSM_metastability.m` | first-tap-zero effect (Fig 4) |
| `FIRDSM_jitter.m` | white jitter (Fig 2), FM nulls (Fig 26), tolerance (Fig 27) |
| `FIRDSM_nonlin_integrator.m` | weak-cubic floor rise (Fig 3) |
| `FIRDSM_thermal_decimation.m` | scaling, thermal noise, sinc⁵ decimation, transients |
| `FIRDSM_nonideal.m` | Q3.1 gain/BW, Q3.2 DAC mismatch, Q3.3 ELD + RZ DAC₀ |
| `FIRDSM_isi_correction.m` | Q7 ISI + digital correction (Figs 29/30) |

## Reproduced numbers (mine vs paper)

| quantity | mine | paper |
|---|---|---|
| ideal SQNR (36 MHz) | 94 dB | ~95 dB design target |
| output PSD: SNDR / SNR / HD2 | 71.4 / 76.5 / −73.0 dB | 70.3 / 74.9 / −73.5 dB |
| peak SNR / SNDR / DR (Fig 21) | 75.7 / 71.6 / ~81 dB | 76.4 / 70.9 / 83 dB |
| STF peaking (Fig 9) | +11.6 dB | ~+12 dB |
| metastability recovery (Fig 4) | 51 → 93.5 dB | ~52 → ~91 dB |
| FIR vs plain-1-bit jitter (Fig 2) | 88.6 vs 63.2 dB | FIR ≈ 4-bit ≫ plain |
| jitter nulls (Fig 26) | at F(z) zeros (557, 997 MHz) | at F(z) zeros |
| ELD tolerance (Q3.3) | unstable >0.2 Ts, RZ DAC₀ to >0.6 Ts | comp restores |
| ISI correction (Figs 29/30) | HD2 −15 dB, SNDR 71→76 dB | HD2 −15 dB, SNDR 71→74.3 dB |

## Live-demo knobs (set in `firdsm_params.m` or override per run)

`OBG`, `Ntap`/`firtaps`, `fir_on`, `comp_on`, `first_tap_zero`, `jitter_rms`,
`jitter_fmod`, `A_dc`, `ugb`, `eld`, `kdac0`, `tapmismatch`, `g3`, `noise_rms`,
`meta_on`/`meta_tau`, `isi_on`/`isi_alpha`/`isi_corr`, `kff`, `amp`, `nlev`.
