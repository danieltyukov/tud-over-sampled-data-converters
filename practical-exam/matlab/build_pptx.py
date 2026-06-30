#!/usr/bin/env python3
"""Assemble the ET4278 final-oral-exam PowerPoint from the TU Delft template.

Fills "Final oral exam templete 2026.pptx" with the content for the assigned
paper (Shettigar & Pavan, JSSC 2012, single-bit CT delta-sigma with FIR DAC),
following 03_presentation_structure.md and the 50-point rubric.

Rules honoured:
  - never reorder or delete a template slide
  - duplicate a slide and suffix the title A/B/C when a question needs more pages
  - put an answer/conclusion on every slide; keep the TU Delft footer/layout
  - embed an image only if it exists, otherwise drop a "[plot: name]" note so the
    script runs before the MATLAB PNGs are generated

Output: ../Final_oral_exam_Daniel_Tyukov_5714699.pptx  (template left untouched).
"""

import copy
import glob
import os

from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from pptx.enum.text import MSO_ANCHOR, PP_ALIGN
from pptx.enum.shapes import PP_PLACEHOLDER

# ---------------------------------------------------------------------------
# paths
# ---------------------------------------------------------------------------
HERE = os.path.dirname(os.path.abspath(__file__))
BASE = os.path.abspath(os.path.join(HERE, ".."))            # practical-exam/
TEMPLATE = os.path.join(BASE, "Final oral exam templete 2026.pptx")
OUTPUT = os.path.join(BASE, "Final_oral_exam_Daniel_Tyukov_5714699.pptx")
FIGURES = os.path.join(BASE, "figures")
# MATLAB PNGs may land in either of these; first hit wins
RESULTS_DIRS = [os.path.join(BASE, "results"), os.path.join(BASE, "matlab", "results")]

BLACK = RGBColor(0, 0, 0)
HEADER_GRAY = RGBColor(0xD9, 0xD9, 0xD9)
WHITE = RGBColor(0xFF, 0xFF, 0xFF)

missing_images = []   # collected for the final report


# ---------------------------------------------------------------------------
# image lookup
# ---------------------------------------------------------------------------
def paper_fig(prefix):
    """Return the figures/<prefix>_*.png|jpg path, or None."""
    hits = sorted(glob.glob(os.path.join(FIGURES, prefix + "_*")))
    if not hits:
        hits = sorted(glob.glob(os.path.join(FIGURES, prefix + "*")))
    return hits[0] if hits else None


def result_img(*names):
    """Return the first existing MATLAB result PNG among the given names."""
    for n in names:
        for d in RESULTS_DIRS:
            p = os.path.join(d, n)
            if os.path.exists(p):
                return p
    return None


# ---------------------------------------------------------------------------
# slide duplication / ordering
# ---------------------------------------------------------------------------
def duplicate_slide(prs, index):
    """Append a deep copy of slide[index] at the end and return it.

    Template slides carry no images yet, so only shapes (text + autoshapes)
    need copying; no image relationships have to be remapped.
    """
    source = prs.slides[index]
    new_slide = prs.slides.add_slide(source.slide_layout)
    # drop the placeholders the layout auto-created, then clone the source shapes
    for shp in list(new_slide.shapes):
        shp._element.getparent().remove(shp._element)
    spTree = new_slide.shapes._spTree
    for shp in source.shapes:
        spTree.append(copy.deepcopy(shp._element))
    return new_slide


def move_slide(prs, old_index, new_index):
    """Move the slide currently at old_index to new_index in the deck order."""
    sldIdLst = prs.slides._sldIdLst
    el = list(sldIdLst)[old_index]
    sldIdLst.remove(el)
    ids = list(sldIdLst)
    if new_index >= len(ids):
        sldIdLst.append(el)
    else:
        sldIdLst.insert(new_index, el)


# ---------------------------------------------------------------------------
# shape helpers
# ---------------------------------------------------------------------------
def shape_by_name(slide, name):
    for sh in slide.shapes:
        if sh.name == name:
            return sh
    return None


def get_title(slide):
    for ph in slide.placeholders:
        if ph.placeholder_format.type in (PP_PLACEHOLDER.TITLE, PP_PLACEHOLDER.CENTER_TITLE):
            return ph
        if ph.placeholder_format.idx == 0:
            return ph
    for sh in slide.shapes:
        if sh.has_text_frame and sh.name.lower().startswith("title"):
            return sh
    return None


def get_body(slide):
    for ph in slide.placeholders:
        if ph.placeholder_format.idx != 0 and ph.has_text_frame:
            return ph
    return None


def set_title(slide, text):
    # keep the layout/master title colour (the title slide uses light text on a
    # dark band); only swap the text itself.
    t = get_title(slide)
    if t is not None:
        t.text_frame.text = text


def set_text(tf, lines, word_wrap=True):
    """Fill a text frame from lines = list of (text, level, bold, size_pt)."""
    tf.word_wrap = word_wrap
    tf.clear()
    first = True
    for text, level, bold, size in lines:
        p = tf.paragraphs[0] if first else tf.add_paragraph()
        first = False
        p.level = level
        p.alignment = PP_ALIGN.LEFT          # template boxes default to centre
        run = p.add_run()
        run.text = text
        run.font.size = Pt(size)
        run.font.bold = bold
        run.font.color.rgb = BLACK


def add_textbox(slide, left, top, width, height, lines, anchor=MSO_ANCHOR.TOP):
    tb = slide.shapes.add_textbox(Inches(left), Inches(top), Inches(width), Inches(height))
    tb.text_frame.word_wrap = True
    tb.text_frame.vertical_anchor = anchor
    set_text(tb.text_frame, lines)
    return tb


def fill_box(slide, name, lines, anchor=MSO_ANCHOR.TOP):
    """Replace an autoshape/placeholder's text (located by name)."""
    sh = shape_by_name(slide, name)
    if sh is None or not sh.has_text_frame:
        return None
    sh.text_frame.vertical_anchor = anchor
    set_text(sh.text_frame, lines)
    return sh


