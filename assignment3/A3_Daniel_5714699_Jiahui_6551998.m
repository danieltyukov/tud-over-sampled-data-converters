% Assignment 3 - 2nd order modulator continuous time 3-bit quantizer
% Made by:
%   Jiahui Que,       6551998
%   Daniel Tyukov,    5714699
%
% Answers (each block is a self-contained %% section - run with Ctrl+Enter):
%
% Question A - 3-bit CT feed-forward modulator (mid-rise quantizer, thermometer DAC)
%   - Max signal amplitude (peak SQNR): A = 0.84 (Vref = 1), found by sweeping the
%     input amplitude. This MSA is used for the rest of A.
%   - Minimum OSR for SQNR = 100 dB: OSR = 97 (fs = 2*fb*OSR = 3.88 MHz, fb = 20 kHz),
%     SQNR = 100.3 dB at the MSA.
%   - Non-ideal DAC (rise-time = 20% of a clock, ideal fall): SQNR drops from 100 dB
%     to about 21 dB. The slow rise with an instant fall only hurts the rising edge,
%     so the error is asymmetric. In the FFT this shows up as a DC offset (mean of y
%     jumps from about -65 to -26 dBFS) and a 2nd harmonic that climbs to about -30 dBc,
%     which is the even-order signature you expect from a one-sided error. The DC term
%     is most of the in-band noise, so it is what drags the SQNR down. Setting the
%     rise-time back to 0 gives 100.3 dB again, so the rise-time is the cause.
%   - Input-referred thermal noise for SNR = 90 dB (SQNR kept at 100 dB): about
%     827 uVrms at the first integrator input.
%   - Scaling so both swings stay < 0.5 V: b1 = 0.68, b2 = 0.56, c1 = 1.12, and Vref
%     is scaled by k2 as well so the quantizer sees the same ratio. Result is
%     max|w1| = 0.46 V, max|w2| = 0.44 V.
%
% Question B - same modulator with a 1-bit quantizer
%   - Minimum OSR for SQNR = 100 dB: OSR = 240, against OSR = 97 for the 3-bit. So the
%     1-bit needs about 2.5x the OSR for the same SQNR.
%   - Why: the 3-bit has 2 more bits, so roughly 12 dB less quantization noise, plus a
%     higher stable input (0.84 vs 0.7). The NTF is the same 2nd order, so the in-band
%     difference is just the quantizer noise floor.
%   - DAC side: the 1-bit DAC has only two levels, so it is linear by construction with
%     no DEM and no element mismatch. The 3-bit pays for its resolution with that DAC
%     complexity and the rise-time sensitivity seen in A.
%   - 1-bit numbers for reference: non-ideal DAC SQNR about 16 dB, thermal noise for
%     90 dB SNR about 1084 uVrms, scaled b1 = 0.30, b2 = 0.35, c1 = 0.71
%     (max|w1| = 0.45 V, max|w2| = 0.47 V).

%% Question A
clear all; close all; clc;

SNR_vals = []; amp_vals = 0.1:0.02:1;  % amplitudes to sweep

