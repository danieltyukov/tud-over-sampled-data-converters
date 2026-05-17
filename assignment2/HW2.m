% Assignment 2 - 2nd order modulator
% Made by:
%   Jiahui Que,       6551998
%   Daniel Tyukov,    5714699

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

for fs = 10000:10:16000
    amplitude  = best_amplitude;

    nr_points = round(nr_periods*fs/fin);

    fres = fs/nr_points;
    maintone = round(fin/fres);
    signal_bins = maintone-7:maintone+7;
    % inband_bins = [1:round(fb/fres)];
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

for noise_rms_1 = 50e-6:1e-6:100000e-6
    % Pre-allocation of vectors
    y = zeros(1,nr_points+1); w1 = y; w2 = y; w12 = y; y(1) = 1;
    
    % Feed Forward filter coefficients
    b1 = 1; b2 = 1;
    c1 = 2; c2 = 1;

    % Main modulator Loop
    for a = 2:nr_points+1    
        w2(a)  = w2(a-1) + b2*w1(a-1);
        w1(a)  = w1(a-1)  + b1*(in(a-1) - y(a-1)) + noise_rms_1*randn;
        w12(a) = c1*w1(a) + c2*w2(a);
        y(a)   = 2*(w12(a)>=0)-1;
    end

    % Feed Forward filter coefficients
    k1 = 0.5 / max(abs(w1));
    k2 = 0.5 / max(abs(w2));
    
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
% semilogx((1:nr_points/2)*fres*1e3,ffty_dB(1:nr_points/2));   
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

for fs = 9000:10:16000
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

for noise_rms_1 = 10e-6:1e-6:100000e-6
    % Pre-allocation of vectors
    y = zeros(1,nr_points+1); w1 = y; w2 = y; w12 = y; y(1) = 1;
    
    % Feedback filter coefficients
    b1 = 1; b2 = 1;
    a1 = 1; a2 = 2;
    
    % Main Modulator Loop
    for a = 2:nr_points+1
        w2(a) = w2(a-1) + b2*(w1(a-1)-a2*y(a-1));
        y(a) = 2*(w2(a)>=0)-1;
        w1(a) = w1(a-1) + b1*(in(a-1)-a1*y(a-1)) + noise_rms_1*randn;
    end

    % Feed Forward filter coefficients
    k1 = 0.5 / max(abs(w1));
    k2 = 0.5 / max(abs(w2));
    
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

for fs = 9250:10:16000
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
    
    for d = 0.00003:0.00001:0.0002

        % Feedback filter coefficients
        b1 = 1; b2 = 1;
        a1 = 1; a2 = 2;
        
        % Main Modulator Loop
        for a = 2:nr_points+1 
            w2(a) = w2(a-1) + b2*(w1(a-1)-a2*y(a-1));
            y(a) = 2*(w2(a)>=0)-1;
            w1(a) = w1(a-1) + b1*(in(a-1)-a1*y(a-1)-d*w2(a-1));
        end
        
        
        ffty = abs(fft(y(2:nr_points+1)'.*(kaiser(length(y)-1,20)))); % compute magnitude spectrum
        [~, idx_min] = min(ffty(1:floor(nr_points/2)));
        freq_min = idx_min * fres;
        if abs(freq_min-fb/sqrt(3)) < 0.5
            break;
        end
    end

    % ffty = 20*log10(ffty/max(ffty)/sqrt(2)); % Scale the spectrum

    % Use absolute bin indices into ffty to avoid relative-index mismatch
    signal_power = sum(ffty(signal_bins).^2); % sum signal power
    noise_power  = sum(ffty(noise_bins).^2);  % sum noise power
    
    SNR  = 10*log10(signal_power/noise_power); % calculate SNR in dB
    
    ffty_magn = abs(ffty);
    ffty_dB = 20*log10(ffty_magn/max(ffty_magn)); % Scale the spectrum
    
    if (abs(100-SNR) < 0.1)
        break;
    end
end
d_best = d;
osr = fs/(2*fb);
fprintf('Oversampling ratio: %.4f (SQNR = %.2f dB)\n', osr, SNR);


% Here the noise to the first integrator will be added. First the noise
% level to reach 90dB SNR will be sweeped and then the accumulators will be
% scaled. 
%%
for noise_rms_1 = 10e-6:1e-6:100e-6
    % Pre-allocation of vectors
    y = zeros(1,nr_points+1); w1 = y; w2 = y; w12 = y; y(1) = 1;
    
    % Feedback filter coefficients
    b1 = 1; b2 = 1;
    a1 = 1; a2 = 2;
    d = d_best;
    
    % Main Modulator Loop
    for a = 2:nr_points+1
        w2(a) = w2(a-1) + b2*(w1(a-1)-a2*y(a-1));
        y(a) = 2*(w2(a)>=0)-1;
        w1(a) = w1(a-1) + b1*(in(a-1)-a1*y(a-1)-d*w2(a-1)) + noise_rms_1*randn;
    end

    % Feed Forward filter coefficients
    k1 = 0.5 / max(abs(w1));
    k2 = 0.5 / max(abs(w2));
    
    b1 = b1 * k1;
    b2 = b2 * k2 / k1;
    a1 = 1;   
    a2 = 2*b1;
    d = d/b1/b2;

    % Main Modulator Loop
    for a = 2:nr_points+1 
        w2(a) = w2(a-1) + b2*(w1(a-1)-a2*y(a-1));
        y(a) = 2*(w2(a)>=0)-1;
        w1(a) = w1(a-1) + b1*(in(a-1)-a1*y(a-1)-d*w2(a-1)) + noise_rms_1*randn;
    end
    
    ffty = abs(fft(y(2:nr_points+1)'.*(kaiser(length(y)-1,20)))); % compute magnitude spectrum

    % ffty = 20*log10(ffty/max(ffty)/sqrt(2)); % Scale the spectrum

    % Use absolute bin indices into ffty to avoid relative-index mismatch
    signal_power = sum(ffty(signal_bins).^2); % sum signal power
    noise_power  = sum(ffty(noise_bins).^2);  % sum noise power
    
    SNR  = 10*log10(signal_power/noise_power); % calculate SNR in dB
    
    ffty_magn = abs(ffty);
    ffty_dB = 20*log10(ffty_magn/max(ffty_magn)); % Scale the spectrum
   
    % Stop when SNR is within 0.1 dB of 90 dB (allow small numerical tolerance)
    if abs(SNR - 90) <= 0.1
        break;
    end

end

fprintf('RMS Noise: %.3f uVrms (SNR = %.2f dB)\n', noise_rms_1*1e6, SNR);

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