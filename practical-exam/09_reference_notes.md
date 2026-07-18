# Reference Notes — precise detail extracted from the downloaded PDFs (`refs/`)

These are the exam-relevant specifics read out of the PDFs in `refs/`, beyond what's in the chosen paper. Use them to make the MATLAB precise (`04_matlab_requirements.md`), the circuit slides accurate (`01` §4), and the comparison/improvements concrete (`06`). Math is Unicode. Section A = modelling methods; B = FIR-DAC design & coefficients; C = newer topologies & comparison.

---

## A. Modelling methods (jitter, metastability, weak nonlinearity, assisted opamp)

### A.1 Clock jitter — Cherry & Snelgrove 1999 (`Cherry1999_…`)
The model the chosen paper cites for "8-tap FIR ≈ 4-bit jitter sensitivity".

- **Error per edge (the load-bearing equation):** a jittered NRZ feedback equals the ideal plus an error sequence
  `e[n] = (y[n] − y[n−1]) · βₙ / Ts`,  βₙ ~ N(0, σ_β²), i.i.d.
  → error is non-zero **only at level changes** and ∝ the **step height** δy = y[n]−y[n−1].
- **Error power:** σ_e² ≈ σ_δy² · (σ_β² / Ts²), i.e. (mean-square step height) × (relative jitter variance).
- **In-band SNR (white jitter):** SNR_NRZ = 10·log₁₀( OSR · V_in²/2 / [σ_δy² · (σ_β/Ts)²] ).
  Scales ∝ step-height², ∝ (σ_β/Ts)², ∝ 1/OSR.
