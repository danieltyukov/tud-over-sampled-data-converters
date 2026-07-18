# References & PDF Links (TU Delft IEEE Xplore proxy)

All links use the **TU Delft proxy** `ieeexplore-ieee-org.tudelft.idm.oclc.org` (you are logged in — verified). For each item:
- **Doc** = `…/document/<id>/` (abstract page, has a PDF button), **PDF** = `…/stamp/stamp.jsp?tp=&arnumber=<id>` (direct), **DOI** when known, or a **search** link by title (always resolves).
- Proxy base: `https://ieeexplore-ieee-org.tudelft.idm.oclc.org`
- Start page (per the exam brief): https://ieeexplore-ieee-org.tudelft.idm.oclc.org/Xplore/home.jsp

> IDs marked ✓ were verified live in IEEE Xplore this session. Others give a by-title search link so you can grab the PDF and confirm the exact DOI before quoting it on a slide.

---

## ★ ALREADY DOWNLOADED — local PDFs in `refs/` (13 files, verified)

These were fetched via the TU Delft proxy / open access and are on disk now. Deep notes extracted from them are in `09_reference_notes.md`.

| Local file (`refs/`) | Paper | IEEE doc id (verified) |
|---|---|---|
| `Shettigar2012_CHOSEN_FIR_DAC_JSSC.pdf` | THE chosen paper | 6341855 |
| `Pavan2010_weak_nonlinearities_TCASI.pdf` | [14] Efficient Simulation of Weak Nonlinearities in CT Oversampling Converters | 5416327 |
| `Cherry1999_jitter_metastability_TCASII.pdf` | [7] Clock jitter & quantizer metastability in CT delta-sigma | 769775 |
| `SuWooley1993_semidigital_DAC_JSSC.pdf` | [13] CMOS oversampling D/A with current-mode semidigital reconstruction filter | 261996 |
| `PavanSankar2010_assisted_opamp_JSSC.pdf` | [15] Power reduction using the assisted-opamp technique | 5492314 |
| `Bolatkale2011_4GHz_CTDSM_JSSC.pdf` | [6] 4 GHz CT delta-sigma (multibit baseline) | 6029947 |
| `Sukumaran2014_FIR_audio_JSSC.pdf` | Low-power single-bit audio CT delta-sigma using FIR feedback | 6862074 |
| `ZhangTemes2015_digitalELD_FIR_TCASI.pdf` | Digital ELD compensation + FIR feedback (ultrasound) | 7116629 |
| `JainPavan2018_TI_FIR_TCASI.pdf` | Time-interleaved FIR feedback | 8030132 |
| `Billa2020_FIR_MASH_JSSC.pdf` | 1-X FIR-MASH | 9098038 |
| `Theertham2022_dualR2O_JSSC.pdf` | Dual return-to-open DACs | 9792160 |
| `PavanBaskaran2018_which_architecture_ISCAS.pdf` | "What architecture should I choose…" tutorial | 8351141 |
| `Rajagopal2015_IITM_thesis_CTDSM_components.pdf` | IIT-Madras MS thesis, CTDSM components (open access) | eescholars ee13m076 |

> NOT found publicly: **Pradeep Shettigar's own MS thesis** (would have the exact loop-filter coefficients). It is not indexed on eescholars.iitm.ac.in or Shodhganga. Derive the coefficients instead (method in `Sukumaran2014` + the chosen paper's Eq. 1) — see `09_reference_notes.md`.

To re-download or get a paper not on disk, use the verified doc-id links below: Doc `…/document/<id>` and direct PDF `…/stampPDF/getPDF.jsp?tp=&arnumber=<id>&ref=` (the `getPDF.jsp` form is the actual file; the `stamp/stamp.jsp` form is the viewer).

---

## A. The chosen paper + companion / thesis status (get these first)

- **[CHOSEN] Shettigar & Pavan, "Design Techniques for Wideband Single-Bit CT ΔΣ Modulators With FIR Feedback DACs," IEEE JSSC 47(12):2865–2879, Dec 2012.** ✓ id **6341855**
  - Doc: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/document/6341855
  - PDF: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/stamp/stamp.jsp?tp=&arnumber=6341855
  - DOI: https://doi.org/10.1109/JSSC.2012.2217871
