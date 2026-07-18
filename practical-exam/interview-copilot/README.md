# Interview-Copilot context — ET4278 final oral exam

**Paper:** Shettigar & Pavan, "Design Techniques for Wideband Single-Bit Continuous-Time ΔΣ Modulators With FIR Feedback DACs," *IEEE JSSC* 47(12), Dec 2012. DOI 10.1109/JSSC.2012.2217871.
**Candidate:** Daniel Tyukov (5714699). **TA/examiner:** Yang Liu.

This folder is the *entire* knowledge base for the live oral. It is written so that when Daniel says a **slide number** out loud, you jump to that slide in `slides.md` and answer from it precisely, in his voice.

## How to use this context (instructions to the copilot)

- **Primary trigger = a slide number.** "Slide 12", "the jitter PSD slide", "Q2.6D" all point to the same block in `slides.md`. Find the matching `## Slide N` header and answer from that block first. Every slide block has: what is literally on the slide, how to explain it, the theory/wording behind it, and the follow-ups an examiner asks.
- **Answer in first person, spoken-exam register.** Short, confident, technically exact. Lead with the one-sentence claim (the slide's "Conclusion"), then 1-2 sentences of mechanism, then the number. Do not dump the whole block.
- **Use the course's exact wording** (see `theory.md`): NTF/STF, out-of-band gain (OBG), Lee's rule, CIFB/CIFF, impulse invariance, excess loop delay (ELD), NRZ/RZ, intersymbol interference (ISI), DEM/DWA, MASH, assisted opamp, kT/C. The examiner grades wording.
- **Distinguish "paper value" vs "my MATLAB value."** Each slide lists both when they differ; never claim the paper's number as your simulated one or vice-versa.
- **If asked something not on a slide,** use `theory.md` (general ΔΣ / course questions = 20% of the grade) and the comparison table there.
- **If pushed on a weakness,** the honest answers are: SNDR is limited by **HD2 from DAC ISI** (only post-corrected off-line); the analog compensation path is **complex** and later work replaced it with digital ELD; MSA is capped by the **OBG-1.5 / Lee's-rule** 1-bit limit.

## One-line thesis (say this if asked "what is the paper about")

A 1-bit quantizer is the cheapest and most linear way to close a CT ΔΣ loop, but its full-scale NRZ feedback is ruinously jitter- and metastability-sensitive and demands a very linear loop filter. Shettigar & Pavan filter the 1-bit stream through an **8-tap semi-digital FIR feedback DAC**, so the feedback becomes the small-step, multi-level waveform of a multi-bit modulator — inheriting its jitter tolerance and relaxed loop-filter linearity — while the DAC stays inherently 2-level-linear (no DEM). The price is the FIR's group delay, cancelled by a mostly-analog **bandpass compensation path** that restores the target 4th-order OBG-1.5 NTF.

## Headline numbers (memorise; quote exactly)

| Quantity | Value |
|---|---|
| Architecture | 4th-order, **single-bit** CT ΔΣ, modified CIFB + input feed-forward |
| Feedback | **8-tap semi-digital FIR DAC** (NRZ) + analog FIR-delay compensation |
| Sampling rate fs | **3.6 GS/s** |
| Bandwidth | **36 MHz** (also reported at 25 MHz) |
| OSR | **50** (= fs / 2 / 36 MHz) |
| NTF order / OBG | 4 / **1.5** (Lee's rule for a 1-bit loop) |
| Peak SNR / SNDR / DR @36 MHz | **76.4 / 70.9 / 83 dB** |
| Peak SNR / SNDR / DR @25 MHz | 80.2 / 73.3 / 86 dB |
| Peak SNDR after ISI correction | **74.3 dB** (peak SNR 77.5 dB) |
| Power / supply | **15 mW** (12.5 mA) from 1.2 V |
| Technology / area | **90 nm** CMOS / 0.12 mm² |
| FoM Walden (SNDR, 36 MHz) | 72.7 fJ/conv-step |
| FoM Schreier (36 MHz) | 176.8 dB |
| Opamp | DC gain ≈ **55 dB**, UGB ≈ **2 GHz** |
| Comparator | high-initial-current single-phase latch, regen gain ≈ 4 @ 3.6 GS/s |
| FIR taps F(z) | **[0.07 0.12 0.15 0.16 0.16 0.15 0.12 0.07]**, Σ = 1 |
| Key measured limiter | **HD2 from DAC ISI** (SNDR-vs-amplitude kink near −55 dBFS) |

## MATLAB assumptions (say if asked "how did you simulate it")

fs = 3.6 GS/s, OSR = 50; Nfft = 2^16; window `kaiser(N,20)`; coherent input tone; **ns = 20 continuous-time sub-steps per clock**; `rng(1)` seeded; hand-rolled (no delsig toolbox); dBFS via A·N/2; SNR/SNDR by hand bin-sum (signal bins = main tone ±7, in-band bins = 1:round(fb/fres)).

## Slide index (34 slides in file order → question → one line)

Presentation = the official 32-slide template with duplicated sub-slides suffixed (Q2.6A…I). "Slide N" below = the Nth slide.

1. Title.
2. **Q1** issues + main techniques.
3. **Q2** model + coefficients (F(z), E(z), a, g, kff, H1).
4. **Q2.1** techniques on/off table.
5. **Q2.2** voltage scaling.
6. **Q2.3** thermal noise & spectrum.
7. **Q2.4** decimation filter (sinc^5 CIC).
8. **Q2.5** list of simulation results (repro table + assumptions).
9. **Q2.6A** NTF (Fig 8).
10. **Q2.6B** STF (Fig 9).
11. **Q2.6C** output PSD (Fig 22).
12. **Q2.6D** jitter PSD (Fig 2).
13. **Q2.6E** jitter FM nulls (Fig 26).
14. **Q2.6F** jitter tolerance (Fig 27).
15. **Q2.6G** metastability (Fig 4).
16. **Q2.6H** nonlinear integrator (Fig 3).
17. **Q2.6I** SNDR vs amplitude (Fig 21).
18. **Q3.1** finite amplifier gain & BW.
19. **Q3.2** DAC mismatch.
20. **Q3.3** excess loop delay (ELD).
21. **Q3.4** clock jitter.
22. **Q3.5** integrator non-linearity.
23. **Q4.1** loop filter & assisted opamp (Fig 10).
24. **Q4.2** semi-digital FIR feedback DAC (Fig 16).
25. **Q4.3** two-stage feed-forward opamp (Fig 12).
26. **Q4.4** comparator latch (Figs 13-15).
27. **Q4.5** clock: LC-PLL and LC-VCO (Fig 18).
28. **Q5** strengths & weaknesses table.
29. **Q6** comparison / extended Table II.
30. **Q7** improvement (adaptive/in-loop ISI) + verification (Figs 29/30).
31. Summary / overall assessment.
32. References.

Files: `slides.md` (the 32-slide reference — the core), `theory.md` (course wording, equations, comparison numbers, general-question prep).
