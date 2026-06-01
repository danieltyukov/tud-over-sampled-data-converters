% Assignment 4 - FIR DAC (2nd order feed-forward CT, 1-bit QNT, NRZ DAC)
% Made by:
%   Jiahui Que,       6551998
%   Daniel Tyukov,    5714699
%
% Answers (run top to bottom; Question A sets fs, in and the FFT bins):
%
% Question A - design: OSR = 240 (fs = 9.6 MHz, fb = 20 kHz), A = 0.7 -> SQNR ~ 100 dB.
%
% Part 1 - 3-tap FIR after the modulator (outside the loop): F(z)=(1+z^-1+z^-2)/3 is a
%   moving average, unity at DC, notches at fs/3 and 2fs/3. In-band is left alone,
%   the out-of-band shaped noise is filtered down. Pure post-filter, loop unchanged.
%
% Part 2 - FIR after the QNT (into the loop), no comp: the feedback into int1 is now the
%   multilevel FIR. The 3-tap has ~1 clock group delay, so the loop gets 1 extra clock
%   of delay. Excess loop delay -> NTF peaks, in-band noise rises, integrators nearly
%   run away. SQNR drops 100 -> 70 dB.
%
% Part 3 - break the loop, impulse responses DAC->LF vs DAC->FIR->LF: the FIR just delays
%   the loop response by ~1 clock. Sampled v: h0=[2.5 3.5 4.5 ..], h1=[0.83 2.0 3.5 ..]
%   (= h0 delayed 1 clock), d = h0-h1 = [1.65 1.5 1 1 ..] (settles to 1).
%
% Part 4 - compensate from the impulse responses: put d back with fast paths driven by
%   the 1-bit output. gc = 1.5 into int2 restores the settled 1 (lost integrator gain),
%   cd1 = cd2 = 0.5 direct at the QNT node restores the n=1,2 bumps. Main feedback stays
%   the FIR. SQNR back to ~101 dB, swings back to normal (max|w2| 62 -> 2.4).
%
% Part 5 - with vs without FIR DAC: MSA and STF are basically unchanged once compensated
%   (MSA ~ 0.7-0.8, in-band STF ~ 0 dB, same NTF as the NRZ design). The win is the
%   feedback waveform: 4-level instead of +-1, so much smaller steps -> lower clock
%   jitter sensitivity and a gentler 1st-integrator swing (loop filter linearity), while
%   the 1-bit DAC stays inherently linear (no DEM).

%% Question A

clear all; close all; clc;

for OSR = 230:10:250
% Define input sinewave and sampling conditions
fin        = 1.003; % input frequency (kHz)
fb         = 20;
fs         = 2*fb*OSR;  % sampling frequency (kHz)
fres       = 0.05;  % FFT resolution
amplitude  = 0.7;
offset     = 0.00;

N          = ceil(fs/fres);
nr_periods = ceil(fin/fres);
nr_steps   = 20; % number of simulations steps per sample period

% Pre-allocate and initialize array variables => faster code
in = offset + amplitude*sin(2*pi*(fin/fs)*[1:N*nr_steps]/nr_steps);
y  = zeros(1,N); y(1) = 0;
w1 = zeros(1,N*nr_steps); w2 = w1; v = w1;

%**********************************************************************
% Locate the bins related to the main tone, as well as the inband bins
%**********************************************************************
maintone    = nr_periods + 1;
signal_bins = [maintone-7 : maintone+7];
inband_bins = 1:round(20/fres);
noise_bins  = setdiff(inband_bins, signal_bins);

ix      = 1;


% CT integrator step coefficients (unity gain per clock period)
% Same loop filter as Question A so only the quantizer differs
om1 = 1/(nr_steps);
om2 = 1/(nr_steps);
b1 = 1;
b2 = 1;

c1 = 2*b2;
c2 = 1;

%**********************************************************************
% 2nd-order CIFF CT SDM main loop
%**********************************************************************
for a = 2:N
    for b = 1:nr_steps
        ix     = ix + 1;
        w2(ix) = w2(ix-1) + om2*b2*w1(ix-1);              % 2nd CT integrator (no DAC feedback)
        w1(ix) = w1(ix-1) + om1*b1*(in(ix-1) - y(a-1));  % 1st CT integrator (NRZ DAC)
        v(ix)  = c1*w1(ix) + c2*w2(ix);                % feed-forward sum to quantizer
    end
    y(a) = 2*(v(ix) >= 0) - 1;