- **[12] Shettigar & Pavan, "A 15 mW 3.6 GS/s CT-ΔΣ ADC…," ISSCC 2012** — the conference precursor of the chosen paper. **Not separately indexed on IEEE Xplore** (only the JSSC journal version above is, and it supersedes it). Just use the downloaded `refs/Shettigar2012_CHOSEN_FIR_DAC_JSSC.pdf`.
- **Pradeep Shettigar's MS thesis (IIT Madras)** would tabulate the omitted coefficients (ω₁..ω₄, k's, E(z) taps, H₁(s) poles/zeros) — but it is **NOT public** (checked: not on eescholars.iitm.ac.in or Shodhganga). **Derive the coefficients instead** — method in `09_reference_notes.md` §B. The related **Rajagopal 2015 IIT-Madras thesis** is in `refs/` (open access) but is a *multibit* design, so it does not give these FIR coefficients.

---

## B. The paper's own references [1]–[17] (extend Table II / cite in Q5/Q6)

Most useful for the MATLAB model and comparison are flagged ★.

- **[1] Mitteregger et al., "A 20-mW 640-MHz CMOS CT ΣΔ ADC with 20-MHz BW, 80-dB DR, 12-bit ENOB," JSSC 41(12), 2006** — multi-bit wideband baseline (Table II col [1]).
  - Doc: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/document/4014623 ✓ id 4014623
- **[2] Kauffman et al., "An 8.5 mW CT ΔΣ Modulator with 25 MHz BW using digital background DAC linearization…," JSSC 46(12), 2011** (Table II col [2]).
  - Doc: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/document/6024453 ✓ id 6024453 · PDF: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/stampPDF/getPDF.jsp?tp=&arnumber=6024453&ref=
- **[3] Dhanasekaran et al., "A 20 MHz BW 68 dB DR CT ΣΔ ADC based on a multi-bit time-domain quantizer and feedback element," ISSCC 2009** (Table II col [3]).
  - Doc: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/document/5686879 ✓ id 5686879 · PDF: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/stampPDF/getPDF.jsp?tp=&arnumber=5686879&ref=
- **[4] Malla et al., "A 28 mW spectrum-sensing reconfigurable 20 MHz 72 dB SNR 70 dB SNDR DT ΣΔ ADC…," ISSCC 2008** (Table II col [4]).
  - Doc: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/document/4523274 ✓ id 4523274 · PDF: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/stampPDF/getPDF.jsp?tp=&arnumber=4523274&ref=
- **[5] Park & Perrott, "A 0.13 µm CMOS 78 dB SNDR 87 mW 20 MHz BW CT ΣΔ ADC with VCO-based integrator and quantizer," ISSCC 2009** (Table II col [5]).
  - Doc: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/document/5342354 ✓ id 5342354 · PDF: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/stampPDF/getPDF.jsp?tp=&arnumber=5342354&ref=
- **[6] Bolatkale, Breems, Rutten, Makinwa, "A 4 GHz CT ΣΔ ADC with 70 dB DR and −74 dBFS THD in 125 MHz BW," JSSC 46(12), 2011** ✓ id **6029947** (Table II col [6]; the other paper Daniel proposed).
  - Doc: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/document/6029947
  - DOI: https://doi.org/10.1109/JSSC.2011.2164963
- ★ **[7] Cherry & Snelgrove, "Clock jitter and quantizer metastability in CT ΔΣ modulators," TCAS-II 46(6), 1999** — the jitter+metastability theory behind Figs 2/4/27. ✓ id **769775** — *in `refs/`*.
  - Doc: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/document/769775 · DOI: https://doi.org/10.1109/82.769775
- **[8] Pavan, "Alias rejection of CT ΔΣ modulators with SC feedback DACs," TCAS-I 58(2), 2011.**
  - Doc: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/document/5641628 ✓ id 5641628 · PDF: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/stampPDF/getPDF.jsp?tp=&arnumber=5641628&ref=
