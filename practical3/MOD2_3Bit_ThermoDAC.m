% 8-level (3-bit) quantizer, normalized modulator with no scaling,
% more than 90dB of SNR and a (randomized) thermometer DAC

clear all; close all; clc; % clear everything

% Define input sinewave
fin        = 1.003;   % input frequency (kHz) (has no simple integer relationship with fs)
amplitude  = 0.7;     % input amplitude (Volts)
offset     = 0.0;     % input offset (Volts)
fb         = 20;      % signal bandwidth (kHz)
fres       = 0.02;    % define FFT resolution (kHz)
OSR        = 60;  
fs         = 2*fb*OSR;        % sampling frequency (kHz)
N          = round(fs/fres);
nr_periods = round(fin/fres); % simulate a whole number of periods => input falls into an FFT bin

% Quantizer definitions
nr_levels = 8;    % number of levels 
Vref      = 1.0;  % reference voltage

% Thermometer DAC elements 
elements = ones(1,nr_levels-1)

%**********************************************************************
% Locate the bins related to the main tone, as well as the inband bins
%**********************************************************************
maintone    = nr_periods + 1;                   % pointer to main tone
signal_bins = [maintone-7 : maintone+7];        % width of Kaiser(20) window's main lobe
inband_bins = [1:fb/fres];                      % pointer to inband bins
noise_bins  = setdiff(inband_bins,signal_bins); % pointer to noise bins

% Coefficients and Scaling
a2 = 2;
b1 = 1; b2 =1;           % no scaling
     
in = offset + amplitude*sin(2*pi*fin*(1:N)/fs);
    
% Pre-allocate and initialize array variables => faster code
y  = zeros(1,N); y(1) = 1;
DAC = zeros(1,N);
w1 = y;  w1(1) = 0;
w2 = y;  w2(1) = 0.1;

% The main loop simulating the second order loop
for a = 2:N
     w2(a) = w2(a-1) + b2*(w1(a-1) - a2*y(a-1));
     w1(a) = w1(a-1) + b1*(in(a-1) - DAC(a-1));
     [y(a), index] = mbq(w2(a), nr_levels, Vref);
     DAC(a) = thermoDAC(index, elements, nr_levels); % standard DAC
     %DAC(a) = thermoDACrnd(index, elements, nr_levels); % randomized DAC    
end

%**********************************************************************
% Calculate bitstream FFT, signal and noise powers, and SNR
%**********************************************************************
ffty = (fft(y'.*(kaiser(length(y),20)))); % window output and compute FFT 
    
% To increase speed determine ONLY the power in the INBAND bins
inband_power = ffty(inband_bins).*conj(ffty(inband_bins));  
signal_power = sum(inband_power(signal_bins)); % sum signal power
noise_power  = sum(inband_power(noise_bins));  % sum noise power
    
SNR  = 10*log10(signal_power/noise_power); % calculate SNR in dB
    
OSR    % display resulting OSR         
SNR    % display resulting SNR 

ffty_magn = abs(ffty);
ffty_magn = ffty_magn/(amplitude*N/2);    % Scale the spectrum (VERY SIMPLY)
ffty_dB   = 20*log10(ffty_magn);

%Plot the spectrum
figure(1); 
semilogx((1:round(N/2))*fres,ffty_dB(1:round(N/2))); 
hold on; 
semilogx(inband_bins*fres,ffty_dB(inband_bins),'g','LineWidth',3);
semilogx(signal_bins*fres,ffty_dB(signal_bins),'r','LineWidth',3);
hold off;

legend('fs/2','Inband Bins','Main tone');
xlabel('frequency'); ylabel('Amplitude'); grid on;

figure(2)
subplot(3,1,1);
plot(w1); xlabel('Samples'); ylabel('W1 (1st Accumulator)'); grid on;
subplot(3,1,2);
plot(w2); xlabel('Samples'); ylabel('W2 (2nd Accumulator)'); grid on;
subplot(3,1,3);
plot(y);  xlabel('Samples'); ylabel('Y (Quantizer Output)'); grid on;
