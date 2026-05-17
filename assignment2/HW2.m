% Assignment 2 - 2nd order modulator
% Made by:
%   Jiahui Que,       6551998
%   Daniel Tyukov,    5714699
%
% Answers (each block is a self-contained %% section - run with Ctrl+Enter):
%
% Question A - 2nd-order FEED-FORWARD modulator
%   - Input amplitude that gives peak SQNR: A = 0.70 V
%     (amp sweep 0.1..1 at fs = 10 MHz, peak SQNR = 100.3 dB).
%   - Minimum OSR for SQNR = 100 dB: OSR = 250 (fs = 10 MHz, fb = 20 kHz).
%   - Thermal noise at the 1st integrator for SNR = 90 dB: ~65 uVrms.
%   - Scaled coefficients (target |w1|,|w2| < 0.5 V):
%       b1 ~ 0.26, b2 ~ 0.29, c1 = 2*b2 ~ 0.59 (c2 stays 1).
%     Scaling rule: b1 = 0.48/max|w1|, b2 = 0.48/(b1*max|w2|), c1 = c*b2.
%     NTF/STF preserved because the quantiser is 1-bit.
%
% Question B - 2nd-order FEEDBACK modulator
%   - Input amplitude that gives peak SQNR: A = 0.65 V (peak SQNR = 100.4 dB).
%   - Minimum OSR for SQNR = 100 dB: OSR = 250 (fs = 10 MHz). Same as A
%     because both topologies share the same NTF magnitude.
%   - Thermal noise at the 1st integrator for SNR = 90 dB: ~35-40 uVrms.
%     (Smaller noise budget than A because w1 follows the input, so b1
%     scales down much more; input-referred noise = noise_rms/b1 is larger.)
%   - Scaled coefficients: b1 ~ 0.15, b2 ~ 0.54, a2 = 2*b1 ~ 0.31 (a1 stays 1).
%     Scaling rule: b1 = 0.48/max|w1|, b2 = 0.48/(b1*max|w2|), a2 = a*b1.
%
% Question C - 2nd-order FEEDBACK modulator with notch (local feedback)
%   - Input amplitude: A = 0.65 V (amp sweep done on basic FB modulator).
%   - Optimal notch (Schreier rule): f_notch = fb/sqrt(3) ~ 11.55 kHz.
%     Theoretical local-FB coefficient d = (2*pi*f_notch/fs)^2.
%     At fs = 9.1 MHz: d_unscaled ~ 3.2e-5.
%   - Minimum OSR for SQNR = 100 dB: OSR = 227.5 (fs = 9.1 MHz).
%     ~9% lower than parts A/B - the notch puts NTF zeros off DC and
%     gives ~3 dB extra in-band SNR.
%   - Thermal noise at the 1st integrator for SNR = 90 dB: ~35 uVrms.
%   - Scaled coefficients: b1 ~ 0.15, b2 ~ 0.54, a2 = 2*b1 ~ 0.31,
%     d_scaled ~ 3.8e-4. Scaling rule: a2 = a*b1, d_scaled = d/(b1*b2).
%
% Question D - Discussion
%   - FF (A) vs FB (B): identical NTF magnitude -> same minimum OSR for the
%     same SQNR target. They differ in WHERE the signal sits: in FF, w1
%     sees only the high-pass shaped quantisation noise, so |w1| is small.
%     In FB, w1 follows the low-pass input, so |w1| is large. After scaling
%     to keep swings < 0.5 V, b1_FF is much larger than b1_FB, which is why
%     FB tolerates much less thermal noise at the integrator output for the
%     same input-referred SNR (here 40 uV vs 65 uV).
%   - Local feedback (C) adds a d-coefficient feeding w2 back into the input
%     of the first integrator. This moves NTF zeros off DC to the unit
%     circle at +-f_notch. With Schreier's optimum f_notch = fb/sqrt(3),
%     the in-band noise integral drops by ~3 dB, which is enough to reach
%     SQNR = 100 dB at a noticeably lower OSR (227.5 instead of 250). The
%     trade-off is a smaller maximum stable input amplitude.
%   - Scaling rules preserve NTF/STF for a 1-bit quantiser: FF requires
%     c* = c*b2; FB requires a* = a*b1; resonator FB additionally needs
%     d* = d/(b1*b2). After scaling, max|w1| and max|w2| both fit inside
%     +-0.5 V as required by the assignment.