def clear_box_text(slide, name):
    sh = shape_by_name(slide, name)
    if sh is not None and sh.has_text_frame:
        sh.text_frame.clear()
    return sh


def add_image_fit(slide, path, left, top, width, height, note_name=None):
    """Place an image inside an EMU box, preserving aspect, centred.

    Inches() inputs. If the path is missing, drop a small placeholder note.
    """
    if path and os.path.exists(path):
        l, t, w, h = Inches(left), Inches(top), Inches(width), Inches(height)
        pic = slide.shapes.add_picture(path, l, t)
        nw, nh = pic.width, pic.height
        s = min(w / nw, h / nh)
        pic.width = int(nw * s)
        pic.height = int(nh * s)
        pic.left = l + int((w - pic.width) / 2)
        pic.top = t + int((h - pic.height) / 2)
        return pic
    label = note_name or (os.path.basename(path) if path else "image")
    if note_name:
        missing_images.append(note_name)
    add_textbox(slide, left, top + height / 2 - 0.2, width, 0.5,
                [("[plot: %s]" % label, 0, False, 12)], anchor=MSO_ANCHOR.MIDDLE)
    return None


def add_images_row(slide, paths_notes, left, top, width, height):
    """Tile N images side by side inside a box (paths_notes = [(path, note), ...])."""
    n = max(1, len(paths_notes))
    gap = 0.1
    cell_w = (width - gap * (n - 1)) / n
    for i, (p, note) in enumerate(paths_notes):
        add_image_fit(slide, p, left + i * (cell_w + gap), top, cell_w, height, note_name=note)


# ---------------------------------------------------------------------------
# table helper
# ---------------------------------------------------------------------------
def add_table(slide, left, top, width, height, data, col_widths=None, font=10, header=True):
    rows, cols = len(data), len(data[0])
    gf = slide.shapes.add_table(rows, cols, Inches(left), Inches(top), Inches(width), Inches(height))
    table = gf.table
    table.first_row = False
    table.horz_banding = False
    if col_widths:
        for i, w in enumerate(col_widths):
            table.columns[i].width = Inches(w)
    for r in range(rows):
        for c in range(cols):
            cell = table.cell(r, c)
            cell.text = str(data[r][c])
            cell.vertical_anchor = MSO_ANCHOR.TOP
            cell.margin_left = Inches(0.05)
            cell.margin_right = Inches(0.05)
            cell.margin_top = Inches(0.02)
            cell.margin_bottom = Inches(0.02)
            cell.fill.solid()
            cell.fill.fore_color.rgb = HEADER_GRAY if (header and r == 0) else WHITE
            for para in cell.text_frame.paragraphs:
                for run in para.runs:
                    run.font.size = Pt(font)
                    run.font.bold = (header and r == 0)
                    run.font.color.rgb = BLACK
    return table


# convenience tuple shorthands for set_text lines
def H(t, size=16):       # bold header
    return (t, 0, True, size)


def B(t, lvl=1, size=13):  # bullet
    return (t, lvl, False, size)


def C(t, size=13):       # conclusion (bold)
    return ("Conclusion: " + t, 0, True, size)


