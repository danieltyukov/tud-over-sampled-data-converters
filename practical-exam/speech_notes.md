# Oral exam speech notes (first person, minimal)

ET4278, Shettigar & Pavan 2012. Read the sentence under each heading; say more only if they ask. Page numbers match the slide footers.

---

### P1 — Title

This is my paper, a single-bit continuous-time delta-sigma modulator with an FIR (finite impulse response) feedback DAC (digital-to-analog converter), by Shettigar and Pavan, 2012. I built the model in MATLAB and reproduced its results.

### P2 — Q1 Introduction

The problem is that a single-bit modulator is perfectly linear but very sensitive to clock jitter, and comparator metastability makes it worse. Their fix is to filter the one-bit output with an eight-tap FIR (finite impulse response) DAC (digital-to-analog converter), so the feedback moves in small steps and tolerates jitter while staying two-level and linear. The only cost is loop delay, which they fix with the compensation path, and the block diagram at the bottom is the full loop.

### P3 — Q2 Model

This is how I built the model. Only the FIR (finite impulse response) taps come from the paper; I derived the noise transfer function, the loop coefficients, and the compensation filter myself, and the plots on the right confirm the responses.

### P4 — Q2.1 Techniques on and off

Here I switch each technique on and off to show what each one buys. Without the compensation the loop is unstable, the first-tap-zero recovers about forty decibels of metastability, and the FIR (finite impulse response) DAC (digital-to-analog converter) drops the jitter floor by about twenty-five decibels. You can see all four cases in the plot on the right.

### P5 — Q2.2 Voltage scaling

The key result is that the input integrator only sees the small shaped error, so it has the smallest swing, and the swing grows toward the quantizer. You can read that straight off the bar chart below.

### P6 — Q2.3 Thermal noise

Here I add thermal noise and set the dynamic range, landing around eighty decibels. In the plot below, the flat green floor is the thermal noise and the grey part is the shaped noise going out of band.

### P7 — Q2.4 Decimation

On the left the decimator removes all the out-of-band noise, and on the right are the time-domain waveforms, from the raw bitstream down to the recovered sine.

### P8 — Q2.5 List of results

This is a summary of every paper result and whether I reproduced it. I reproduced everything except the literature-survey scatter plots, and my assumptions are on the right.

### P9 — Q2.6A Noise transfer function

From here the paper figure is on the left and mine is on the right. Mine is fourth-order with an out-of-band gain of one-and-a-half and two in-band notches, matching the paper.

### P10 — Q2.6B Signal transfer function

Both are bandpass with about a twelve-decibel peak. Mine peaks a little higher in frequency, so a real system would want an input pre-filter.

### P11 — Q2.6C Output spectrum

This is the output spectrum with a signal tone. My signal-to-noise-and-distortion ratio is about seventy-one and my signal-to-noise ratio about seventy-six, which match the paper's seventy and seventy-five to within a decibel, and the shape is the same.

### P12 — Q2.6D Jitter spectrum

With clock jitter, the plain single-bit floor is the highest, and my FIR (finite impulse response) case sits about twenty-five decibels below it, right with the four-bit.

### P13 — Q2.6E Jitter nulls

This shows why the FIR (finite impulse response) DAC (digital-to-analog converter) filters jitter. The in-band jitter noise, in blue, drops to a null exactly where the DAC (digital-to-analog converter) response has a zero.

### P14 — Q2.6F Jitter tolerance

My FIR (finite impulse response) curve tolerates about ten times more jitter than plain single-bit, and that holds across the whole frequency range. The reason is that each clock edge only switches one small tap instead of a full-scale step.

### P15 — Q2.6G Metastability

Zeroing the first FIR (finite impulse response) tap gives the comparator an extra clock to settle, and it recovers from about fifty-two up to ninety-four decibels.

### P16 — Q2.6H Nonlinear integrator

The input integrator is the critical one, because it sees the raw input and feedback before any shaping. I put a weak cubic nonlinearity on it, and as I increase it the in-band floor rises, because the nonlinearity folds out-of-band noise back in-band.