end

k1 = 0.45 / max(abs(w1));   % target 0.45 V leaves margin so the noisy run stays under 0.5 V
k2 = 0.45 / max(abs(w2));

% Vref = Vref*k2;
b1 = b1 * k1;
b2 = b2 * k2 / k1;
c1 = c1*b2;

% Pre-allocate CT-resolution state arrays
w1 = zeros(1, N*nr_steps);
w2 = zeros(1, N*nr_steps);
v  = zeros(1, N*nr_steps);

% Quantizer output (one per clock period)
y   = zeros(1, N); y(1) = 0;
ix      = 1;

%**********************************************************************
% 2nd-order CIFF CT SDM main loop
%**********************************************************************
for a = 2:N+1
    for b = 1:nr_steps
        ix     = ix + 1;
        w2(ix) = w2(ix-1) + om2*b2*w1(ix-1);              % 2nd CT integrator (no DAC feedback)
        w1(ix) = w1(ix-1) + om1*b1*(in(ix-1) - y(a-1));  % 1st CT integrator (NRZ DAC)
        v(ix)  = c1*w1(ix) + c2*w2(ix);                % feed-forward sum to quantizer
    end
    y(a) = 2*(v(ix) >= 0) - 1;
end


%**********************************************************************
% Calculate bitstream FFT, signal and noise powers, and SNR