# ===========================================================================
# build
# ===========================================================================
def build():
    prs = Presentation(TEMPLATE)

    # ---- duplicate slides (high index first so lower-index inserts stay valid)
    # Q4 (index 14): 5 total -> 4 dups at 15..18
    for k in range(4):
        duplicate_slide(prs, 14)
        move_slide(prs, len(prs.slides) - 1, 15 + k)
    # Q2.6 (index 8): 9 total -> 8 dups at 9..16
    for k in range(8):
        duplicate_slide(prs, 8)
        move_slide(prs, len(prs.slides) - 1, 9 + k)

    s = list(prs.slides)
    # final indices
    TITLE = s[0]
    Q1 = s[1]
    Q2 = s[2]
    Q21, Q22, Q23, Q24, Q25 = s[3], s[4], s[5], s[6], s[7]
    Q26 = s[8:17]               # A..I
    Q31, Q32, Q33, Q34, Q35 = s[17], s[18], s[19], s[20], s[21]
    Q41, Q42, Q43, Q44, Q45 = s[22], s[23], s[24], s[25], s[26]
    Q5, Q6, Q7, SUM = s[27], s[28], s[29], s[30]

    # ---- slide 0: title -----------------------------------------------------
    # the title slide has a dark banner: use light text (white title, cyan subtitle)
    CYAN = RGBColor(0x00, 0xA6, 0xD6)
    set_title(TITLE, "Design Techniques for Wideband Single-Bit Continuous-Time "
                     "Delta-Sigma Modulators with FIR Feedback DACs")
    t = get_title(TITLE)
    if t is not None:
        for para in t.text_frame.paragraphs:
            for r in para.runs:
                r.font.color.rgb = WHITE
                r.font.size = Pt(20)
    sub = shape_by_name(TITLE, "Subtitle 2")
    if sub is not None:
        set_text(sub.text_frame, [
            ("Shettigar & Pavan, IEEE JSSC, vol. 47 no. 12, 2012", 0, False, 16),
            ("Daniel Tyukov, 5714699 - ET4278", 0, True, 16),
        ])
        for para in sub.text_frame.paragraphs:
            for r in para.runs:
                r.font.color.rgb = CYAN
    rem = shape_by_name(TITLE, "TextBox 3")     # drop the template remarks box
    if rem is not None:
        rem._element.getparent().remove(rem._element)

    # ---- slide 1: Q1 introduction ------------------------------------------
    set_title(Q1, "Q1. Introduction")
    body = get_body(Q1)
    body.left, body.top, body.width, body.height = Inches(0.45), Inches(1.7), Inches(5.6), Inches(8.6)
    set_text(body.text_frame, [
        H("Issues addressed by the paper"),
        B("Single-bit NRZ feedback: full-scale steps every cycle -> high clock-jitter sensitivity"),
        B("Comparator metastability adds data-dependent jitter -> in-band SNR collapses"),
        B("Full-scale single-bit feedback demands a very linear loop filter"),
        B("Multi-bit avoids these but costs quantizer power/area + DAC mismatch -> DEM/calibration"),
        B("An FIR feedback DAC adds group delay (excess loop delay) that destabilises the loop"),
        H("Main techniques", 15),
        B("1-bit ADC + 8-tap semi-digital FIR feedback DAC (multi-bit-like waveform, 2-level linear, no DEM)"),
        B("First FIR tap = 0 (explicit 1-cycle delay) to dodge metastability"),
        B("Analog FIR-delay compensation: E(z) FIR DAC + bandpass H1(s) restores the target NTF"),
        B("RZ DAC0 for ELD compensation (no summer around the quantizer)"),
        B("Modified CIFB + input feed-forward, active-RC integrators, assisted opamp"),
        C("FIR feedback gives a 1-bit loop the jitter/linearity of a multi-bit loop; the price is "
          "loop delay, solved by an analog compensation path.", 13),
    ])
    add_image_fit(Q1, paper_fig("fig01"), 6.0, 1.7, 7.8, 3.5, note_name="fig01")
    add_image_fit(Q1, paper_fig("fig07"), 6.0, 5.3, 7.8, 4.2, note_name="fig07")

    # ---- slide 2: Q2 model & coefficients ----------------------------------
    set_title(Q2, "Q2. Model and coefficients")
    body = get_body(Q2)
    body.left, body.top, body.width, body.height = Inches(0.45), Inches(1.7), Inches(6.7), Inches(8.6)
    set_text(body.text_frame, [
        H("Coefficients"),
        B("F(z) main FIR, 8 taps: [0.07 0.12 0.15 0.16 0.16 0.15 0.12 0.07], sum = 1"),
        B("E(z) compensation FIR, 7 taps (derived): [0.93 0.81 0.66 0.50 0.34 0.19 0.07]"),
        B("CIFB feedback gains a = [0.0060 0.0457 0.1933 0.5547]"),
        B("Resonator gains g1 = 8.35e-4, g2 = 3.13e-3 (NTF zeros at 0.46, 0.89 of fb)"),
        B("Input feed-forward kff = 1.2 into last integrator (STF peaking); H1(s) bandpass ~100 MHz"),
        B("fs = 3.6 GS/s, fb = 36 MHz, OSR = 50, order = 4, OBG = 1.5"),
        H("Derivation", 15),
        B("Synthesise 4th-order OBG-1.5 NTF (Butterworth-HP poles bisected for OBG) + 2 optimised zeros"),
        B("Match the loop characteristic polynomial -> CIFB coefficients a, g"),
        B("F(z) from Eq.(1); E(z) = (1 - F(z))/(1 - z^-1) (DC gain 0)"),
        B("Fit H1(s) to the replica path by impulse invariance"),
        C("F(z) is taken from the paper; E(z), a, g and H1(s) were derived. The model reproduces "
          "the OBG-1.5 NTF (Fig 8).", 12),
    ])
    add_image_fit(Q2, paper_fig("fig07"), 7.3, 1.7, 6.6, 3.7, note_name="fig07")
    add_image_fit(Q2, result_img("FIRDSM_design_comp.png"), 7.3, 5.6, 6.6, 3.9,
                  note_name="FIRDSM_design_comp.png")

    # ---- slide 3: Q2.1 techniques on/off -----------------------------------
    set_title(Q21, "Q2.1 Techniques on/off")
    body = get_body(Q21)
    body.left, body.top, body.width, body.height = Inches(0.45), Inches(1.7), Inches(6.4), Inches(0.5)
    set_text(body.text_frame, [("Each technique enabled then disabled, quantified in-band (36 MHz):", 0, False, 13)])
    add_table(Q21, 0.45, 2.5, 6.6, 4.4, [
        ["Technique", "OFF", "ON"],
        ["Compensation path", "unstable (~ -45 dB)", "~94 dB"],
        ["First-tap = 0 (metastability)", "~52 dB", "~94 dB"],
        ["FIR DAC (jitter floor)", "plain 1-bit", "~25 dB lower"],
        ["Ideal SQNR (all on)", "-", "~94 dB"],
    ], col_widths=[3.2, 1.9, 1.5], font=14)
    add_image_fit(Q21, result_img("FIRDSM_techniques_onoff.png"), 7.0, 1.7, 6.9, 7.2,
                  note_name="FIRDSM_techniques_onoff.png")
    add_textbox(Q21, 0.45, 8.4, 13.4, 1.0, [
        C("compensation = stability, first-tap-zero = +42 dB (metastability), FIR DAC = ~25 dB "
          "jitter-floor reduction.", 13)])

    # ---- slide 4: Q2.2 voltage scaling -------------------------------------
    set_title(Q22, "Q2.2 Voltage scaling")
    body = get_body(Q22)
    body.left, body.top, body.width, body.height = Inches(0.45), Inches(1.7), Inches(5.2), Inches(6.5)
    set_text(body.text_frame, [
        H("Assumptions"),
        B("Internal full scale = +-1; quantizer output in {-1, +1}"),
        B("FIR DAC makes I4 see only the small shaped error (vin - v1): I4 has the smallest swing (~0.03)"),
        B("Swing grows toward the sign-only quantizer node I1; the first-order (input) path saturates last"),
        B("States map to the 1.2 V supply / Vref; scaling redistributes gain, loop transfer unchanged"),
        C("the input integrator (most linearity-critical) has the smallest swing; scaling preserves the NTF/STF.", 13),
    ])
    add_image_fit(Q22, result_img("FIRDSM_scaling.png"), 5.6, 1.9, 8.2, 6.6,
                  note_name="FIRDSM_scaling.png")

    # ---- slide 5: Q2.3 thermal noise ---------------------------------------
    set_title(Q23, "Q2.3 Thermal noise & spectrum")
    body = get_body(Q23)
    body.left, body.top, body.width, body.height = Inches(0.45), Inches(1.7), Inches(5.2), Inches(6.5)
    set_text(body.text_frame, [
        H("Thermal noise"),
        B("Input-referred Gaussian noise added at the I4 summing node"),
        B("sigma sized so the in-band floor sets the dynamic range (Table I target 83 dB)"),
        B("Noise is unshaped (flat): it sets the floor, separate from the shaped quantisation noise"),
        B("Output PSD in true dBFS so it overlays the paper"),
        C("with the chosen input-referred noise the modulator reaches DR ~ 80 dB over 36 MHz (paper 83).", 13),
    ])
    add_image_fit(Q23, result_img("FIRDSM_thermal.png"), 5.6, 1.9, 8.2, 6.6,
                  note_name="FIRDSM_thermal.png")

    # ---- slide 6: Q2.4 decimation ------------------------------------------
    set_title(Q24, "Q2.4 Decimation filter")
    body = get_body(Q24)
    body.left, body.top, body.width, body.height = Inches(0.45), Inches(1.7), Inches(6.4), Inches(7.0)
    set_text(body.text_frame, [
        H("Decimation filter"),
        B("sinc^(order+1) = sinc^5 CIC, implemented as cascaded box-car averages"),
        B("Decimation factor ~ OSR (50); downsample to ~Nyquist"),
        B("Plot output spectrum before/after decimation + transient waveforms"),
        B("(bitstream, integrator states, recovered sine)"),
        C("decimation removes the out-of-band shaped noise; the in-band SNR is preserved.", 13),
    ])
    body.width = Inches(5.6)
    add_image_fit(Q24, result_img("FIRDSM_decimation.png"), 6.2, 1.6, 7.3, 3.9,
                  note_name="FIRDSM_decimation.png")
    add_image_fit(Q24, result_img("FIRDSM_transient.png"), 6.2, 5.5, 7.3, 3.9,
                  note_name="FIRDSM_transient.png")

    # ---- slide 7: Q2.5 list of simulation results --------------------------
    set_title(Q25, "Q2.5 List of simulation results")
    body = get_body(Q25)
    body.left, body.top, body.width, body.height = Inches(0.45), Inches(1.7), Inches(8.6), Inches(0.4)
    set_text(body.text_frame, [("Paper results and which were reproduced in MATLAB:", 0, False, 12)])
    add_table(Q25, 0.45, 2.2, 8.7, 6.6, [
        ["Result", "Paper value", "Repro"],
        ["NTF (Fig 8)", "4th-order, OBG 1.5, notch ~ -90 dB", "yes"],
        ["STF (Fig 9)", "+12 dB peak ~100 MHz", "yes"],
        ["Output PSD (Fig 22)", "SNDR 70.3, SNR 74.9, HD2 73.5 dB", "yes"],
        ["SNR/SNDR vs amp (Fig 21)", "pk SNR 76.4, SNDR 70.9, DR 83", "yes"],
        ["Jitter PSD (Fig 2)", "FIR ~ 4-bit, << plain 1-bit", "yes"],
        ["Jitter nulls (Fig 26)", "minima at F(z) zeros ~600/800 MHz", "yes"],
        ["Jitter tolerance (Fig 27)", "~10x vs plain 1-bit", "yes"],
        ["Metastability (Fig 4)", "52 -> 94 dB (paper 91)", "yes"],
        ["Nonlinear integrator (Fig 3)", "floor rise = 4-bit case", "yes"],
        ["ISI correction (Figs 29/30)", "HD2 -15 dB, SNDR -> 74.3", "yes"],
        ["Survey scatter (Figs 23/24)", "BW/DR & P/SNDR clouds", "no (survey)"],
    ], col_widths=[2.9, 4.4, 1.4], font=12)
    add_textbox(Q25, 9.3, 2.2, 4.5, 6.6, [
        H("MATLAB assumptions", 14),
        B("fs = 3.6 GS/s, OSR = 50", 1, 12),
        B("Nfft = 2^16", 1, 12),
        B("window kaiser(N, 20)", 1, 12),
        B("coherent input tone", 1, 12),
        B("ns = 20 CT sub-steps/clock", 1, 12),
        B("rng(1) seeded", 1, 12),
        C("reproduced NTF, STF, PSD, SNR/SNDR-vs-A, jitter (2/26/27), metastability (4), "
          "nonlinear integrator (3), ISI (29/30); survey scatter (23/24) not reproducible.", 11),
    ])

    # ---- slides 8..16: Q2.6 A..I comparisons -------------------------------
    q26 = [
        ("Q2.6A NTF",
         "Realised |NTF| vs f/Fs: 4th-order, OBG = 1.5, two optimised in-band notches.",
         "fig08", result_img("FIRDSM_design_NTF.png"), "FIRDSM_design_NTF.png",
         "Same 4th-order high-pass shape as Fig 8: OBG = 1.5 plateau, two in-band notches (~-100 dB)."),
        ("Q2.6B STF",
         "|STF| magnitude from the input feed-forward.",
         "fig09", result_img("FIRDSM_design_STF.png"), "FIRDSM_design_STF.png",
         "Same bandpass shape as Fig 9: ~+12 dB peak then rolls off (peak ~200 MHz vs ~100 MHz); needs input pre-filter."),
        ("Q2.6C Output PSD",
         "Output PSD, -4 dBFS 10 MHz tone, 2^16-pt FFT.",
         "fig22", result_img("FIRDSM_sim_PSD.png"), "FIRDSM_sim_PSD.png",
         "SNDR 71.4 (paper 70.3), SNR 76.5 (74.9), HD2 -73.0 (-73.5) dB."),
        ("Q2.6D Jitter PSD",
         "In-band PSD with 0.3 ps rms white clock jitter: FIR vs plain 1-bit vs 4-bit.",
         "fig02", result_img("FIRDSM_jitter_psd.png"), "FIRDSM_jitter_psd.png",
         "FIR jitter floor ~25 dB below plain 1-bit, similar to 4-bit."),
        ("Q2.6E Jitter filtering (FM nulls)",
         "In-band jitter noise vs FM jitter frequency, overlaid with |F(z)|.",
         "fig26", result_img("FIRDSM_jitter_nulls.png"), "FIRDSM_jitter_nulls.png",
         "In-band jitter noise nulls fall at the zeros of F(z)."),
        ("Q2.6F Jitter tolerance",
         "Max tolerable rms jitter vs jitter frequency: 1-bit+FIR vs 4-bit vs plain 1-bit.",
         "fig27", result_img("FIRDSM_jitter_tolerance.png"), "FIRDSM_jitter_tolerance.png",
         "1-bit+FIR tolerates ~10x more rms jitter than plain 1-bit."),
        ("Q2.6G Metastability",
         "In-band PSD with vs without the first-tap explicit delay.",
         "fig04", result_img("FIRDSM_metastability.png"), "FIRDSM_metastability.png",
         "First-tap-zero recovers ~52 -> ~94 dB (paper 91)."),
        ("Q2.6H Nonlinear integrator",
         "In-band PSD with a weak cubic on the input integrator I4.",
         "fig03", result_img("FIRDSM_nonlin_integrator.png"), "FIRDSM_nonlin_integrator.png",
         "Weak cubic on I4 raises the in-band floor (out-of-band noise demodulation)."),
        ("Q2.6I SNDR vs amplitude",
         "SNR/SNDR vs input amplitude sweep including the ISI kink.",
         "fig21", result_img("FIRDSM_snr_vs_amp.png"), "FIRDSM_snr_vs_amp.png",
         "Peak SNR 75.7, SNDR 71.6, DR ~81 dB; ISI kink near full scale."),
    ]
    for slide, (title, desc, figpref, rimg, rnote, concl) in zip(Q26, q26):
        set_title(slide, title)
        body = get_body(slide)
        if body is not None:
            body.height = Inches(1.0)
            set_text(body.text_frame, [("Simulated: " + desc, 0, False, 13)])
        # left box: published result (paper figure)
        lb = shape_by_name(slide, "Rectangle 1")
        if lb is not None:
            set_text(lb.text_frame, [("Published result - %s" % figpref.upper(), 0, True, 12)])
            lb.text_frame.vertical_anchor = MSO_ANCHOR.TOP
            L = Emu(lb.left).inches; T = Emu(lb.top).inches
            W = Emu(lb.width).inches; Hh = Emu(lb.height).inches
            add_image_fit(slide, paper_fig(figpref), L + 0.1, T + 0.45, W - 0.2, Hh - 0.55,
                          note_name=figpref)
        # right box: your result (MATLAB png)
        rb = shape_by_name(slide, "Rectangle 5")
        if rb is not None:
            set_text(rb.text_frame, [("My result - MATLAB", 0, True, 12)])
            rb.text_frame.vertical_anchor = MSO_ANCHOR.TOP
            L = Emu(rb.left).inches; T = Emu(rb.top).inches
            W = Emu(rb.width).inches; Hh = Emu(rb.height).inches
            add_image_fit(slide, rimg, L + 0.1, T + 0.45, W - 0.2, Hh - 0.55, note_name=rnote)
        # bottom box: quantified comparison
        fill_box(slide, "Rectangle 6", [C(concl, 13)])

    # ---- slides 17..21: Q3 non-idealities ----------------------------------
    def q3(slide, title, lines, rimg, rnote):
        set_title(slide, title)
        clear_box_text(slide, "Rectangle 4")
        big = shape_by_name(slide, "Rectangle 4")
        if big is not None:
            L = Emu(big.left).inches; T = Emu(big.top).inches
            W = Emu(big.width).inches; Hh = Emu(big.height).inches
            add_image_fit(slide, rimg, L + 0.1, T + 0.1, W - 0.2, Hh - 0.2, note_name=rnote)
        fill_box(slide, "Rectangle 5", lines)

    q3(Q31, "Q3.1 Finite amplifier gain & BW", [
        B("Paper: opamp DC gain ~ 55 dB, UGB ~ 2 GHz (Fig 12).", 0, 12),
        B("Model: leaky integrator (finite DC gain) + 1-pole roll-off at UGB on each integrator; swept A_dc and UGB.", 0, 12),
        B("Impact: finite gain leaks the NTF notch (in-band floor rises); finite UGB adds excess phase -> NTF droop.", 0, 12),
        C("negligible penalty needs ~50 dB DC gain and ~2-4 GHz UGB; the paper's 55 dB / 2 GHz is sufficient.", 12),
    ], result_img("FIRDSM_nonideal_gainbw.png"), "FIRDSM_nonideal_gainbw.png")

    q3(Q32, "Q3.2 DAC mismatch", [
        B("A 2-level (1-bit) DAC has NO level mismatch -> intrinsically linear.", 0, 12),
        B("The 8-tap FIR DAC has unit-element (resistor) mismatch; chose sigma ~ 0.5-1% per tap.", 0, 12),
        B("Mismatch perturbs the F(z) coefficients (a LINEAR change) -> shifts the F(z) zeros / jitter nulls and the realised NTF slightly. No new harmonics.", 0, 12),
        C("FIR-tap mismatch moves the jitter nulls and perturbs the NTF; it does not add distortion (unlike a multi-bit DAC).", 12),
    ], result_img("FIRDSM_nonideal_mismatch.png"), "FIRDSM_nonideal_mismatch.png")

    q3(Q33, "Q3.3 Excess loop delay (ELD)", [
        B("Modelled as a fractional-Ts delay in the quantizer -> DAC feedback path.", 0, 12),
        B("Impact: the NTF degrades and the loop goes unstable beyond ~0.25 Ts of excess delay.", 0, 12),
        B("RZ DAC0 (prompt fast feedback into I1) compensates the delay and restores stability.", 0, 12),
        C("ELD must be compensated; the RZ DAC0 path restores the NTF up to the modelled delay.", 12),
    ], result_img("FIRDSM_nonideal_eld.png"), "FIRDSM_nonideal_eld.png")

    q3(Q34, "Q3.4 Clock jitter", [
        B("Modelled white + sinusoidal-FM timing error on the clock edges; error per cycle ~ (v1[n]-v1[n-1])*dt/Ts.", 0, 12),
        B("Impact: the in-band noise floor rises with rms jitter.", 0, 12),
        B("Reduction: the FIR DAC's small steps cut the jitter error ~10x vs plain 1-bit; in-band nulls appear at the F(z) zeros.", 0, 12),
        C("the FIR feedback DAC reduces jitter sensitivity ~10x, to a level comparable with a 4-bit modulator.", 12),
    ], result_img("FIRDSM_jitter_psd.png"), "FIRDSM_jitter_psd.png")

    q3(Q35, "Q3.5 Integrator non-linearity", [
        B("Paper: weak cubic on the input integrator I4: i = Gm*vd - G3*vd^3 (Gm/G3 = 1000, '20,20'; Fig 3).", 0, 12),
        B("The input integrator is the dominant one: its non-linearity acts on the unfiltered input/feedback.", 0, 12),
        B("Modelled as a cubic on the I4 input; impact: it folds out-of-band shaped noise in-band -> floor rises.", 0, 12),
        C("the input integrator sets the linearity budget; G3 raises the in-band floor (SNDR 94 -> 76 dB at G3=0.1).", 12),
    ], result_img("FIRDSM_nonlin_integrator.png"), "FIRDSM_nonlin_integrator.png")

    # ---- slides 22..26: Q4 circuit implementation --------------------------
    def q4(slide, title, lines, figs):
        set_title(slide, title)
        clear_box_text(slide, "Rectangle 4")
        big = shape_by_name(slide, "Rectangle 4")
        if big is not None:
            L = Emu(big.left).inches; T = Emu(big.top).inches
            W = Emu(big.width).inches; Hh = Emu(big.height).inches
            add_images_row(slide, figs, L + 0.1, T + 0.1, W - 0.2, Hh - 0.2)
        fill_box(slide, "Rectangle 5", lines)

    q4(Q41, "Q4.1 Loop filter & assisted opamp", [
        B("Four active-RC integrators (I4..I1); input/feedback resistors set the CIFB coefficients; virtual-ground current summing.", 0, 12),
        B("Assisted-opamp current DACs inject a replica of the input current at the opamp output -> relaxed opamp for fast input currents.", 0, 12),
        B("Reset switches across the caps as anti-lockup; R and C are digitally trimmable banks.", 0, 12),
        C("active-RC loop filter with assisted opamps gives low-distortion integration with small caps and low opamp power.", 12),
    ], [(paper_fig("fig10"), "fig10")])

    q4(Q42, "Q4.2 Semi-digital FIR feedback DAC", [
        B("Tapped delay line filters the 1-bit output by F(z); each tap drives a switched-resistor unit element into the I4 virtual ground.", 0, 12),
        B("Switched resistors avoid current-steering distortion. Reference-side switching = constant loop gain (linear); virtual-ground-side = faster but noisier.", 0, 12),
        B("Resistor (tap) mismatch only perturbs F(z) -> stays linear, no DEM needed.", 0, 12),
        C("the semi-digital FIR DAC turns the 1-bit stream into a small-step, inherently linear multi-level feedback.", 12),
    ], [(paper_fig("fig01"), "fig01"), (paper_fig("fig16"), "fig16")])

    q4(Q43, "Q4.3 Two-stage feed-forward opamp", [
        B("Two-stage feed-forward-compensated opamp (no Miller cap to charge -> power efficient).", 0, 12),
        B("AC-coupling the feed-forward path raises the output swing -> smaller caps, higher integrator gain.", 0, 12),
        B("DC gain ~ 55 dB, UGB ~ 2 GHz; I4 draws 3 mA, I3/I2/I1 0.5 mA each.", 0, 12),
        C("feed-forward compensation meets the 55 dB / 2 GHz target at low power.", 12),
    ], [(paper_fig("fig12"), "fig12")])

    q4(Q44, "Q4.4 Comparator latch", [
        B("Single-phase-clocked latch. Sampling phase: input amplified and held on drain parasitics. Regeneration phase: tail grounded -> very high initial current -> short regeneration time.", 0, 12),
        B("Rail-to-rail CMOS output drives the latch directly (no CML level-shifters).", 0, 12),
        B("Regenerative gain ~4 at 3.6 GS/s vs <1 for an equal-power CML latch -> low metastability.", 0, 12),
        C("the high-initial-current latch beats CML power at 3.6 GS/s and minimises metastability.", 12),
    ], [(paper_fig("fig13"), "fig13"), (paper_fig("fig14"), "fig14"), (paper_fig("fig15"), "fig15")])

    q4(Q45, "Q4.5 Clock: LC-PLL and LC-VCO", [
        B("On-chip LC-PLL: LC-VCO (cross-coupled NMOS, 2x2 nH, MOS varactor + trimmable MIM, 2.4-3.6 GHz), /128, PFD, charge pump, ~100 kHz loop BW.", 0, 12),
        B("Supplies the low-jitter 3.6 GHz clock; simulated VCO phase noise ~ -120 dBc/Hz @ 1 MHz.", 0, 12),
        C("the LC-PLL provides the GS/s clock whose jitter ultimately limits the modulator.", 12),
    ], [(paper_fig("fig18"), "fig18")])

    # ---- slide 27: Q5 strengths & weaknesses -------------------------------
    set_title(Q5, "Q5. Strengths and weaknesses")
    body = get_body(Q5)
    if body is not None:
        body._element.getparent().remove(body._element)
    add_table(Q5, 0.4, 1.7, 13.4, 6.7, [
        ["Technique", "Strength", "Weakness / cost", "Verdict vs today"],
        ["1-bit ADC + FIR feedback DAC",
         "multi-bit-like jitter tolerance + relaxed loop-filter linearity, 2-level linear DAC (no DEM)",
         "adds group delay -> needs compensation; FIR taps add area/routing",
         "still the dominant idea, widely adopted after 2012"],
        ["Analog FIR-delay compensation (E(z)+H1(s))",
         "restores the NTF; bandpass keeps its own jitter/offset out of band; mostly analog",
         "complex to design; extra opamp + matched replicas; RC-spread sensitive",
         "partly superseded by digital ELD / dual-RZ"],
        ["First FIR tap = 0",
         "~40 dB metastability-floor recovery for ~free",
         "costs one tap of filtering depth",
         "clean, still used"],
        ["RZ DAC ELD compensation",
         "no power-hungry summer around the quantizer",
         "RZ adds jitter sensitivity on that path",
         "standard practice"],
        ["CIFB + feed-forward, active-RC, assisted opamp",
         "decoupled fast/precise paths, small caps, low opamp power",
         "STF peaking -> needs input pre-filter; many DAC feed-ins",
         "typical for high-speed CT DSM"],
        ["High-initial-current comparator latch",
         "beats CML power at 3.6 GS/s",
         "custom timing",
         "fine"],
        ["Digital ISI correction (post-facto)",
         "recovers ~3-4 dB SNDR, confirms the ISI origin",
         "off-line, single fixed alpha, not adaptive/on-chip",
         "the obvious improvement target"],
    ], col_widths=[2.7, 4.0, 3.6, 3.1], font=9)
    add_textbox(Q5, 0.4, 8.6, 13.4, 1.6, [
        C("the paper solves jitter, loop-filter linearity and DAC linearity/DEM; the residual "
          "weakness is ISI-induced HD2, fixed only in post-processing (SNDR 70.9 vs ~95 dB SQNR target).", 12)])

    # ---- slide 28: Q6 comparison -------------------------------------------
    set_title(Q6, "Q6. Comparison (extended Table II)")
    body = get_body(Q6)
    if body is not None:
        body._element.getparent().remove(body._element)
    add_table(Q6, 0.3, 1.6, 13.6, 5.4, [
        ["Design (year)", "Tech / Vdd", "BW", "DR", "pk SNDR", "Power", "FoM_S", "Key feature"],
        ["This work '12", "90 nm / 1.2 V", "36 MHz", "86@25M", "71@36M", "15 mW", "176.8", "1-bit, 8-tap FIR + analog ELD comp"],
        ["Bolatkale '11 [6]", "45 nm / 1.1+1.8 V", "125 MHz", "70", "65", "260 mW", "~157", "4-bit CT, cap-FF, direct ELD (no FIR)"],
        ["Sukumaran '14", "180 nm / 1.8 V", "24 kHz", "103", "98.2", "280 uW", "182.3", "1-bit FIR audio + ISI cal + dither"],
        ["Zhang-Temes '15", "65 nm / 1.0 V", "15 MHz", "79.4", "74.3", "6.96 mW", "~172.7", "2-bit, 3-tap FIR + digital ELD + DWA"],
        ["Jain-Pavan '18", "65 nm / 1.4 V", "60 MHz", "76", "67.6", "13.3 mW", "172.5", "1-bit 2x time-interleaved FIR"],
        ["Billa '20", "180 nm / 1.8 V", "24 kHz", "104", "100.9", "265 uW", "180.5", "1-X FIR-MASH, chopping"],
        ["Theertham '22", "180 nm / 1.8 V", "250 kHz", "104", "103.2", "17.7 mW", "174.7", "1-bit, 12-tap FIR + dual R2O DAC + chop"],
    ], col_widths=[1.9, 1.9, 1.1, 1.0, 1.1, 1.2, 1.1, 4.3], font=9)
    add_image_fit(Q6, paper_fig("tableII"), 0.3, 7.05, 6.4, 2.45, note_name="tableII")
    add_textbox(Q6, 7.0, 7.1, 6.9, 2.6, [
        H("Where this work sits", 14),
        B("2012: best FoM among SNDR>70 dB; highest BW among DR>80 dB designs.", 1, 12),
        B("Today: beaten in efficiency by later FIR variants (Jain-Pavan, Billa, Theertham) that add time-interleaving, MASH, chopping, and circuit-level ISI fixes.", 1, 12),
        C("foundational architecture; the FIR DAC idea persists, the compensation/ISI handling has moved on.", 11),
    ])

    # ---- slide 29: Q7 proposed improvements --------------------------------
    set_title(Q7, "Q7. Improvement & verification")
    body = get_body(Q7)
    body.left, body.top, body.width, body.height = Inches(0.45), Inches(1.7), Inches(13.4), Inches(3.4)
    set_text(body.text_frame, [
        H("Proposal: in-loop / adaptive ISI correction (or a dual-RZ / return-to-open DAC)"),
        B("Why: the paper's HD2 (the SNDR limiter) is removed only off-line with a single fixed alpha."),
        B("An adaptive digital alpha tracks process/temperature; a circuit-level dual-RZ/R2O DAC removes ISI directly."),
        B("Updated architecture: keep the 8-tap FIR DAC, replace the post-facto correction with an in-loop ISI path."),
        B("Verified in MATLAB: ISI on/off + correction, reproducing Figs 29/30."),
    ])
    add_textbox(Q7, 0.3, 3.7, 4.4, 0.3, [("PSD: HD2 down ~15 dB (Fig 30)", 0, True, 11)])
    add_textbox(Q7, 4.85, 3.7, 4.4, 0.3, [("SNDR vs amplitude: kink removed (Fig 29)", 0, True, 11)])
    add_textbox(Q7, 9.4, 3.7, 4.3, 0.3, [("paper Fig 30", 0, True, 11)])
    add_image_fit(Q7, result_img("FIRDSM_isi_correction.png"), 0.3, 4.0, 4.4, 4.5,
                  note_name="FIRDSM_isi_correction.png")
    add_image_fit(Q7, result_img("FIRDSM_isi_sndr_vs_amp.png"), 4.85, 4.0, 4.4, 4.5,
                  note_name="FIRDSM_isi_sndr_vs_amp.png")
    add_image_fit(Q7, paper_fig("fig30"), 9.4, 4.0, 4.3, 4.5, note_name="fig30")
    add_textbox(Q7, 0.45, 8.7, 13.4, 0.9, [
        C("ISI correction recovers peak SNDR ~71 -> ~76 dB and drops HD2 ~15 dB (reproduces Figs 29/30; paper 74.3).", 13)])

    # ---- slide 30: summary -------------------------------------------------
    set_title(SUM, "Summary")
    body = get_body(SUM)
    set_text(body.text_frame, [
        H("Overall assessment"),
        ("In 2012 this paper made the case that a single-bit CT delta-sigma could compete with "
         "multi-bit at tens-of-MHz bandwidths by borrowing the multi-bit feedback waveform via an "
         "FIR DAC. The idea proved durable: FIR feedback is now standard across audio, biomedical "
         "and RF CT delta-sigma designs, and the same group extended it with time-interleaved FIR, "
         "FIR-MASH, chopping, and return-to-open DACs.", 0, False, 15),
        ("Where the original is now beaten is in the details it left open: its analog FIR-delay "
         "compensation is complex and its ISI correction is off-line, both addressed by simpler "
         "digital-ELD and circuit-level dual-RZ/R2O techniques in later work. The architecture is "
         "foundational and still cited, but a 2025 redesign would keep the FIR DAC and replace the "
         "compensation/ISI handling.", 0, False, 15),
        C("single-bit + FIR feedback solved the 1-bit jitter/linearity problem and remains "
          "relevant; the compensation and ISI blocks are where modern designs improve on it.", 14),
    ])

    # references slide (only the papers actually used), appended after the summary
    REF = duplicate_slide(prs, 30)
    set_title(REF, "References")
    refs = [
        "[1] P. Shettigar and S. Pavan, \"Design Techniques for Wideband Single-Bit CT Delta-Sigma Modulators With FIR Feedback DACs,\" IEEE JSSC, 47(12), 2012.",
        "[2] J. A. Cherry and W. M. Snelgrove, \"Clock jitter and quantizer metastability in CT Delta-Sigma modulators,\" IEEE TCAS-II, 46(6), 1999.",
        "[3] D. K. Su and B. A. Wooley, \"A CMOS oversampling D/A converter with a current-mode semidigital reconstruction filter,\" IEEE JSSC, 28(12), 1993.",
        "[4] S. Pavan, \"Efficient Simulation of Weak Nonlinearities in CT Oversampling Converters,\" IEEE TCAS-I, 57(8), 2010.",
        "[5] S. Pavan and P. Sankar, \"Power Reduction in CT Delta-Sigma Modulators Using the Assisted Opamp Technique,\" IEEE JSSC, 45(7), 2010.",
        "[6] R. Adams and K. Q. Nguyen, \"A 113-dB SNR oversampling DAC with segmented noise-shaped scrambling,\" IEEE JSSC, 33(12), 1998.",
        "[7] W. L. Lee, \"A novel higher order interpolative modulator topology for high resolution A/D converters,\" MS thesis, MIT, 1987.",
        "[8] G. Mitteregger et al., \"A 20-mW 640-MHz CMOS CT Delta-Sigma ADC with 20-MHz BW, 80-dB DR,\" IEEE JSSC, 41(12), 2006.",
        "[9] M. Bolatkale et al., \"A 4 GHz CT Delta-Sigma ADC with 70 dB DR and -74 dBFS THD in 125 MHz BW,\" IEEE JSSC, 46(12), 2011.",
        "[10] V. Sukumaran and S. Pavan, \"Low Power Design Techniques for Single-Bit Audio CT Delta-Sigma ADCs Using FIR Feedback,\" IEEE JSSC, 49(11), 2014.",
        "[11] Y. Zhang, et al., \"A CT Delta-Sigma Modulator for Ultrasound Using Digital ELD Compensation and FIR Feedback,\" IEEE TCAS-I, 62(7), 2015.",
        "[12] A. Jain and S. Pavan, \"Continuous-Time Delta-Sigma Modulators With Time-Interleaved FIR Feedback,\" IEEE TCAS-I, 65(2), 2018.",
        "[13] S. Billa, A. Dixit, and S. Pavan, \"Analysis and Design of an Audio CT 1-X FIR-MASH Delta-Sigma Modulator,\" IEEE JSSC, 55(10), 2020.",
        "[14] G. Theertham, et al., \"Design of High-Resolution CT Delta-Sigma Data Converters With Dual Return-to-Open DACs,\" IEEE JSSC, 57(11), 2022.",
    ]
    rbody = get_body(REF)
    if rbody is not None:
        rbody.left, rbody.top, rbody.width, rbody.height = Inches(0.7), Inches(1.6), Inches(12.8), Inches(7.6)
        set_text(rbody.text_frame, [(r, 0, False, 12) for r in refs])

    prs.save(OUTPUT)
    return prs


if __name__ == "__main__":
    prs = build()
    n = len(prs.slides)
    print("saved:", OUTPUT)
    print("slide count:", n)
    if missing_images:
        uniq = sorted(set(missing_images))
        print("missing images (placeholders inserted):")
        for m in uniq:
            print("   ", m)
    else:
        print("all referenced images found.")