- **[9] W. Lee, "A novel higher order interpolative modulator topology for high resolution A/D converters," MS thesis, MIT, 1987** — origin of Lee's rule (OBG ≲ 1.5). (MIT DSpace.)
- **[10] Oliaei, "Sigma-delta modulator with spectrally shaped feedback," TCAS-II 50(9), 2003** — alternative FIR-feedback compensation (paper contrasts with it).
  - Doc: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/document/1232527 ✓ id 1232527 · PDF: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/stampPDF/getPDF.jsp?tp=&arnumber=1232527&ref=
- **[11] Putter, "ΣΔ ADC with finite impulse response feedback DAC," ISSCC 2004** — the other FIR-feedback prior art (reduced first-integrator gain).
  - Doc: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/document/1332601 ✓ id 1332601 · PDF: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/stampPDF/getPDF.jsp?tp=&arnumber=1332601&ref=
- ★ **[13] Su & Wooley, "A CMOS oversampling D/A converter with a current-mode semidigital reconstruction filter," JSSC 28(12), 1993** — the **semi-digital FIR DAC** the paper uses. ✓ id **261996** — *in `refs/`*.
  - Doc: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/document/261996 · DOI: https://doi.org/10.1109/4.261996
- ★ **[14] Pavan, "Efficient Simulation of Weak Nonlinearities in Continuous-Time Oversampling Converters," TCAS-I 57(8), 2010** — **the method to model Fig 3 (nonlinear integrator) in MATLAB.** ✓ id **5416327** — *in `refs/`*. (IEEE title is "Weak Nonlinearities"; the chosen paper cites it as "weak loop filter nonlinearities".)
  - Doc: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/document/5416327 ✓ id 5416327
- ★ **[15] Pavan & Sankar, "Power Reduction in Continuous-Time ΔΣ Modulators Using the Assisted Opamp Technique," JSSC 45(7), 2010** — the assisted-opamp block (Fig 10). ✓ id **5492314** — *in `refs/`*.
  - Doc: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/document/5492314
- **[16] Murmann, "ADC Performance Survey 1997–2012"** (the data behind Figs 23/24). The maintained "Murmann ADC Survey" is a public spreadsheet on his academic page — search "Murmann ADC survey" (no stable IEEE link).
- **[17] Adams & Nguyen, "A 113-dB SNR oversampling DAC with segmented noise-shaped scrambling," JSSC 33(12), 1998** — the **dual-RZ** principle for ISI (Q7 improvement).
  - DOI: https://doi.org/10.1109/4.735526

---

## C. Newer / better-topology papers (post-2012) — for Q5/Q6/Q7

All verified live this session unless marked.

- ★ **Sukumaran & Pavan, "Low Power Design Techniques for Single-Bit Audio CT ΔΣ ADCs Using FIR Feedback," JSSC 49(11), 2014.** ✓ id **6862074** — the direct audio evolution of the chosen paper (cited 119×).
  - Doc: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/document/6862074 · PDF: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/stamp/stamp.jsp?tp=&arnumber=6862074
- **Sukumaran & Pavan, "A 280 µW audio CT ΔΣ modulator with 103 dB DR and 102 dB A-weighted SNR," A-SSCC 2013.**
  - Conference precursor of the downloaded `refs/Sukumaran2014_FIR_audio_JSSC.pdf` (same FIR-feedback idea) — just use the 2014 journal version.