%% Question A
%**************************************************************************
% 2nd order feed-forward modulator 
% f_sig => 20Hz - 20kHz 
%**************************************************************************

clear; close all; format long; clc;

% 2nd order sigma-delta with feed-forward loop filter
% Sweeping the amplitude 
SNR_vals = []; amp_vals = 0.1:0.05:1;  % amplitudes to sweep

for amplitude = amp_vals
    % Input and sampling definitions
    fin        = 1.003;  % input frequency (kHz) 
    fs         = 10000;
    fb         = 20;
    offset     = 0.00;
    nr_periods = 300;
    
    nr_points = round(nr_periods*fs/fin);
    
    fres = fs/nr_points;
    maintone = round(fin/fres);
    signal_bins = maintone-7:maintone+7;
    inband_bins = round(0.02/fres):round(20/fres);
    noise_bins = setdiff(inband_bins,signal_bins);
    
    in = offset + amplitude*sin(2*pi*(1:nr_points)/(fs/fin));
    
    % Pre-allocation of vectors
    y = zeros(1,nr_points+1); w1 = y; w2 = y; w12 = y; y(1) = 1;
    
    % Feed Forward filter coefficients
    b1 = 1; b2 = 1;
    c1 = 2; c2 = 1;
    
    % Main modulator Loop
    for a = 2:nr_points+1    
        w2(a)  = w2(a-1) + b2*w1(a-1);
        w1(a)  = w1(a-1)  + b1*(in(a-1) - y(a-1));
        w12(a) = c1*w1(a) + c2*w2(a);
        y(a)   = 2*(w12(a)>=0)-1;
    end
    
    
    ffty = abs(fft(y(2:nr_points+1)'.*(kaiser(length(y)-1,20)))); % compute magnitude spectrum
        
    % % To increase speed determine ONLY the power in the INBAND bins
    % inband_power = ffty(inband_bins).*conj(ffty(inband_bins));  
    % signal_power = sum(inband_power(signal_bins)); % sum signal power
    % noise_power  = sum(inband_power(noise_bins));  % sum noise power

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

% Scan fs from low to high. SNR crosses 100 dB at fs ~ 10 MHz (OSR ~ 250).
% Step 100 kHz keeps the loop short; break at first fs that reaches SQNR > 100.
for fs = 7000:100:13000
    amplitude  = best_amplitude;

    nr_points = round(nr_periods*fs/fin);

    fres = fs/nr_points;
    maintone = round(fin/fres);
    signal_bins = maintone-7:maintone+7;
    inband_bins = round(0.02/fres):round(20/fres);
    noise_bins = setdiff(inband_bins,signal_bins);

    in = offset + amplitude*sin(2*pi*(1:nr_points)/(fs/fin));

    % Pre-allocation of vectors
    y = zeros(1,nr_points+1); w1 = y; w2 = y; w12 = y; y(1) = 1;

    % Feed Forward filter coefficients
    b1 = 1; b2 = 1;
    c1 = 2; c2 = 1;

    % Main modulator Loop
    for a = 2:nr_points+1
        w2(a)  = w2(a-1) + b2*w1(a-1);
        w1(a)  = w1(a-1)  + b1*(in(a-1) - y(a-1));
        w12(a) = c1*w1(a) + c2*w2(a);
        y(a)   = 2*(w12(a)>=0)-1;
    end
    
    
    ffty = abs(fft(y(2:nr_points+1)'.*(kaiser(length(y)-1,20)))); % compute magnitude spectrum

    % ffty = 20*log10(ffty/max(ffty)/sqrt(2)); % Scale the spectrum

    % Use absolute bin indices into ffty to avoid relative-index mismatch
    signal_power = sum(ffty(signal_bins).^2); % sum signal power
    noise_power  = sum(ffty(noise_bins).^2);  % sum noise power
    
    SNR  = 10*log10(signal_power/noise_power); % calculate SNR in dB
    
    ffty_magn = abs(ffty);
    ffty_dB = 20*log10(ffty_magn/max(ffty_magn)); % Scale the spectrum
    
    if (SNR > 100)
        break;
    end
end
osr = fs/(2*fb);
fprintf('Oversampling ratio: %.4f (SQNR = %.2f dB)\n', osr, SNR);

% Here the noise to the first integrator will be added. First the noise
% level to reach 90dB SNR will be sweeped and then the accumulators will be
% scaled. 

% Sweep noise from low to high. Break when scaled SNR drops to 90 dB.
% Step 5 uV gives ~5 uV resolution; range 5 uV - 500 uV is plenty.
for noise_rms_1 = 5e-6:5e-6:500e-6
    % Pre-allocation of vectors
    y = zeros(1,nr_points+1); w1 = y; w2 = y; w12 = y; y(1) = 1;

    % Feed Forward filter coefficients (unscaled run to measure swings)
    b1 = 1; b2 = 1;
    c1 = 2; c2 = 1;

    % Main modulator Loop
    for a = 2:nr_points+1
        w2(a)  = w2(a-1) + b2*w1(a-1);
        w1(a)  = w1(a-1)  + b1*(in(a-1) - y(a-1)) + noise_rms_1*randn;
        w12(a) = c1*w1(a) + c2*w2(a);
        y(a)   = 2*(w12(a)>=0)-1;
    end

    % Scale coefficients: keep |w1|, |w2| < 0.5 V (assignment spec).
    % H*(z) = b1*b2*H(z) if c* = c*b2, so NTF/STF shape is preserved.
    k1 = 0.48 / max(abs(w1));   % target 0.48 V leaves margin for run-to-run randn variation
    k2 = 0.48 / max(abs(w2));

    b1 = b1 * k1;
    b2 = b2 * k2 / k1;
    c1 = 2*b2;
    c2 = 1;

    % Main modulator Loop
    for a = 2:nr_points+1    
        w2(a)  = w2(a-1) + b2*w1(a-1);
        w1(a)  = w1(a-1)  + b1*(in(a-1) - y(a-1)) + noise_rms_1*randn;
        w12(a) = c1*w1(a) + c2*w2(a);
        y(a)   = 2*(w12(a)>=0)-1;
    end
    
    ffty = abs(fft(y(2:nr_points+1)'.*(kaiser(length(y)-1,20)))); % compute magnitude spectrum

    % ffty = 20*log10(ffty/max(ffty)/sqrt(2)); % Scale the spectrum

    % Use absolute bin indices into ffty to avoid relative-index mismatch
    signal_power = sum(ffty(signal_bins).^2); % sum signal power
    noise_power  = sum(ffty(noise_bins).^2);  % sum noise power
    
    SNR  = 10*log10(signal_power/noise_power); % calculate SNR in dB
    
    ffty_magn = abs(ffty);
    ffty_dB = 20*log10(ffty_magn/max(ffty_magn)); % Scale the spectrum
   

    if (SNR <= 90)        
        break;
    end
end

fprintf('RMS Noise: %.3f uVrms (SNR = %.2f dB)\n', noise_rms_1*1e6, SNR);
fprintf('Scaled coeffs: b1=%.4f  b2=%.4f  c1=%.4f   (max|w1|=%.3f V, max|w2|=%.3f V)\n', ...
        b1, b2, c1, max(abs(w1)), max(abs(w2)));

%************************************************************************
% Display the 'time domain' output values
%************************************************************************

figure(2);
subplot(3,1,1); plot(w1,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('w1 (1st Accumulator)');  grid on;
subplot(3,1,2); plot(w2,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('w2 (2nd Accumulator)');  grid on;
subplot(3,1,3); plot(y,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('y (Bitstream)');  grid on;

%************************************************************************
% Display the 'frequency domain' output values
%************************************************************************

figure(3);
semilogx((1:nr_points/2)*fres*1e3, ffty_dB(1:floor(nr_points/2)));
hold on;
plot(inband_bins*fres*1e3,ffty_dB(inband_bins),'g','LineWidth',3);
plot(signal_bins*fres*1e3,ffty_dB(signal_bins),'r','LineWidth',3);
hold off;
legend('Full spectrum','Inband Bins','Main tone');
xlabel('frequency'); ylabel('Amplitude'); grid on;

%% Question B
%**************************************************************************
% 2nd order feedback modulator 
% f_sig => 20Hz - 20kHz 
%**************************************************************************

clear; close all; format long; clc;

% 2nd order sigma-delta with feed-forward loop filter
% Sweeping the amplitude 
SNR_vals = []; amp_vals = 0.1:0.05:1;  % amplitudes to sweep

for amplitude = amp_vals
    % Input and sampling definitions
    fin        = 1.003;  % input frequency (kHz) 
    fs         = 10000;
    fb         = 20;
    offset     = 0.00;
    nr_periods = 300;
    
    nr_points = round(nr_periods*fs/fin);
    
    fres = fs/nr_points;
    maintone = round(fin/fres);
    signal_bins = maintone-7:maintone+7;
    inband_bins = round(0.02/fres):round(20/fres);
    noise_bins = setdiff(inband_bins,signal_bins);
    
    in = offset + amplitude*sin(2*pi*(1:nr_points)/(fs/fin));
    
    % Pre-allocation of vectors
    y = zeros(1,nr_points+1); w1 = y; w2 = y; w12 = y; y(1) = 1;
    
    % Feedback filter coefficients
    b1 = 1; b2 = 1;
    a1 = 1; a2 = 2;
    
    % Main Modulator Loop
    for a = 2:nr_points+1 
        w2(a) = w2(a-1) + b2*(w1(a-1)-a2*y(a-1));
        y(a) = 2*(w2(a)>=0)-1;
        w1(a) = w1(a-1) + b1*(in(a-1)-a1*y(a-1));
    end
    
    
    ffty = abs(fft(y(2:nr_points+1)'.*(kaiser(length(y)-1,20)))); % compute magnitude spectrum
        
    % % To increase speed determine ONLY the power in the INBAND bins
    % inband_power = ffty(inband_bins).*conj(ffty(inband_bins));  
    % signal_power = sum(inband_power(signal_bins)); % sum signal power
    % noise_power  = sum(inband_power(noise_bins));  % sum noise power

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

% Same NTF magnitude as the FF design, so the crossover is again ~10 MHz.
for fs = 7000:100:13000
    amplitude  = best_amplitude;

    nr_points = round(nr_periods*fs/fin);

    fres = fs/nr_points;
    maintone = round(fin/fres);
    signal_bins = maintone-7:maintone+7;
    inband_bins = round(0.02/fres):round(20/fres);
    noise_bins = setdiff(inband_bins,signal_bins);

    in = offset + amplitude*sin(2*pi*(1:nr_points)/(fs/fin));

    % Pre-allocation of vectors
    y = zeros(1,nr_points+1); w1 = y; w2 = y; w12 = y; y(1) = 1;

    % Feedback filter coefficients
    b1 = 1; b2 = 1;
    a1 = 1; a2 = 2;

    % Main Modulator Loop
    for a = 2:nr_points+1
        w2(a) = w2(a-1) + b2*(w1(a-1)-a2*y(a-1));
        y(a) = 2*(w2(a)>=0)-1;
        w1(a) = w1(a-1) + b1*(in(a-1)-a1*y(a-1));
    end
    
    
    ffty = abs(fft(y(2:nr_points+1)'.*(kaiser(length(y)-1,20)))); % compute magnitude spectrum

    % ffty = 20*log10(ffty/max(ffty)/sqrt(2)); % Scale the spectrum

    % Use absolute bin indices into ffty to avoid relative-index mismatch
    signal_power = sum(ffty(signal_bins).^2); % sum signal power
    noise_power  = sum(ffty(noise_bins).^2);  % sum noise power
    
    SNR  = 10*log10(signal_power/noise_power); % calculate SNR in dB
    
    ffty_magn = abs(ffty);
    ffty_dB = 20*log10(ffty_magn/max(ffty_magn)); % Scale the spectrum
    
    if (SNR > 100)
        break;
    end
end
osr = fs/(2*fb);
fprintf('Oversampling ratio: %.4f (SQNR = %.2f dB)\n', osr, SNR);

% Here the noise to the first integrator will be added. First the noise
% level to reach 90dB SNR will be sweeped and then the accumulators will be
% scaled. 

% Sweep noise from low to high. Break when scaled SNR drops to 90 dB.
for noise_rms_1 = 5e-6:5e-6:500e-6
    % Pre-allocation of vectors
    y = zeros(1,nr_points+1); w1 = y; w2 = y; w12 = y; y(1) = 1;

    % Feedback filter coefficients (unscaled run to measure swings)
    b1 = 1; b2 = 1;
    a1 = 1; a2 = 2;

    % Main Modulator Loop
    for a = 2:nr_points+1
        w2(a) = w2(a-1) + b2*(w1(a-1)-a2*y(a-1));
        y(a) = 2*(w2(a)>=0)-1;
        w1(a) = w1(a-1) + b1*(in(a-1)-a1*y(a-1)) + noise_rms_1*randn;
    end

    % Scale FB modulator: a* = a*b1 keeps NTF shape (1-bit Q),
    % b1 = 0.5/max|w1|, b2 = 0.5/(b1*max|w2|).
    k1 = 0.48 / max(abs(w1));   % target 0.48 V leaves margin for run-to-run randn variation
    k2 = 0.48 / max(abs(w2));

    b1 = b1 * k1;
    b2 = b2 * k2 / k1;
    a1 = 1;
    a2 = 2*b1;

    % Main Modulator Loop
    for a = 2:nr_points+1
        w2(a) = w2(a-1) + b2*(w1(a-1)-a2*y(a-1));
        y(a) = 2*(w2(a)>=0)-1;
        w1(a) = w1(a-1) + b1*(in(a-1)-a1*y(a-1)) + noise_rms_1*randn;
    end
    
    ffty = abs(fft(y(2:nr_points+1)'.*(kaiser(length(y)-1,20)))); % compute magnitude spectrum

    % ffty = 20*log10(ffty/max(ffty)/sqrt(2)); % Scale the spectrum

    % Use absolute bin indices into ffty to avoid relative-index mismatch
    signal_power = sum(ffty(signal_bins).^2); % sum signal power
    noise_power  = sum(ffty(noise_bins).^2);  % sum noise power
    
    SNR  = 10*log10(signal_power/noise_power); % calculate SNR in dB
    
    ffty_magn = abs(ffty);
    ffty_dB = 20*log10(ffty_magn/max(ffty_magn)); % Scale the spectrum
   

    if (SNR <= 90)        
        break;
    end
end

fprintf('RMS Noise: %.3f uVrms (SNR = %.2f dB)\n', noise_rms_1*1e6, SNR);
fprintf('Scaled coeffs: b1=%.4f  b2=%.4f  a2=%.4f   (max|w1|=%.3f V, max|w2|=%.3f V)\n', ...
        b1, b2, a2, max(abs(w1)), max(abs(w2)));

%************************************************************************
% Display the 'time domain' output values
%************************************************************************

figure(2);
subplot(3,1,1); plot(w1,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('w1 (1st Accumulator)');  grid on;
subplot(3,1,2); plot(w2,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('w2 (2nd Accumulator)');  grid on;
subplot(3,1,3); plot(y,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('y (Bitstream)');  grid on;

%************************************************************************
% Display the 'frequency domain' output values
%************************************************************************

figure(3); 
semilogx((1:nr_points/2)*fres*1e3, ffty_dB(1:floor(nr_points/2)));
hold on;
plot(inband_bins*fres*1e3,ffty_dB(inband_bins),'g','LineWidth',3);
plot(signal_bins*fres*1e3,ffty_dB(signal_bins),'r','LineWidth',3);
hold off;
legend('Full spectrum','Inband Bins','Main tone');
xlabel('frequency'); ylabel('Amplitude'); grid on;

%% Question C
%**************************************************************************
% 2nd order feedback modulator with notch (local feedback)
% f_sig => 20Hz - 20kHz 
%**************************************************************************

clear; close all; format long; clc;

% 2nd order sigma-delta with feed-forward loop filter
% Sweeping the amplitude 
SNR_vals = []; amp_vals = 0.1:0.05:1;  % amplitudes to sweep

for amplitude = amp_vals
    % Input and sampling definitions
    fin        = 1.003;  % input frequency (kHz) 
    fs         = 10000;
    fb         = 20;
    offset     = 0.00;
    nr_periods = 300;
    
    nr_points = round(nr_periods*fs/fin);
    
    fres = fs/nr_points;
    maintone = round(fin/fres);
    signal_bins = maintone-7:maintone+7;
    inband_bins = round(0.02/fres):round(20/fres);
    noise_bins = setdiff(inband_bins,signal_bins);
    
    in = offset + amplitude*sin(2*pi*(1:nr_points)/(fs/fin));
    
    % Pre-allocation of vectors
    y = zeros(1,nr_points+1); w1 = y; w2 = y; w12 = y; y(1) = 1;
    
    % Feedback filter coefficients
    b1 = 1; b2 = 1;
    a1 = 1; a2 = 2;
    
    % Main Modulator Loop
    for a = 2:nr_points+1 
        w2(a) = w2(a-1) + b2*(w1(a-1)-a2*y(a-1));
        y(a) = 2*(w2(a)>=0)-1;
        w1(a) = w1(a-1) + b1*(in(a-1)-a1*y(a-1));
    end
    
    
    ffty = abs(fft(y(2:nr_points+1)'.*(kaiser(length(y)-1,20)))); % compute magnitude spectrum
        
    % % To increase speed determine ONLY the power in the INBAND bins
    % inband_power = ffty(inband_bins).*conj(ffty(inband_bins));  
    % signal_power = sum(inband_power(signal_bins)); % sum signal power
    % noise_power  = sum(inband_power(noise_bins));  % sum noise power

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

% With the notch (local feedback) we expect a lower minimum OSR than A/B,
% because the in-band noise is suppressed extra by the resonator.
% Schreier: optimal notch at fb/sqrt(3). Theoretical d ~ (2*pi*fb/(sqrt(3)*fs))^2.
% We still sweep d in a small window around the theoretical value to pick
% the one whose actual notch frequency best matches fb/sqrt(3).
f_notch = fb/sqrt(3);

for fs = 5000:100:11000
    amplitude  = best_amplitude;

    nr_points = round(nr_periods*fs/fin);

    fres = fs/nr_points;
    maintone = round(fin/fres);
    signal_bins = maintone-7:maintone+7;
    inband_bins = round(0.02/fres):round(20/fres);
    noise_bins = setdiff(inband_bins,signal_bins);

    in = offset + amplitude*sin(2*pi*(1:nr_points)/(fs/fin));

    d_theory = (2*pi*f_notch/fs)^2;
    d_grid   = d_theory*linspace(0.5,1.8,8);  % narrow sweep around theory

    best_SNR = -Inf;
    best_d   = d_theory;
    for d = d_grid
        % Pre-allocation of vectors (per d trial)
        y = zeros(1,nr_points+1); w1 = y; w2 = y; w12 = y; y(1) = 1;

        % Feedback filter coefficients
        b1 = 1; b2 = 1;
        a1 = 1; a2 = 2;

        % Main Modulator Loop with local feedback (d * w2)
        for a = 2:nr_points+1
            w2(a) = w2(a-1) + b2*(w1(a-1)-a2*y(a-1));
            y(a) = 2*(w2(a)>=0)-1;
            w1(a) = w1(a-1) + b1*(in(a-1)-a1*y(a-1)-d*w2(a-1));
        end

        ffty = abs(fft(y(2:nr_points+1)'.*(kaiser(length(y)-1,20))));
        sp = sum(ffty(signal_bins).^2);
        np = sum(ffty(noise_bins).^2);
        S  = 10*log10(sp/np);
        if S > best_SNR
            best_SNR = S; best_d = d;
        end
    end

    % Use absolute bin indices into ffty to avoid relative-index mismatch
    signal_power = sum(ffty(signal_bins).^2); % sum signal power
    noise_power  = sum(ffty(noise_bins).^2);  % sum noise power

    SNR  = best_SNR;
    d    = best_d;

    ffty_magn = abs(ffty);
    ffty_dB = 20*log10(ffty_magn/max(ffty_magn)); % Scale the spectrum

    if SNR > 100
        break;
    end
end
d_best = d;
osr = fs/(2*fb);
fprintf('Oversampling ratio: %.4f (SQNR = %.2f dB)\n', osr, SNR);


% Here the noise to the first integrator will be added. First the noise
% level to reach 90dB SNR will be sweeped and then the accumulators will be
% scaled. Break when scaled SNR first drops to/below 90 dB.
for noise_rms_1 = 5e-6:5e-6:500e-6
    % Pre-allocation of vectors
    y = zeros(1,nr_points+1); w1 = y; w2 = y; w12 = y; y(1) = 1;

    % Feedback filter coefficients (unscaled run with notch)
    b1 = 1; b2 = 1;
    a1 = 1; a2 = 2;
    d = d_best;

    % Main Modulator Loop
    for a = 2:nr_points+1
        w2(a) = w2(a-1) + b2*(w1(a-1)-a2*y(a-1));
        y(a) = 2*(w2(a)>=0)-1;
        w1(a) = w1(a-1) + b1*(in(a-1)-a1*y(a-1)-d*w2(a-1)) + noise_rms_1*randn;
    end

    % Scale resonator FB modulator: a* = a*b1, d* = d/(b1*b2)
    k1 = 0.48 / max(abs(w1));   % target 0.48 V leaves margin for run-to-run randn variation
    k2 = 0.48 / max(abs(w2));

    b1 = b1 * k1;
    b2 = b2 * k2 / k1;
    a1 = 1;
    a2 = 2*b1;
    d = d/b1/b2;

    % Main Modulator Loop with scaled coefficients
    for a = 2:nr_points+1
        w2(a) = w2(a-1) + b2*(w1(a-1)-a2*y(a-1));
        y(a) = 2*(w2(a)>=0)-1;
        w1(a) = w1(a-1) + b1*(in(a-1)-a1*y(a-1)-d*w2(a-1)) + noise_rms_1*randn;
    end

    ffty = abs(fft(y(2:nr_points+1)'.*(kaiser(length(y)-1,20))));

    signal_power = sum(ffty(signal_bins).^2);
    noise_power  = sum(ffty(noise_bins).^2);

    SNR  = 10*log10(signal_power/noise_power);

    ffty_magn = abs(ffty);
    ffty_dB = 20*log10(ffty_magn/max(ffty_magn));

    if SNR <= 90
        break;
    end
end

fprintf('RMS Noise: %.3f uVrms (SNR = %.2f dB)\n', noise_rms_1*1e6, SNR);
fprintf('Scaled coeffs: b1=%.4f  b2=%.4f  a2=%.4f  d_scaled=%.5g  (max|w1|=%.3f V, max|w2|=%.3f V)\n', ...
        b1, b2, a2, d, max(abs(w1)), max(abs(w2)));
fprintf('Notch design: d_best(unscaled)=%.5g, f_notch_target=%.3f kHz\n', d_best, fb/sqrt(3));

% Display the 'time domain' output values
figure(2);
subplot(3,1,1); plot(w1,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('w1 (1st Accumulator)');  grid on;
subplot(3,1,2); plot(w2,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('w2 (2nd Accumulator)');  grid on;
subplot(3,1,3); plot(y,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('y (Bitstream)');  grid on;

% Display the 'frequency domain' output values
figure(3); 
semilogx((1:nr_points/2)*fres*1e3, ffty_dB(1:floor(nr_points/2)));
hold on;
plot(inband_bins*fres*1e3,ffty_dB(inband_bins),'g','LineWidth',3);
plot(signal_bins*fres*1e3,ffty_dB(signal_bins),'r','LineWidth',3);
hold off;
legend('Full spectrum','Inband Bins','Main tone');
xlabel('frequency'); ylabel('Amplitude'); grid on;