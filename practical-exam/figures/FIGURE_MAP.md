# Figure map

Each paper figure/table extracted as an individual image (from the embedded raster in the PDF).
"Repro" = reproducible in MATLAB (system-level). Full descriptions in `../01_paper_analysis.md`.
Full-page renders: `pages/page-01..15.png`. Raw extracts: `embedded/img-000..033`.

| File | Paper | What it shows | Repro? | Exam use |
|---|---|---|---|---|
| `fig01_singlebit_ctdsm_firdac_waveforms_histogram.png` | Fig 1 | 1-bit CTDSM + FIR DAC, semi-digital structure, feedback waveforms, error histograms | partial | Q1, Q4.2 |
| `fig02_clock_jitter_inband_psd.png` | Fig 2 | in-band PSD with 0.3 ps rms white jitter: FIR vs 4-bit vs plain 1-bit vs ideal | yes | Q2.6, Q3.4 |
| `fig03_nonlinear_integrator_inband_psd.jpg` | Fig 3 | weak-cubic input integrator floor rise, FIR vs 4-bit | yes | Q2.6, Q3.5 |
| `fig04_metastability_explicit_delay_psd.png` | Fig 4 | with/without explicit 1-cycle delay (SNR 91 vs 52 dB) | yes | Q2.1, Q2.6 |
| `fig05_modified_cifb_starting_point.png` | Fig 5 | modified CIFB starting architecture + compensation block | n/a | Q1, Q2 model |
| `fig06_firdac_compensation_technique.jpg` | Fig 6 | FIR-delay compensation derivation (a-d), bandpass H1(s) | partial | Q1, Q2 model |
| `fig07_compensated_modulator_architecture.jpg` | Fig 7 | final compensated architecture (all DACs, k's, H1) | n/a | Q1, Q2 model |
| `fig08_realized_ntf_vs_maxflat.png` | Fig 8 | realised NTF (with H1 kink) vs maximally-flat OBG-1.5 | yes | Q2.6A |
| `fig09_stf_magnitude.jpg` | Fig 9 | STF magnitude (+12 dB peak ~100 MHz) | yes | Q2.6B |
| `fig10_single_ended_schematic.jpg` | Fig 10 | single-ended schematic (active-RC, assisted opamp, semi-digital FIR) | n/a | Q4.1/4.2 |
| `fig11_compensating_filter_response.jpg` | Fig 11 | frequency response of H1(s) (peaks ~100 MHz, 1/s roll-off) | yes | Q2 model |
| `fig12_two_stage_feedforward_opamp.png` | Fig 12 | two-stage feed-forward opamp macromodel + schematic (55 dB / 2 GHz) | n/a | Q4.3, Q3.1 |
| `fig13_comparator_schematic_waveforms.png` | Fig 13 | comparator schematic + waveforms (sampling/regeneration) | n/a | Q4.4 |
| `fig14_regeneration_current_proposed_vs_cml.jpg` | Fig 14 | regeneration current, proposed vs CML, large/small inputs | n/a | Q4.4 |
| `fig15_comparator_output_waveforms.jpg` | Fig 15 | comparator output for small inputs, CML vs proposed | n/a | Q4.4 |
| `fig16_resistive_dac_ref_vs_virtualground.jpg` | Fig 16 | switched-resistor DAC: reference-side vs virtual-ground switching | n/a | Q4.2 |
| `fig17_dac_nonlinearity_isi_waveforms.jpg` | Fig 17 | DAC ISI: single-ended/differential currents + low-freq spectra | yes | Q3.2/Q7 |
| `fig18_lc_pll_and_lc_vco.png` | Fig 18 | LC-PLL block + LC-VCO schematic | n/a | Q4.5 |
| `fig19_die_photo_layout.jpg` | Fig 19 | die photo / layout (0.12 mm^2) | n/a | context |
| `fig20_test_setup.png` | Fig 20 | measurement test setup | n/a | Q2.5 |
| `fig21_snr_sndr_vs_input_amplitude.png` | Fig 21 | SNR/SNDR vs amplitude (peak 76.4/70.9, DR 83, ISI kink) | yes | Q2.6I |
| `fig22_output_psd_minus4dBFS_10MHz.png` | Fig 22 | output PSD, -4 dBFS @10 MHz (HD2 73.5, HD3 79.7) | yes | Q2.6C |
| `fig23_bw_vs_dr_survey.jpg` | Fig 23 | BW vs DR survey scatter (ISSCC/VLSI) | no (survey) | Q6 |
| `fig24_power_vs_sndr_survey.jpg` | Fig 24 | power/Fnyq vs SNDR survey scatter | no (survey) | Q6 |
| `fig25_fm_modulated_clock_generation.png` | Fig 25 | FM-modulated clock generation for jitter test | n/a | Q3.4 |
| `fig26_inband_noise_vs_jitter_frequency.png` | Fig 26 | in-band noise vs FM jitter freq, nulls at F(z) zeros | yes | Q2.6E, Q3.4 |
| `fig27_jitter_tolerance_comparison.jpg` | Fig 27 | jitter tolerance: 1b+FIR vs 4-bit vs plain 1-bit | yes | Q2.6F, Q3.4 |
| `fig28_isi_correction_concept.png` | Fig 28 | ISI-correction concept (real/ideal/error + digital model) | yes | Q7 |
| `fig29_sndr_with_without_isi_correction.png` | Fig 29 | SNDR vs amplitude, correction on/off | yes | Q7 |
| `fig30_psd_with_without_isi_correction.png` | Fig 30 | PSD with/without ISI correction (HD2 -15 dB) | yes | Q7 |
| `tableI_performance_summary.png` | Table I | performance summary (25 & 36 MHz BW) + FoM defs | n/a | Q2.5 |
| `tableII_performance_comparison.png` | Table II | comparison vs [1]-[6] (EXTEND this) | n/a | Q6 |