- **Effective σ_δy² by pulse type (±1 modulator):** NRZ ≈ **2.80**, RZ ≈ **8.00**, RZ+HRZ ≈ **24.10**. RZ is ~4.6 dB worse, RZ/HRZ ~9.3 dB worse → why the design uses **NRZ** taps.
- **Why the FIR helps, quantified:** the 8-tap FIR turns ±2 single-bit steps into an 8-step staircase whose mean-square edge step collapses toward a 16-level (4-bit) DAC. So σ_δy²(FIR) ≈ σ_δy²(4-bit) → "jitter sensitivity similar to a four-bit modulator at fs/3" (Fig 2).
- **MATLAB recipe:** per sample `beta = sigma_beta*randn`; form the FIR staircase `w[n] = Σ_k d_k·y[n−k]`; inject `e_jit[n] = (w[n]−w[n−1])·beta[n]/Ts` as an additive term on the DAC current into integrator 1. Verify floor against σ_δy²·(σ_β/Ts)²/OSR, using `var(diff(w))` for σ_δy² with the real taps. (`diff(w)` is small for the FIR → small e_jit; that's the whole point.)

### A.2 Comparator metastability — Cherry & Snelgrove 1999
- **Physics:** regenerative latch is single-pole positive feedback → output grows exponentially, `v(t) = v(0)·exp(t/τ)`, τ = regeneration time constant ∝ 1/GB. Small comparator input resolves late → **data-dependent zero-crossing time** of the feedback edge = "exactly the same effect as clock jitter," but signal-dependent (worst near |v_x|→0).
- **Time-to-resolve:** τ_d ≈ τ·ln(V_logic/|v_x|), diverges as v_x→0 (below a threshold: no crossing = glitch).
- **Equivalent-jitter shortcut (avoids a 2-D lookup):** model metastability as white jitter with **σ_β = σ_ms/√2**, σ_ms = std-dev of DAC-pulse-width variation (Cherry's 5th-order example: σ_ms = 5.95×10⁻³·Ts). The √2 is because clock jitter perturbs two edges, metastability one.
- **MATLAB model (inject on the FIRST tap only):** at each sample take v_x[n] (comparator input) and slope; τ_d[n] = τ·ln(V_FS/|v_x[n]|) (clamp; declare hysteresis below threshold); subtract `Δq[n] = d₀·(y[n]−y[n−1])·(τ_d[n]/Ts)` from the feedback into integrator 1. **Mitigation = set d₀ = 0** (explicit 1-cycle delay) → Δq ≡ 0 → metastability gone (Fig 4, ~40 dB recovery). Knobs for Q4: τ (regen tail current), preamp gain (≈4 useful), number of half-latches.

### A.3 Weak integrator nonlinearity — Pavan 2010 (`Pavan2010_…`)
The exact method behind Fig 3 (and the efficient way to do Q3.5).

- **Device:** `i = G_m·v_d − G₃·v_d³` for |v_d| ≤ √(G_m/3G₃) (then clips). v_d = first-integrator virtual-ground swing. Same form as Fig 3 inset.
- **Perturbational two-run method (no nonlinear ODE solve):**
  1. **Linear run:** simulate with G₃ = 0 (real quantizer); record output v⁽¹⁾[k] **and** the first-integrator node history x₁⁽¹⁾[k]. (Only the input integrator matters in this CIFF-style loop.)
  2. **Injection run:** same *linear* loop filter, **bypass the quantizer**, set input u = 0, drive it with the injected current `j[k] = G₃·(x₁⁽¹⁾[k])³`; record v⁽³⁾[k].
  3. **Combine:** v[k] = v⁽¹⁾[k] + v⁽³⁾[k]; PSD → in-band SNDR. The cubed-node term folds out-of-band noise into the band (raises the floor).
- **HD3 relation:** for v_d = A·sinωt, **HD3 = (G₃·A²)/(4·G_m)**; weakly-nonlinear ceiling A < √(G_m/3G₃).
- **Fig 3 parameters (confirmed):** G_m = **1000**, G₃ = **20** for *both* the 4-bit (1.2 GS/s) and 1-bit-FIR (3.6 GS/s) modulators ("1k, 20, 20"), input resistor R = 1 (normalised). → G₃/G_m = 0.02, HD3 ≈ 0.005·A². The point: in-band floor rises by the **same** amount in both → the FIR DAC does **not** relax loop-filter linearity (it relaxes jitter, not linearity).

### A.4 Assisted-opamp integrator — Pavan & Sankar 2010 (`PavanSankar2010_…`)
For the Q4 first-integrator slide and the Q3.1 finite-gain/BW model.

- **Idea:** the current the first opamp must supply (from V_in and V_dac) is known, so a feed-forward "assistant" (g_m = 1/R + a replica current-steering DAC, ±V_ref/R) injects it directly at the opamp **output node**. The opamp then sources ≈0 current → virtual ground barely moves → distortion collapses → opamp can run at much lower bias current. Applied to the **first integrator only**.
- **Cancellation condition:** I_a(s) = (1 + C_L/C)·I_in(s) + I_in(s)·G_L/(sC); with impedance-scaled later stages → I_a ≈ (1 + C_L/C)·I_in (purely proportional, robust).
- **Distortion suppression:** assistant's own HD3 is divided by the opamp loop gain G_m·R at the output → assistant HD3 up to 0.5 % still gives ~distortion-free output.
- **Finite gain/BW model (Q3.1):** model the opamp as a 1-pole transconductor `G_m(s) = G_m0/(1+s/ω_p)`. In a hand-rolled loop, replace the ideal accumulator `1/(1−z⁻¹)` with a **leaky accumulator** `g/(1 − p·z⁻¹)`, leak `p = 1 − (ω_u/A₀)/fs` (finite DC gain A₀), plus a one-pole prefilter at the **UGB** (finite BW). Sweep A₀ and UGB → in-band floor / NTF leakage; find the minimum.
- **Numbers:** assisted-opamp *reference* design = DC gain 65 dB, UGB 55 MHz (audio). **For reproducing the chosen paper use ITS opamp: DC gain ≈ 55 dB, UGB ≈ 2 GHz** (at fs = 3.6 GS/s).

> Gaps: Cherry's τ and (ρ_d, ρ_r) are SPICE lookup tables (no closed form) — use the σ_β = σ_ms/√2 shortcut. Pavan 2010's "1k,20,20" are normalised modelling inputs, not lab HD. The assisted-opamp G_m(s) single-pole form is the standard realisation, not an explicit equation in the paper.

---

## B. FIR-DAC design & the compensation closed-form (Sukumaran 2014, Su & Wooley 1993)

This is the recipe to derive the coefficients the chosen paper doesn't print (Shettigar's own MS thesis is unavailable; this is the substitute).

### B.1 Main FIR F(z)
- Chosen paper (verbatim Eq.1): F(z) = 0.07(1+z⁻⁷)+0.12(z⁻¹+z⁻⁶)+0.15(z⁻²+z⁻⁵)+0.16(z⁻³+z⁻⁴) → taps **[0.07 0.12 0.15 0.16 0.16 0.15 0.12 0.07]**, symmetric (linear phase), **Σ=1 (DC gain 1)**, **optimised assuming jitter spectrum ∝ 1/f²** (not equal taps).
- Sukumaran (audio) uses **equal** taps for layout ease: F(z) = (1/N)(1−z⁻ᴺ)/(1−z⁻¹), N=12. Equal taps are fine at high OSR; jitter-weighted taps buy margin at low OSR/high speed.
- **Tap-count optimum:** peak error into the input integrator = (shaped q-noise, ↓ with N) vs (input component from STF deviation, ↑ with N). For a **CIFF-B** loop the normalised peak |e(t)| drops then **flattens at N ≈ 10–12** (≈0.1); CIFB flattens higher (≈0.25–0.3). 8 taps at OSR 50 (chosen paper) is consistent (lower OSR → wider normalised transition band → fewer taps).

### B.2 Compensation closed-form (Sukumaran's 3rd-order CIFF-B; the method to derive E(z)/k̂₂)
DT equivalents of the CT paths (NRZ DAC), exact:
- 1/s  → H₁(z) = z⁻¹/(1−z⁻¹)
- 1/s² → H₂(z) = ½(z⁻¹+z⁻²)/(1−z⁻¹)²
- 1/s³ → H₃(z) = (z⁻¹+4z⁻²+z⁻³)/6 /(1−z⁻¹)³
- **(for the 4th-order chosen paper, supply this — Eulerian, not in the PDFs):** 1/s⁴ → (z⁻¹+11z⁻²+11z⁻³+z⁻⁴)/24 /(1−z⁻¹)⁴

Procedure:
1. **Pick the non-FIR prototype coefficients** by matching the target NTF (maximally flat, OBG 1.5): k₁H₁+k₂H₂+k₃H₃ = 1/NTF(z) − 1.
2. Equate FIR vs non-FIR loop gains: k̂₃F(z)H₃ + k̂₂F(z)H₂ + F_c(z)H₁ = k₃H₃ + k₂H₂ + k₁H₁.
3. **k̂₃ = k₃** (since F(1)=1).
4. Factor **1 − F(z) = M₁(z)(1−z⁻¹)**, with **M₁(1) = ½(N−1)** ⇒ **k̂₂ = k₂ + (k₃/2)(N−1)** (raise the 2nd-integrator gain).
5. Factor M₁(z)N₃(z) − M₁(1)F(z)N₂(z) = M₂(z)(1−z⁻¹) ⇒ **F_c(z) = k₁ + k₂·N₂(z)·M₁(z) + k₃·M₂(z)** (an N-tap compensation FIR into the first/1-s path).
- STF (for peaking): STF(jω) = [(k_f s² + k̂₂ s + k₃)/s³ · NTF]|_{s=jω}; k_f = input feed-forward.
- **CAVEAT — this is Sukumaran's 3rd-order CIFF-B template.** The chosen paper is **4th-order** and uses a *different* compensation (a single bandpass E(z)·H₁(s) into the inner integrator, not F_c into the first — see B.3). So reuse the **method** (DT-map → match 1/NTF−1 → keep highest-order k̂=k → fold (1−F)/(1−z⁻¹)=M₁=E(z) → re-tune inner gains), not the literal `k̂₂=k₂+(k₃/2)(N−1)` formula.

### B.3 How the chosen paper's compensation maps to this (Fig 6 sanity check)
- Shettigar's **E(z) = 7-tap** = "(1−F(z)) with one integrator folded in" = exactly M₁(z) (order N−2 = 6 → 7 taps), **DC gain ~0**.
- Shettigar's **H₁(s)** = analog **bandpass** realisation of the replica-integrator path: H₁(s) = k_h1(1+s/ω_c)/[(1+s/ω_a)(1+s/ω_b)], low DC gain + 1/s roll-off, **peaks ≈ 100 MHz** (Figs 6d/11).
- **Crucial difference from Sukumaran:** Sukumaran feeds F_c into the **first** integrator and raises k̂₂; Shettigar feeds a single **bandpass E(z)·H₁(s)** path into the **inner (3rd) integrator** with V_in subtracted + a high-pass branch to I₂. Shettigar explicitly rejects (i) FIR feed-ins into all integrators [10] ("jitter noise injected by the compensation FIR-DACs begins to limit performance") and (ii) reduced first-integrator gain [11] (raises in-band q-noise). The bandpass trick keeps the compensation path's in-band+DC content low → preserves the FIR jitter advantage; feeding I₃ attenuates its non-idealities by two integrators.
- **Practical build path:** derive k₁,k₂,k₃(,k₄) from the OBG-1.5 NTF; E(z)=M₁(z) from 1−F(z); fit H₁(s) (bandpass, peak ~100 MHz) by impulse-invariance to the replica path; re-tune inner coefficient(s) per the k̂₂/F_c relations to hold the NTF. Verify against Fig 8.

### B.4 Semi-digital FIR DAC (Su & Wooley) — for Q4 + the mismatch model
- Structure: 1-bit code → **digital shift register** (taps z⁻ⁱ) → each tap gates a **weighted current unit element** aᵢ → summed at an opamp **virtual ground** (RC feedback = I→V + ZOH). H(z) = Σ aᵢz⁻ⁱ; **linear phase ⇔ symmetric taps aᵢ = a_{n−i+1}**.
- **Mismatch = coefficient error, not nonlinearity** (the key slide point): all switches carry *delayed copies of the same 1-bit stream*, so each element's linearity is independent of neighbours — errors only perturb H(z). Formula: random source errors give |ΔH(f)| ≈ (√π/2)(δ_I/I_M), **independent of frequency and tap count**; they cap stopband attenuation at ≈1/|ΔH|, negligible passband effect. (To model in MATLAB: F(z) taps × (1+σ·randn) → recompute response; jitter nulls shift; no new harmonics.)

### B.5 Other Sukumaran specifics
- Thermal noise: first opamp dominates; FIR relaxes its linearity → low bias; FIR taps are large resistors into the virtual ground.
- Jitter suppression ≈ 20·log₁₀(N) dB (12-tap ≈ 21 dB).
- Residual problem = **rise/fall asymmetry (ISI)** → even-order distortion + floor; FIR does NOT fix it → handled by an on-chip ISI tuning loop (3-bit PMOS bank + SAR equalising rise/fall) + fs/8 25%-duty dither for idle tones. (Improvement idea for Q7.)

### B.6 Rajagopal thesis — NOT relevant
It is a **multibit** (17-level flash, DWA, current-steering RZ DAC) 4th-order CIFFB wideband design (2.6 GHz, 100 MHz BW, OSR 13). No FIR DAC / semi-digital structure / FIR coefficients. Only generic confirmations (OBG 1.5, CIFFB+optimised zeros). Don't mine it for coefficients.

---

## C. Newer topologies & extended comparison (exact reported numbers)

### C.1 Comparison-table rows (quote these on the Q6 slide)
| Design (year) | Tech / Vdd | f_s | BW | DR | pk SNR | pk SNDR | Power | FoM_W | FoM_S | Area | Key feature |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **Shettigar-Pavan 2012** | 90 nm /1.2 V | 3.6 GS/s | 36 (25) MHz | 86@25M | 80.2@25M | 71@36M; 73.3@25M | 15 mW | 72.7 (79.4) fJ | 176.8 (178.2) dB | 0.12 mm² | 1-bit 4th-ord, **8-tap FIR + analog ELD comp** |
| Bolatkale 2011 [6] | 45 nm /1.1+1.8 V | 4 GS/s | **125 MHz** | 70 | 65.5 | 65 | 260 mW | ~400 fJ | ~157 dB | 0.9 mm² | **4-bit** CT, cap-FF, direct ELD (no FIR) — the multibit road not taken |
| Sukumaran 2014 | 180 nm /1.8 V | 6.144 MS/s | 24 kHz | 103 | 98.9 (A:102.3) | 98.2 | 280 µW | 88 fJ | 182.3 dB | 1.25 mm² | 1-bit FIR audio + ISI cal + dither |
| Zhang-Temes 2015 | 65 nm /1.0 V | 1.2 GS/s | 15 MHz | 79.4 | 77.3 | 74.3 | 6.96 mW | 58.6 fJ | ~172.7 dB | 0.16 mm² | **2-bit, 3-tap FIR + digital ELD comp** + DWA |
| Jain-Pavan 2018 | 65 nm /1.4 V | 6 GS/s | 60 MHz | 76 | 68.8 | 67.6 | 13.3 mW | **56.5 fJ** | 172.5 dB | 0.07 mm² | 1-bit **2× time-interleaved FIR** |
| Billa 2020 | 180 nm /1.8 V | 6.144 MS/s | 24 kHz | 104 | 101.7 | 100.9 | 265 µW | — | 180.5 dB | 0.64 mm² | **1-X FIR-MASH** (1st+2nd 1-bit), chopping |
| Theertham 2022 | 180 nm /1.8 V | 48 MS/s | 250 kHz | 104 | 104.3 | 103.2 | 17.7 mW | ~300 fJ | 174.7 dB | 1.1 mm² | 1-bit, 12-tap FIR + **dual return-to-open DAC** + chopping |
| Pavan-Baskaran 2018 | 65 nm /1.2 V | (audio) | 24 kHz | — | — | 98.6 | 260 µW | — | 178.3 dB | small | tutorial: 1-bit + FIR + chopping ported 180→65 nm |
(FoM_W = Walden fJ/conv-step, FoM_S = Schreier dB. "~" = derived from P/BW/DR.)

### C.2 Improvement axes vs the 2012 paper (for Q5/Q7)
- **Bolatkale 2011** — multibit wideband counter-example: 125 MHz BW but 0.4 pJ/conv, ~157 dB, needs DEM/flash/higher supply. Shows what single-bit+FIR trades (BW) and avoids (DEM, power).
- **Sukumaran 2014** — same idea to >100 dB audio at µW; adds tap-count theory + ISI calibration + dither.
- **Zhang-Temes 2015** — **digital ELD compensation** (reference-shifting quantizer) replaces the 2012 analog compensation path → simpler, relaxes last-integrator GBW. (Q7 axis: analog→digital ELD.)
- **Jain-Pavan 2018** — **time-interleaved FIR**: more taps / GHz BW without the first-tap jitter penalty; best Walden FoM. (Q7 axis: scale FIR to wideband.)
- **Billa 2020** — **FIR-MASH**: cascade single-bit stages → 3rd-order NTF with MSA ≈ −0.65 dBFS, recovering the ~3 dB the OBG-1.5/MSA limit costs a single-loop 1-bit. (Q7 axis: MASH for aggressive NTF.)
- **Theertham 2022** — **dual return-to-open DAC** removes the data-dependent ISI that limits resistive NRZ FIR DACs — i.e. the exact SNDR-kink/HD2 problem the 2012 paper only post-corrected. (Q7 axis: circuit-level ISI fix.)

### C.3 Pavan-Baskaran decision framework (lit-review framing)
Quantizer levels dominate power → pick **1-bit ADC** (one comparator, no ladder, offset irrelevant; multibit flash grows exponentially and loads the loop filter). Two-level DAC is statically linear → **1-bit DAC** avoids DEM/calibration. The only catch is **jitter** (large 2-level steps) → **FIR feedback** shrinks the step to 2/N → jitter noise ↓ 20·log₁₀(N) dB *and* the loop filter sees a small error (multibit-like relaxed linearity), with no DAC-mismatch burden; stabilise the added delay by method-of-moments. Operate at **high OSR / modest order** in a fast-enough node. Each modern paper extends one axis of this recipe (digital ELD / TI-FIR / MASH / RTO-DAC); Bolatkale is the multibit alternative the framework argues against.