ffty = (fft(y(2:N+1)'.*(kaiser(length(y)-1,20))));
% ffty = (fft(y(2:N+1)'.*rect_filt));

inband_power = ffty(inband_bins).*conj(ffty(inband_bins));
signal_power = sum(inband_power(signal_bins));
noise_power  = sum(inband_power(noise_bins));

SNR = 10*log10(signal_power/noise_power);

ffty_magn = abs(ffty);
ffty_magn = ffty_magn/(amplitude*N/2);
ffty_dB   = 20*log10(ffty_magn);
if (SNR > 100) break;
end
end
fprintf('Oversampling ratio: %.4f (SQNR = %.2f dB, with scaling)\n', OSR, SNR);


% Plot the output spectrum
figure(1);
semilogx((1:round(N/2))*fres*1e3, ffty_dB(1:round(N/2)));
hold on;
semilogx(inband_bins*fres*1e3, ffty_dB(inband_bins), 'g', 'LineWidth', 3);
semilogx(signal_bins*fres*1e3, ffty_dB(signal_bins), 'r', 'LineWidth', 3);
hold off;
legend('fs/2', 'Inband Bins', 'Main tone');
xlabel('Frequency (Hz)'); ylabel('Amplitude (dB)'); grid on;
title('2nd-order modulator with 3-bit quantizer and thermometer DAC output spectrum');

% Plot CT state variables (first 500 clock periods to show sub-step detail)
figure(2);
subplot(3,1,1); plot(w1,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('W1 (1st Integrator)'); grid on;
subplot(3,1,2); plot(w2,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('W2 (2nd Integrator)'); grid on;
subplot(3,1,3); plot(y,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('Y (Bitstream)'); grid;


%% Apply the 3-tap FIR filter to the output

rect_filt = 1/3*ones(1,3);
%**********************************************************************
fir_output = zeros(1,N-2);
for a = 1:N-2
    fir_output(a) = y(a+1:a+3)*rect_filt';
end

ffty = fft(fir_output);
ffty_magn = abs(ffty);
ffty_magn = ffty_magn/(amplitude*N/2);
ffty_dB   = 20*log10(ffty_magn);

% Plot the output spectrum
figure(3);
semilogx((1:round(N/2))*fres*1e3, ffty_dB(1:round(N/2)));
hold on;
semilogx(inband_bins*fres*1e3, ffty_dB(inband_bins), 'g', 'LineWidth', 3);
semilogx(signal_bins*fres*1e3, ffty_dB(signal_bins), 'r', 'LineWidth', 3);
hold off;
legend('fs/2', 'Inband Bins', 'Main tone');
xlabel('Frequency (Hz)'); ylabel('Amplitude (dB)'); grid on;
title('2nd-order modulator with 1-bit quantizer');


%% FIR into the loop
% Feedback into int1 is now the multilevel 3-tap FIR of the bitstream (FIR DAC).
rect_filt = 1/3*ones(1,3);

om1 = 1/(nr_steps);
om2 = 1/(nr_steps);
b1 = 1;
b2 = 1;
c1 = 2*b2;
c2 = 1;

w1 = zeros(1, N*nr_steps); w2 = w1; v = w1;
vn  = zeros(1, N+1);     % 1-bit quantizer output (= modulator output)
fbk = zeros(1, N+1);     % FIR DAC feedback waveform
ix  = 1;

for a = 2:N+1
    for b = 1:nr_steps
        ix     = ix + 1;
        w2(ix) = w2(ix-1) + om2*b2*w1(ix-1);                % 2nd CT integrator (no DAC feedback)
        w1(ix) = w1(ix-1) + om1*b1*(in(ix-1) - fbk(a-1));  % 1st CT integrator (FIR DAC)
        v(ix)  = c1*w1(ix) + c2*w2(ix);                    % feed-forward sum to quantizer
    end
    vn(a)  = 2*(v(ix) >= 0) - 1;                                % 1-bit output
    fbk(a) = (vn(a) + vn(max(a-1,1)) + vn(max(a-2,1)))/3;     % F(z) feedback for next clock
end

%**********************************************************************
% Calculate bitstream FFT, signal and noise powers, and SNR
ffty = (fft(vn(2:N+1)'.*(kaiser(length(vn)-1,20))));

inband_power = ffty(inband_bins).*conj(ffty(inband_bins));
signal_power = sum(inband_power(signal_bins));
noise_power  = sum(inband_power(noise_bins));

SNR = 10*log10(signal_power/noise_power);

ffty_magn = abs(ffty);
ffty_magn = ffty_magn/(amplitude*N/2);
ffty_dB   = 20*log10(ffty_magn);
fprintf('FIR into loop (no comp): SQNR = %.2f dB (max|w1|=%.2f max|w2|=%.2f)\n', SNR, max(abs(w1)), max(abs(w2)));

% Plot the output spectrum
figure(4);
semilogx((1:round(N/2))*fres*1e3, ffty_dB(1:round(N/2)));
hold on;
semilogx(inband_bins*fres*1e3, ffty_dB(inband_bins), 'g', 'LineWidth', 3);
semilogx(signal_bins*fres*1e3, ffty_dB(signal_bins), 'r', 'LineWidth', 3);
hold off;
legend('fs/2', 'Inband Bins', 'Main tone');
xlabel('Frequency (Hz)'); ylabel('Amplitude (dB)'); grid on;
title('FIR DAC in the loop, no compensation');


%% Impulse responses: open-loop (break the loop)
N_ir = 5;   % clock periods to simulate

% Unit NRZ impulse: DAC = 1 for one clock period, then zero
dac_imp     = [1, zeros(1, N_ir)];           % NRZ impulse (a-1 indexing matches y(a-1))
dac_fir_imp = filter(rect_filt, 1, dac_imp); % causal 3-tap FIR of the impulse

L = N_ir*nr_steps + 1;
w1_1 = zeros(1,L); w2_1 = zeros(1,L);
w1_2 = zeros(1,L); w2_2 = zeros(1,L);
v_1 = zeros(1,L); v_2 = zeros(1,L);
om1 = 1/(nr_steps);
om2 = 1/(nr_steps);
b1 = 1;
b2 = 1;
c1 = 2*b2;
c2 = 1;

% Chain 1: DAC => LF  (standard NRZ, no FIR)
ix_ir = 1;
in = zeros(1,L); in(1)=1;
for a = 2:N_ir+1
    for b = 1:nr_steps
        ix_ir = ix_ir + 1;
        w2_1(ix_ir) = w2_1(ix_ir-1) + (om2*b2)*w1_1(ix_ir-1);
        w1_1(ix_ir) = w1_1(ix_ir-1) + (om1*b1)*(dac_imp(a-1));
        v_1(ix_ir) = c1*w1_1(ix_ir) + c2*w2_1(ix_ir);
    end
end

% Chain 2: DAC => FIR => LF  (3-tap FIR shapes the pulse before entering the LF)
ix_ir = 1;
for a = 2:N_ir+1
    for b = 1:nr_steps
        ix_ir = ix_ir + 1;
        w2_2(ix_ir) = w2_2(ix_ir-1) + (om2*(b2))*w1_2(ix_ir-1);
        w1_2(ix_ir) = w1_2(ix_ir-1) + (om1*(b1))*(dac_fir_imp(a-1));
        v_2(ix_ir) = (c1)*w1_2(ix_ir) + (c2)*w2_2(ix_ir);
    end
end

% Sub-step time axis (in clock periods)
t_ir = (0:N_ir*nr_steps) / nr_steps;

% Reconstruct DAC waveforms at sub-step resolution (NRZ hold)
dac_sub_1 = zeros(1,L); dac_sub_2 = zeros(1,L);
for a = 2:N_ir+1
    idx = (a-2)*nr_steps + (2:nr_steps+1);
    dac_sub_1(idx) = dac_imp(a-1);
    dac_sub_2(idx) = dac_fir_imp(a-1);
end

figure(5);
subplot(4,1,1);
plot(t_ir, dac_sub_1, 'b', t_ir, dac_sub_2, 'r--', 'LineWidth', 1.5);
ylabel('DAC output'); grid on;
legend('NRZ impulse (DAC\rightarrowLF)', 'FIR-shaped (DAC\rightarrowFIR\rightarrowLF)');
title('DAC pulse shapes entering the loop filter');

subplot(4,1,2);
plot(t_ir, w1_1, 'b', t_ir, w1_2, 'r--', 'LineWidth', 1.5);
ylabel('w_1'); grid on;
legend('DAC\rightarrowLF', 'DAC\rightarrowFIR\rightarrowLF');
title('1st integrator response');

subplot(4,1,3);
plot(t_ir, w2_1, 'b', t_ir, w2_2, 'r--', 'LineWidth', 1.5);
ylabel('w_2'); grid on;
legend('DAC\rightarrowLF', 'DAC\rightarrowFIR\rightarrowLF');
title('2nd integrator response');

subplot(4,1,4);
plot(t_ir, v_1, 'b', t_ir, v_2, 'r--', 'LineWidth', 1.5);
xlabel('Clock periods'); ylabel('v'); grid on;
legend('DAC\rightarrowLF', 'DAC\rightarrowFIR\rightarrowLF');
title('Loop filter output (v) response');
sgtitle('Open-loop impulse responses: DAC\rightarrowLF vs DAC\rightarrowFIR\rightarrowLF');


%% FIR into the loop + compensation
% Put back d = h0 - h1 (from the impulse responses) with fast paths driven by the
% 1-bit output: gc into int2 restores the settled 1, cd1/cd2 direct at the QNT node
% restore the n=1,2 bumps. Main feedback stays the smooth FIR.
in = offset + amplitude*sin(2*pi*(fin/fs)*[1:N*nr_steps]/nr_steps);   % restore sinewave (Part 3 used an impulse)
rect_filt = 1/3*ones(1,3);

om1 = 1/(nr_steps);
om2 = 1/(nr_steps);
b1 = 1;
b2 = 1;
c1 = 2*b2;
c2 = 1;
gc = 1.5; cd1 = 0.5; cd2 = 0.5;   % compensation read off the impulse responses

w1 = zeros(1, N*nr_steps); w2 = w1; v = w1;
vn  = zeros(1, N+1);
fbk = zeros(1, N+1);
ix  = 1;

for a = 2:N+1
    vc  = vn(a-1);            % prompt 1-bit feedback (1 clock delay)
    vc2 = vn(max(a-2,1));
    for b = 1:nr_steps
        ix     = ix + 1;
        w2(ix) = w2(ix-1) + om2*(b2*w1(ix-1) - gc*vc);         % 2nd integrator + comp DAC
        w1(ix) = w1(ix-1) + om1*b1*(in(ix-1) - fbk(a-1));     % 1st integrator (FIR DAC)
        v(ix)  = c1*w1(ix) + c2*w2(ix) - cd1*vc - cd2*vc2;    % feed-forward + direct comp
    end
    vn(a)  = 2*(v(ix) >= 0) - 1;
    fbk(a) = (vn(a) + vn(max(a-1,1)) + vn(max(a-2,1)))/3;
end

%**********************************************************************
% Calculate bitstream FFT, signal and noise powers, and SNR
ffty = (fft(vn(2:N+1)'.*(kaiser(length(vn)-1,20))));

inband_power = ffty(inband_bins).*conj(ffty(inband_bins));
signal_power = sum(inband_power(signal_bins));
noise_power  = sum(inband_power(noise_bins));

SNR = 10*log10(signal_power/noise_power);

ffty_magn = abs(ffty);
ffty_magn = ffty_magn/(amplitude*N/2);
ffty_dB   = 20*log10(ffty_magn);
fprintf('FIR into loop + comp: SQNR = %.2f dB (max|w1|=%.2f max|w2|=%.2f)\n', SNR, max(abs(w1)), max(abs(w2)));

% Plot the output spectrum
figure(6);
semilogx((1:round(N/2))*fres*1e3, ffty_dB(1:round(N/2)));
hold on;
semilogx(inband_bins*fres*1e3, ffty_dB(inband_bins), 'g', 'LineWidth', 3);
semilogx(signal_bins*fres*1e3, ffty_dB(signal_bins), 'r', 'LineWidth', 3);
hold off;
legend('fs/2', 'Inband Bins', 'Main tone');
xlabel('Frequency (Hz)'); ylabel('Amplitude (dB)'); grid on;
title('FIR DAC in the loop, compensated');


%% MSA and STF: with vs without FIR DAC
% Sweep input amplitude, compare the plain NRZ design and the compensated FIR DAC.
rect_filt = 1/3*ones(1,3);
om1 = 1/(nr_steps);
om2 = 1/(nr_steps);
b1 = 1;
b2 = 1;
c1 = 2*b2;
c2 = 1;
gc = 1.5; cd1 = 0.5; cd2 = 0.5;

amps = 0.1:0.1:0.9;
snr_nrz = zeros(size(amps));
snr_fir = zeros(size(amps));

for k = 1:length(amps)
    in = amps(k)*sin(2*pi*(fin/fs)*[1:N*nr_steps]/nr_steps);

    % plain NRZ modulator
    w1 = zeros(1, N*nr_steps); w2 = w1; v = w1; y = zeros(1, N+1); ix = 1;
    for a = 2:N+1
        for b = 1:nr_steps
            ix     = ix + 1;
            w2(ix) = w2(ix-1) + om2*b2*w1(ix-1);
            w1(ix) = w1(ix-1) + om1*b1*(in(ix-1) - y(a-1));
            v(ix)  = c1*w1(ix) + c2*w2(ix);
        end
        y(a) = 2*(v(ix) >= 0) - 1;
    end
    ffty = fft(y(2:N+1)'.*kaiser(N,20));
    ip = ffty(inband_bins).*conj(ffty(inband_bins));
    snr_nrz(k) = 10*log10(sum(ip(signal_bins))/sum(ip(noise_bins)));

    % compensated FIR DAC modulator
    w1 = zeros(1, N*nr_steps); w2 = w1; v = w1; vn = zeros(1, N+1); fbk = zeros(1, N+1); ix = 1;
    for a = 2:N+1
        vc = vn(a-1); vc2 = vn(max(a-2,1));
        for b = 1:nr_steps
            ix     = ix + 1;
            w2(ix) = w2(ix-1) + om2*(b2*w1(ix-1) - gc*vc);
            w1(ix) = w1(ix-1) + om1*b1*(in(ix-1) - fbk(a-1));
            v(ix)  = c1*w1(ix) + c2*w2(ix) - cd1*vc - cd2*vc2;
        end
        vn(a)  = 2*(v(ix) >= 0) - 1;
        fbk(a) = (vn(a) + vn(max(a-1,1)) + vn(max(a-2,1)))/3;
    end
    ffty = fft(vn(2:N+1)'.*kaiser(N,20));
    ip = ffty(inband_bins).*conj(ffty(inband_bins));
    snr_fir(k) = 10*log10(sum(ip(signal_bins))/sum(ip(noise_bins)));
end

[~, kn] = max(snr_nrz);
[~, kf] = max(snr_fir);
fprintf('MSA: NRZ peak %.1f dB at A=%.1f, FIR+comp peak %.1f dB at A=%.1f\n', ...
        snr_nrz(kn), amps(kn), snr_fir(kf), amps(kf));

figure(7);
plot(amps, snr_nrz, 'ko-', amps, snr_fir, 'bs-', 'LineWidth', 1.5);
xlabel('Input amplitude'); ylabel('SQNR (dB)'); grid on;
legend('NRZ design', 'FIR DAC + comp', 'location', 'southeast');
title('SQNR vs input amplitude (MSA)');