for amplitude = amp_vals
    OSR = 85;
    % Define input sinewave and sampling conditions
    fin        = 1.003; % input frequency (kHz) 
    fb         = 20;
    fs         = 2*fb*OSR;  % sampling frequency (kHz) 
    fres       = 0.05;  % FFT resolution
    offset     = 0.00;
    
    N          = ceil(fs/fres);
    nr_periods = ceil(fin/fres);
    nr_steps   = 10; % number of simulations steps per sample period
    
    % Pre-allocate and initialize array variables => faster code
    in = offset + amplitude*sin(2*pi*(fin/fs)*[1:N*nr_steps]/nr_steps);
    y  = zeros(1,N); y(1) = 0;
    w1 = zeros(1,N*nr_steps); w2 = w1; v = w1; 
    
    % Quantizer definitions
    nr_levels = 8;    % number of levels (3-bit)
    Vref      = 1;  % reference voltage
    
    % Thermometer DAC elements
    elements = ones(1, nr_levels-1);
    
    %**********************************************************************
    % Locate the bins related to the main tone, as well as the inband bins
    %**********************************************************************
    maintone    = nr_periods + 1;
    signal_bins = [maintone-7 : maintone+7];
    inband_bins = 1:round(20/fres);
    noise_bins  = setdiff(inband_bins, signal_bins);
    
    ix      = 1;
    DAC_val = 0;  % NRZ DAC value, held constant over inner loop
    
    
    % CT integrator step coefficients (unity gain per clock period)
    % Adjust coefficients to account for simulation step-size
    om1 = 1/(nr_steps); 
    om2 = 1/(nr_steps); 
    b1 = 1;
    b2 = 1;
    
    c1 = 2*b2;
    c2 = 1;    
    
    %**********************************************************************
    % 2nd-order CIFF CT SDM main loop
    %**********************************************************************
    for a = 2:N+1
        for b = 1:nr_steps
            ix     = ix + 1;
            w2(ix) = w2(ix-1) + om2*b2*w1(ix-1);              % 2nd CT integrator (no DAC feedback)
            w1(ix) = w1(ix-1) + om1*b1*(in(ix-1) - DAC_val);  % 1st CT integrator (NRZ DAC)
            % w1(ix) = w1(ix-1) + om1*b1*(in(ix-1) - y(a-1));  % 1st CT integrator (NRZ DAC)
            v(ix)  = c1*w1(ix) + c2*w2(ix);                % feed-forward sum to quantizer
        end
        [y(a), index] = mbq(v(ix), nr_levels, Vref);        % 3-bit mid-rise quantizer (once per period)
        DAC_val = thermoDACrnd(index, elements, nr_levels);  % randomized thermometer DAC
        % y(a) = 2*(v(ix) >= 0) - 1;
    end
    
    ffty = abs(fft(y(2:N+1)'.*(kaiser(length(y)-1,20)))); % compute magnitude spectrum

    % Use absolute bin indices into ffty to avoid relative-index mismatch
    signal_power = sum(ffty(signal_bins).^2); % sum signal power
    noise_power  = sum(ffty(noise_bins).^2);  % sum noise power
    
    SNR  = 10*log10(signal_power/noise_power); % calculate SNR in dB
    
    ffty_magn = abs(ffty);
    ffty_dB = 20*log10(ffty_magn/max(ffty_magn)); % Scale the spectrum

    SNR_vals(end+1) = SNR; %#ok<SAGROW>
end
% Find amplitude that gives maximum SNR and display it
[~, idx_max] = max(SNR_vals);
best_amplitude = amp_vals(idx_max);
fprintf('Amplitude with max SNR: %.4f (SNR = %.2f dB)\n', best_amplitude, SNR_vals(idx_max));

% Plot SNR vs amplitude
figure(1); clf;
plot(amp_vals, SNR_vals, '-o','LineWidth',1.5);
xlabel('Amplitude'); ylabel('SNR (dB)'); grid on;
title('SNR vs Input Amplitude');


for OSR = 90:1:110
    % Define input sinewave and sampling conditions
    fin        = 1.003; % input frequency (kHz) 
    fb         = 20;
    fs         = 2*fb*OSR;  % sampling frequency (kHz) 
    fres       = 0.05;  % FFT resolution
    amplitude  = best_amplitude;
    offset     = 0.00;
    
    N          = ceil(fs/fres);
    nr_periods = ceil(fin/fres);
    nr_steps   = 20; % number of simulations steps per sample period
    
    % Pre-allocate and initialize array variables => faster code
    in = offset + amplitude*sin(2*pi*(fin/fs)*[1:N*nr_steps]/nr_steps);
    y  = zeros(1,N); y(1) = 0;
    w1 = zeros(1,N*nr_steps); w2 = w1; v = w1; 
    
    % Quantizer definitions
    nr_levels = 8;    % number of levels (3-bit)
    Vref      = 1;  % reference voltage
    
    % Thermometer DAC elements
    elements = ones(1, nr_levels-1);
    
    %**********************************************************************
    % Locate the bins related to the main tone, as well as the inband bins
    %**********************************************************************
    maintone    = nr_periods + 1;
    signal_bins = [maintone-8 : maintone+7];
    inband_bins = 1:round(20/fres);
    noise_bins  = setdiff(inband_bins, signal_bins);
    
    ix      = 1;
    DAC_val = 0;  % NRZ DAC value, held constant over inner loop
    
    
    % CT integrator step coefficients (unity gain per clock period)
    % Adjust coefficients to account for simulation step-size
    om1 = 1/(nr_steps); 
    om2 = 1/(nr_steps); 
    b1 = 1;
    b2 = 1;
    
    c1 = 2*b2;
    c2 = 1;    
    
    for a = 2:N+1
        for b = 1:nr_steps
            ix     = ix + 1;
            w2(ix) = w2(ix-1) + om2*b2*w1(ix-1);              % 2nd CT integrator (no DAC feedback)
            w1(ix) = w1(ix-1) + om1*b1*(in(ix-1) - DAC_val);  % 1st CT integrator (NRZ DAC)
            % w1(ix) = w1(ix-1) + om1*b1*(in(ix-1) - y(a-1));  % 1st CT integrator (NRZ DAC)
            v(ix)  = c1*w1(ix) + c2*w2(ix);                % feed-forward sum to quantizer
        end
        [y(a), index] = mbq(v(ix), nr_levels, Vref);        % 3-bit mid-rise quantizer (once per period)
        DAC_val = thermoDACrnd(index, elements, nr_levels);  % randomized thermometer DAC
        % y(a) = 2*(v(ix) >= 0) - 1;
    end
    
    k1 = 0.45 / max(abs(w1));   % target 0.45 V leaves margin so the noisy run stays under 0.5 V
    k2 = 0.45 / max(abs(w2));
    
    Vref = Vref*k2;
    b1 = b1 * k1;
    b2 = b2 * k2 / k1;
    c1 = c1*b2;
    % b1 = b1 * k1;
    % b2 = b2 * k2 / k1;
    % c1 = c1 / k1;
    % c2 = c2 / k2;

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
            w1(ix) = w1(ix-1) + om1*b1*(in(ix-1) - DAC_val);  % 1st CT integrator (NRZ DAC)
            % w1(ix) = w1(ix-1) + om1*b1*(in(ix-1) - y(a-1));  % 1st CT integrator (NRZ DAC)
            v(ix)  = c1*w1(ix) + c2*w2(ix);                % feed-forward sum to quantizer
        end
        [y(a), index] = mbq(v(ix), nr_levels, Vref);        % 3-bit mid-rise quantizer (once per period)
        DAC_val = thermoDACrnd(index, elements, nr_levels);  % randomized thermometer DAC
        % y(a) = 2*(v(ix) >= 0) - 1;
    end
    
    %**********************************************************************
    % Calculate bitstream FFT, signal and noise powers, and SNR
    %**********************************************************************
    ffty = (fft(y(2:N+1)'.*(kaiser(length(y)-1,20))));
    
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
figure(2);
semilogx((1:round(N/2))*fres*1e3, ffty_dB(1:round(N/2)));
hold on;
semilogx(inband_bins*fres*1e3, ffty_dB(inband_bins), 'g', 'LineWidth', 3);
semilogx(signal_bins*fres*1e3, ffty_dB(signal_bins), 'r', 'LineWidth', 3);
hold off;
legend('fs/2', 'Inband Bins', 'Main tone');
xlabel('Frequency (Hz)'); ylabel('Amplitude (dB)'); grid on;
title('2nd-order modulator with 3-bit quantizer and thermometer DAC output spectrum');

% Plot CT state variables (first 500 clock periods to show sub-step detail)
figure(3);
subplot(3,1,1); plot(w1,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('W1 (1st Integrator)'); grid on;
subplot(3,1,2); plot(w2,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('W2 (2nd Integrator)'); grid on;
subplot(3,1,3); plot(y,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('Y (Bitstream)'); grid;


% non-ideal DAC 
% Pre-allocate CT-resolution state arrays
w1 = zeros(1, N*nr_steps);
w2 = zeros(1, N*nr_steps);
v  = zeros(1, N*nr_steps);

% Quantizer output (one per clock period)
y   = zeros(1, N); y(1) = 0;

ix      = 1;

prev_elements = -ones(1, nr_levels-1);   % all elements start at -1
dac_waveform  = -ones(1, nr_steps);      % consistent initial DAC output

for a = 2:N+1
    for b = 1:nr_steps
        ix     = ix + 1;
        w2(ix) = w2(ix-1) + om2*b2*w1(ix-1);
        w1(ix) = w1(ix-1) + om1*b1*(in(ix-1) - dac_waveform(b));  % sub-step DAC value
        v(ix)  = c1*w1(ix) + c2*w2(ix);
    end
    [y(a), index] = mbq(v(ix), nr_levels, Vref);
    [dac_waveform, prev_elements] = thermoDACrnd_nonideal(index, prev_elements, ...
                                     nr_levels, nr_steps, 0.2);
end
%**********************************************************************
% Calculate bitstream FFT, signal and noise powers, and SNR
%**********************************************************************
ffty = (fft(y(2:N+1)'.*(kaiser(length(y)-1,20))));

inband_power = ffty(inband_bins).*conj(ffty(inband_bins));
signal_power = sum(inband_power(signal_bins));
noise_power  = sum(inband_power(noise_bins));

SNR = 10*log10(signal_power/noise_power);

ffty_magn = abs(ffty);
ffty_magn = ffty_magn/(amplitude*N/2);
ffty_dB   = 20*log10(ffty_magn);

% Asymmetric DAC error: look for a DC offset and harmonic tones in the FFT
dc_offset = mean(y(2:N+1));
h2 = 2*(maintone-1) + 1;   % 2nd harmonic bin
h3 = 3*(maintone-1) + 1;   % 3rd harmonic bin
h2_dBc = 10*log10(sum(abs(ffty(h2-3:h2+3)).^2)/signal_power);
h3_dBc = 10*log10(sum(abs(ffty(h3-3:h3+3)).^2)/signal_power);

figure(4);
semilogx((1:round(N/2))*fres*1e3, ffty_dB(1:round(N/2)));
hold on;
semilogx(inband_bins*fres*1e3, ffty_dB(inband_bins), 'g', 'LineWidth', 3);
semilogx(signal_bins*fres*1e3, ffty_dB(signal_bins), 'r', 'LineWidth', 3);
semilogx([h2 h3]*fres*1e3, ffty_dB([h2 h3]), 'm*', 'MarkerSize', 10, 'LineWidth', 2);
hold off;
legend('fs/2', 'Inband Bins', 'Main tone', '2nd/3rd harmonic');
xlabel('Frequency (Hz)'); ylabel('Amplitude (dB)'); grid on;
title('2nd-order modulator with 3-bit quantizer and non-ideal thermometer DAC output spectrum');

fprintf('New SQNR = %.2f dB (DC offset = %+.4f, 2nd harm = %.1f dBc, 3rd harm = %.1f dBc)\n', ...
        SNR, dc_offset, h2_dBc, h3_dBc);

% Add the calculated noise for 90 dB SNR
noise_rms=amplitude*sqrt(fs*nr_steps/4/fb/10^(90/10));

% Pre-allocate CT-resolution state arrays
w1 = zeros(1, N*nr_steps);
w2 = zeros(1, N*nr_steps);
v  = zeros(1, N*nr_steps);

% Quantizer output (one per clock period)
y   = zeros(1, N); y(1) = 1;

ix      = 1;
DAC_val = 0;  % NRZ DAC value, held constant over inner loop

%**********************************************************************
% 2nd-order CIFF CT SDM main loop
%**********************************************************************
for a = 2:N+1
    for b = 1:nr_steps
        ix     = ix + 1;
        w2(ix) = w2(ix-1) + om2*b2*w1(ix-1);              % 2nd CT integrator (no DAC feedback)
        w1(ix) = w1(ix-1) + om1*b1*(in(ix-1) - DAC_val + noise_rms*randn);  % 1st CT integrator (NRZ DAC)
        % w1(ix) = w1(ix-1) + om1*b1*(in(ix-1) - y(a-1));  % 1st CT integrator (NRZ DAC)
        v(ix)  = c1*w1(ix) + c2*w2(ix);                % feed-forward sum to quantizer
    end
    [y(a), index] = mbq(v(ix), nr_levels, Vref);        % 3-bit mid-rise quantizer (once per period)
    DAC_val = thermoDACrnd(index, elements, nr_levels);  % randomized thermometer DAC
    % y(a) = 2*(v(ix) >= 0) - 1;
end

%**********************************************************************
% Calculate bitstream FFT, signal and noise powers, and SNR
%**********************************************************************
ffty = (fft(y(2:N+1)'.*(kaiser(length(y)-1,20))));

inband_power = ffty(inband_bins).*conj(ffty(inband_bins));
signal_power = sum(inband_power(signal_bins));
noise_power  = sum(inband_power(noise_bins));

SNR = 10*log10(signal_power/noise_power);

ffty_magn = abs(ffty);
ffty_magn = ffty_magn/(amplitude*N/2);
ffty_dB   = 20*log10(ffty_magn);

fprintf('RMS Noise: %.3f uVrms (SNR = %.2f dB)\n', noise_rms*1e6, SNR);
fprintf('Scaled coeffs: b1=%.4f  b2=%.4f  c1=%.4f   (max|w1|=%.3f V, max|w2|=%.3f V)\n', ...
        b1, b2, c1, max(abs(w1)), max(abs(w2)));

% Plot the output spectrum
figure(5);
semilogx((1:round(N/2))*fres*1e3, ffty_dB(1:round(N/2)));
hold on;
semilogx(inband_bins*fres*1e3, ffty_dB(inband_bins), 'g', 'LineWidth', 3);
semilogx(signal_bins*fres*1e3, ffty_dB(signal_bins), 'r', 'LineWidth', 3);
hold off;
legend('fs/2', 'Inband Bins', 'Main tone');
xlabel('Frequency (Hz)'); ylabel('Amplitude (dB)'); grid on;
title('2nd-order modulator with 3-bit quantizer and thermometer DAC output spectrum and thermal noise');


%% Question B - same modulator as A but with a 1-bit quantizer
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
%**********************************************************************
ffty = (fft(y(2:N+1)'.*(kaiser(length(y)-1,20))));

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
figure(2);
semilogx((1:round(N/2))*fres*1e3, ffty_dB(1:round(N/2)));
hold on;
semilogx(inband_bins*fres*1e3, ffty_dB(inband_bins), 'g', 'LineWidth', 3);
semilogx(signal_bins*fres*1e3, ffty_dB(signal_bins), 'r', 'LineWidth', 3);
hold off;
legend('fs/2', 'Inband Bins', 'Main tone');
xlabel('Frequency (Hz)'); ylabel('Amplitude (dB)'); grid on;
title('2nd-order modulator with 3-bit quantizer and thermometer DAC output spectrum');

% Plot CT state variables (first 500 clock periods to show sub-step detail)
figure(3);
subplot(3,1,1); plot(w1,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('W1 (1st Integrator)'); grid on;
subplot(3,1,2); plot(w2,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('W2 (2nd Integrator)'); grid on;
subplot(3,1,3); plot(y,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('Y (Bitstream)'); grid;


% non-ideal DAC 
% Pre-allocate CT-resolution state arrays
w1 = zeros(1, N*nr_steps);
w2 = zeros(1, N*nr_steps);
v  = zeros(1, N*nr_steps);

% Quantizer output (one per clock period)
y   = zeros(1, N); y(1) = 0;

ix      = 1;

rise_steps = round(0.2 * nr_steps);   % = 4 sub-steps
prev_dac   = -1;                       % initial DAC state
dac_waveform = -ones(1, nr_steps);     % initial waveform

for a = 2:N+1
    curr_dac = y(a-1);   % NRZ: this period's DAC value was decided last clock

    if prev_dac == -1 && curr_dac == +1
        % Rising: linear ramp from -1 to +1 over rise_steps
        dac_waveform = -1 + 2*min((0:nr_steps-1), rise_steps) / rise_steps;
    else
        % Falling or no transition: instantaneous
        dac_waveform = curr_dac * ones(1, nr_steps);
    end
    prev_dac = curr_dac;

    for b = 1:nr_steps
        ix     = ix + 1;
        w2(ix) = w2(ix-1) + om2*b2*w1(ix-1);
        w1(ix) = w1(ix-1) + om1*b1*(in(ix-1) - dac_waveform(b));
        v(ix)  = c1*w1(ix) + c2*w2(ix);
    end
    y(a) = 2*(v(ix) >= 0) - 1;
end
%**********************************************************************
% Calculate bitstream FFT, signal and noise powers, and SNR
%**********************************************************************
ffty = (fft(y(2:N+1)'.*(kaiser(length(y)-1,20))));

inband_power = ffty(inband_bins).*conj(ffty(inband_bins));
signal_power = sum(inband_power(signal_bins));
noise_power  = sum(inband_power(noise_bins));

SNR = 10*log10(signal_power/noise_power);

ffty_magn = abs(ffty);
ffty_magn = ffty_magn/(amplitude*N/2);
ffty_dB   = 20*log10(ffty_magn);

figure(4);
semilogx((1:round(N/2))*fres*1e3, ffty_dB(1:round(N/2)));
hold on;
semilogx(inband_bins*fres*1e3, ffty_dB(inband_bins), 'g', 'LineWidth', 3);
semilogx(signal_bins*fres*1e3, ffty_dB(signal_bins), 'r', 'LineWidth', 3);
hold off;
legend('fs/2', 'Inband Bins', 'Main tone');
xlabel('Frequency (Hz)'); ylabel('Amplitude (dB)'); grid on;
title('2nd-order modulator with 3-bit quantizer and non-ideal thermometer DAC output spectrum');

fprintf('New SQNR = %.2f dB\n', SNR);

% Add the calculated noise for 90 dB SNR
noise_rms=amplitude*sqrt(fs*nr_steps/4/fb/10^(90/10));

% Pre-allocate CT-resolution state arrays
w1 = zeros(1, N*nr_steps);
w2 = zeros(1, N*nr_steps);
v  = zeros(1, N*nr_steps);

% Quantizer output (one per clock period)
y   = zeros(1, N); y(1) = 1;

ix      = 1;

%**********************************************************************
% 2nd-order CIFF CT SDM main loop
%**********************************************************************
for a = 2:N+1
    for b = 1:nr_steps
        ix     = ix + 1;
        w2(ix) = w2(ix-1) + om2*b2*w1(ix-1);              % 2nd CT integrator (no DAC feedback)
        w1(ix) = w1(ix-1) + om1*b1*(in(ix-1) - y(a-1) + noise_rms*randn);  % 1st CT integrator (NRZ DAC)
        v(ix)  = c1*w1(ix) + c2*w2(ix);                % feed-forward sum to quantizer
    end
    y(a) = 2*(v(ix) >= 0) - 1;
end

%**********************************************************************
% Calculate bitstream FFT, signal and noise powers, and SNR
%**********************************************************************
ffty = (fft(y(2:N+1)'.*(kaiser(length(y)-1,20))));

inband_power = ffty(inband_bins).*conj(ffty(inband_bins));
signal_power = sum(inband_power(signal_bins));
noise_power  = sum(inband_power(noise_bins));

SNR = 10*log10(signal_power/noise_power);

ffty_magn = abs(ffty);
ffty_magn = ffty_magn/(amplitude*N/2);
ffty_dB   = 20*log10(ffty_magn);

fprintf('RMS Noise: %.3f uVrms (SNR = %.2f dB)\n', noise_rms*1e6, SNR);
fprintf('Scaled coeffs: b1=%.4f  b2=%.4f  c1=%.4f   (max|w1|=%.3f V, max|w2|=%.3f V)\n', ...
        b1, b2, c1, max(abs(w1)), max(abs(w2)));

% Plot the output spectrum
figure(5);
semilogx((1:round(N/2))*fres*1e3, ffty_dB(1:round(N/2)));
hold on;
semilogx(inband_bins*fres*1e3, ffty_dB(inband_bins), 'g', 'LineWidth', 3);
semilogx(signal_bins*fres*1e3, ffty_dB(signal_bins), 'r', 'LineWidth', 3);
hold off;
legend('fs/2', 'Inband Bins', 'Main tone');
xlabel('Frequency (Hz)'); ylabel('Amplitude (dB)'); grid on;
title('2nd-order modulator with 3-bit quantizer and thermometer DAC output spectrum and thermal noise');

%% functions used

function [DAC] = thermoDACrnd(index, elements, nr_levels)
% Realizes a RANDOMIZED thermometer DAC implementing "nr_levels" levels
% "elements" is a vector of NORMALIZED unit DAC elements 
% "index" = [0 .. nr_levels-1] is the thermometer code provided by the quantizer

nr_elements = nr_levels - 1;      % number of DAC elements
DACvect = -ones(1,nr_elements);   % Reset all elements to -1
shuffle = randperm(nr_elements);
DACvect(shuffle(1:index)) = 1;    % Set a random permutation of "index" DAC elements to +1
DAC = (elements*DACvect')/nr_elements; % Build the DAC output from the given unit elements
end

function [q_out, index] = mbq(in, nr_levels, vref)
% Realizes a mid-rise multi-bit quantizer
% "nr_levels" = number of levels between -vref and +vref
% "index" = [0 .. nr_levels-1] is the number of DAC elements with the value of +1
% All other DAC elements should have a value of -1

delta = 2/(nr_levels-1);                      % calculate normalized spacing between quantizer levels
q_out = round((in/vref + 1)/delta)*delta - 1; % shift normalized input range, round to nearest level, then shift back
q_out = sign(in)*min(abs(q_out),1);           % clip quantized input value
index = round((q_out+1)/delta); % Assign a thermometer code index to the decided quantizer level
end

function [dac_waveform, new_elements] = thermoDACrnd_nonideal(index, prev_elements, ...
                                         nr_levels, nr_steps, rise_frac)
% Non-ideal randomized thermometer DAC
% Finite rise-time (rise_frac * Ts), instantaneous fall
%
% index        : thermometer code [0..nr_levels-1]
% prev_elements: element states from previous clock period (+1/-1), 1x(nr_levels-1)
% nr_levels    : 8 for 3-bit
% nr_steps     : CT sub-steps per clock period (20)
% rise_frac    : rise-time as fraction of Ts (0.2)
%
% dac_waveform : DAC value at each sub-step, 1xnr_steps
% new_elements : element states at end of this period, 1x(nr_levels-1)

nr_elements = nr_levels - 1;                    % 7 unit elements
rise_steps  = round(rise_frac * nr_steps);      % 4 sub-steps for 20% of 20

% Random thermometer assignment for new period
new_elements = -ones(1, nr_elements);
shuffle      = randperm(nr_elements);
new_elements(shuffle(1:index)) = +1;

% Build per-sub-step waveform for each element
elem_waveforms = zeros(nr_elements, nr_steps);

for e = 1:nr_elements
    old_val = prev_elements(e);
    new_val = new_elements(e);

    if old_val == -1 && new_val == +1
        % Rising: linear ramp from -1 to +1 over rise_steps sub-steps
        % At sub-step b, value = -1 + 2 * min(b-1, rise_steps) / rise_steps
        ramp = -1 + 2 * min((0:nr_steps-1), rise_steps) / rise_steps;
        elem_waveforms(e, :) = ramp;

    elseif old_val == +1 && new_val == -1
        % Falling: instantaneous (ideal)
        elem_waveforms(e, :) = -1;

    else
        % No transition: hold at current value
        elem_waveforms(e, :) = new_val;
    end
end

% Normalize and sum across elements
dac_waveform = sum(elem_waveforms, 1) / nr_elements;
end