### P17 — Q2.6I Dynamic range sweep

I sweep the input amplitude and plot the signal-to-noise and signal-to-noise-and-distortion ratios. The peak numbers and the dynamic range match the paper, and near full scale you can see the little inter-symbol-interference kink, which is what limits the very top end.

### P18 — Q3.1 Finite gain and bandwidth

Now the non-idealities. Performance flattens out past about fifty decibels of gain and a couple of gigahertz, so the paper's fifty-five decibels and two gigahertz are plenty.

### P19 — Q3.2 DAC mismatch

A two-level DAC (digital-to-analog converter) has no level mismatch, and the FIR (finite impulse response) tap mismatch only shifts the response nulls slightly. That is the single-bit advantage: mismatch moves the nulls but never creates harmonics, so no dynamic element matching is needed.

### P20 — Q3.3 Excess loop delay

Without compensation the loop goes unstable past about a quarter clock, that's the red curve falling off, and the return-to-zero path in blue keeps it stable.

### P21 — Q3.4 Clock jitter

This is my jitter model. The plain single-bit floor is worst, and the FIR (finite impulse response) case is about ten times better, down at the four-bit level.

### P22 — Q3.5 Integrator nonlinearity

This is the same input-integrator nonlinearity, seen as a non-ideality. The stronger the cubic, the higher the in-band floor, and it drops the signal-to-noise-and-distortion ratio from about ninety-four down to about seventy-six decibels.

### P23 — Q4.1 Loop filter

Now the circuit blocks. This is the loop filter, four active-RC integrators, with the assisted-opamp trick that injects the input current so the amplifier stays relaxed.

### P24 — Q4.2 Feedback DAC

The feedback DAC (digital-to-analog converter) is a tapped delay line of switched resistors, so it is inherently linear and needs no dynamic element matching.

### P25 — Q4.3 Amplifier

A two-stage feed-forward opamp with no Miller capacitor, which reaches about fifty-five decibels of gain and two gigahertz at low power.

### P26 — Q4.4 Comparator

The comparator latch uses a high initial current for fast regeneration and a rail-to-rail output, which beats current-mode logic on power and keeps metastability low.

### P27 — Q4.5 Clock

The clock is an on-chip LC (inductor-capacitor) phase-locked loop, and its jitter ultimately sets the limit for the whole modulator.

### P28 — Q5 Strengths and weaknesses

This is my strengths-and-weaknesses table. The FIR (finite impulse response) DAC (digital-to-analog converter) is the winning idea, giving multi-bit jitter tolerance from a linear, no-DEM (no dynamic element matching) DAC (digital-to-analog converter). Its main cost is the analog compensation filter, which is elegant but needs an extra amplifier and a matched replica, and later designs replace it with a simpler all-digital delay scheme. The one real leftover weakness is inter-symbol interference, which the paper only fixes off-line, and that is exactly what I target in Q7.

### P29 — Q6 Comparison

My extended table is on top and the paper's original is below. The clearest contrast is Bolatkale's four-bit converter from 2011: it reaches a similar bandwidth but burns about two hundred and sixty milliwatts, whereas this work gets there at fifteen, because the single-bit FIR (finite impulse response) approach avoids the power-hungry multi-bit DAC (digital-to-analog converter). In 2012 it had the best figure of merit among converters above seventy decibels, and it has since been beaten by newer FIR (finite impulse response) variants like Jain-Pavan's time-interleaved design.

### P30 — Q7 Improvement

My proposal is to make the inter-symbol-interference correction in-loop and adaptive instead of off-line, or to remove it in hardware with a dual return-to-open DAC (digital-to-analog converter). That is not just theory: the same group's later Theertham design does exactly the return-to-open version. My simulations, on the left and middle, show the correction recovers about five decibels of peak performance and drops the second harmonic by about fifteen.

### P31 — Summary

This paper showed a single-bit modulator can match a multi-bit one using an FIR (finite impulse response) DAC (digital-to-analog converter), and that idea is now standard. It has only been improved in the details it left open.

### P32 — References

These are the references I actually used, the paper plus the key work behind each technique and the comparison.