- ★ **Zhang, Chen, He, Temes, "A CT ΔΣ Modulator for Biomedical Ultrasound Beamformer Using Digital ELD Compensation and FIR Feedback," TCAS-I 62(7), 2015.** ✓ id **7116629** — **digital ELD comp + FIR** (simpler than the paper's analog comp; Q7).
  - Doc: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/document/7116629 · PDF: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/stamp/stamp.jsp?tp=&arnumber=7116629
- ★ **Jain & Pavan, "Continuous-Time Delta-Sigma Modulators With Time-Interleaved FIR Feedback," TCAS-I 65(2), 2018.** ✓ id **8030132** — more FIR taps without the full delay penalty (Q7).
  - Doc: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/document/8030132 · PDF: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/stamp/stamp.jsp?tp=&arnumber=8030132
- ★ **Billa, Dixit, Pavan, "Analysis and Design of an Audio CT 1-X FIR-MASH ΔΣ Modulator," JSSC 55(10), 2020.** ✓ id **9098038** — FIR + MASH (better topology candidate).
  - Doc: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/document/9098038 · PDF: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/stamp/stamp.jsp?tp=&arnumber=9098038
- ★ **Theertham, Ganta, Pavan, "Design of High-Resolution CT ΔΣ Data Converters With Dual Return-to-Open DACs," JSSC 57(11), 2022.** ✓ id **9792160** — **R2O DAC** attacks ISI/jitter directly (Q7).
  - Doc: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/document/9792160 · PDF: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/stamp/stamp.jsp?tp=&arnumber=9792160
- ★ **Pavan & Baskaran, "What Architecture Should I Choose for my CT ΔΣ Modulator?," ISCAS 2018.** ✓ id **8351141** — tutorial; great for Q5/Q6 framing.
  - Doc: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/document/8351141 · PDF: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/stamp/stamp.jsp?tp=&arnumber=8351141
- **Pavan, "Improved Chopping in CT ΔΣ Converters Using FIR Feedback and N-Path Techniques," TCAS-II 65(5), 2018** — "chopping for free" (Q7 1/f-noise improvement).
  - Doc: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/document/8326528 ✓ id 8326528 · PDF: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/stampPDF/getPDF.jsp?tp=&arnumber=8326528&ref=
- **Manivannan & Pavan, "Improved CT ΔΣ Modulators With Embedded Active Filtering," TCAS-I 67(11), 2020.**
  - Doc: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/document/9162446 ✓ id 9162446 · PDF: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/stampPDF/getPDF.jsp?tp=&arnumber=9162446&ref=
- **Mokhtar, Abdelaal, …, Ortmanns, "A 0.9-V DAC-Calibration-Free CT Incremental ΔΣ Modulator Achieving 97-dB SFDR at 2 MS/s in 28-nm CMOS," JSSC 57(11), 2022.** ✓ id **9744725**
  - Doc: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/document/9744725 · PDF: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/stamp/stamp.jsp?tp=&arnumber=9744725
- **Runge, Edler, Kaiser, Gerfers, "A 18 MS/s 76 dB SNDR 93 dB SFDR CT ΔΣ Modulator … Shared FIR DAC in 22 nm FDSOI," CICC 2021** — modern node, shared FIR DAC.
  - Doc: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/document/9431404 ✓ id 9431404 · PDF: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/stampPDF/getPDF.jsp?tp=&arnumber=9431404&ref=
- **Srivastava et al., "A Small-Area 2nd-Order Adder-Less CT ΔΣ Modulator With Pulse-Shaping FIR DAC for Magnetic Sensing," IEEE OJCAS 5, 2024** (Open Access).
  - Doc: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/document/10475189 ✓ id 10475189 (Open Access) · PDF: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/stampPDF/getPDF.jsp?tp=&arnumber=10475189&ref=
- **Theertham & Pavan, "Challenges in Precision CT ΔΣ Data Converter Design [Feature]," IEEE Circuits and Systems Magazine 23(3), 2023** — recent survey.
  - Doc: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/document/10284564 ✓ id 10284564 · PDF: https://ieeexplore-ieee-org.tudelft.idm.oclc.org/stampPDF/getPDF.jsp?tp=&arnumber=10284564&ref=

---

## D. Textbook & background

- **Pavan, Schreier, Temes, "Understanding Delta-Sigma Data Converters," 2nd ed., Wiley-IEEE Press, 2017** — the standard text; has FIR-DAC, jitter, ELD, CT-mapping chapters. (Wiley/IEEE Xplore book; the course is built on it.)
- **Schreier & Temes, "Understanding Delta-Sigma Data Converters," 1st ed., 2005** — has the delsig toolbox background (we do NOT use the toolbox, but the theory chapters are the reference).

---

## E. How to download via the proxy (notes for the next agent / user)

1. You are already authenticated ("Access provided by: TU Delft Library"). Click the **PDF** link or the red **PDF** button on the Doc page.
2. If a link 404s, open the **search** link, click the result, then the PDF button (the document `id` occasionally changes).
3. For non-IEEE items (theses, Murmann survey, textbook) use the given external links.
4. Downloaded PDFs already live in `practical-exam/refs/` (named `AuthorYear_shorttitle.pdf`); add any extra papers there in the same style.
