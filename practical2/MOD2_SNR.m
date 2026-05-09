clc;clear all; close all;

% Input signal definition
fin = 2.003; % input frequency
amplitude = 0.7;
offset = 0.0;
fb  = 4;     % signal bandwidth
fs  = 1000;  % sampling frequency

% Define the sinusoid input signal applied to the input of the modulator
nr_periods = 100;
nr_points = ceil(nr_periods*fs/fin);
in = offset + amplitude*sin(2*pi*[1:nr_points]/(fs/fin));

% Locaate the bins related to the main tone, as well as the inband bins
fres = fs/nr_points;
maintone = round(fin/fres);
signal_bins = [maintone-7:maintone+7];
inband_bins = [1:round(fb/fres)];
noise_bins = setdiff(inband_bins,signal_bins);

% w2 is the second accumulator's output
% w1 is the first accumulator's output
% a is the stabilizing zero coefficient
% Pre-allocate and initialize array variables => faster code
y  = zeros(1,nr_points); y(1) = 1;
w1 = y;  w1(1) = 0;
w2 = y;  w2(1) = 0;
a = 1;

%************************************************************************
% The main loop simulating the second order loop
for i = 2:nr_points,
    w2(i) = w2(i-1) + w1(i-1) - a*y(i-1);
    y(i) = 2*(w2(i)>=0)-1;
    w1(i) = w1(i-1) + in(i) - y(i);
end

% Calculate bitstream FFT, signal and noise powers, and SNR
ffty = (fft(y'.*(kaiser(length(y),20)))); % window output and compute FFT 

% To increase speed determine ONLY the power in the INBAND bins
inband_power = ffty(inband_bins).*conj(ffty(inband_bins));  
signal_power = sum(inband_power(signal_bins)); % sum signal power
noise_power  = sum(inband_power(noise_bins));  % sum noise power

disp('Signal to noise ratio:');
SNR  = 10*log10(signal_power/noise_power) % calculate SNR in dB

%************************************************************************
% Display the output spectrum of the modulator
%************************************************************************
ffty_magn = abs(ffty);
ffty_dB = 20*log10(ffty_magn/max(ffty_magn)); % Scale the spectrum

figure(1); semilogx((1:nr_points/2)*fres,ffty_dB(1:nr_points/2),'-k','LineWidth',1.5);
xlabel('Frequency'); ylabel('Amplitude [dB]'); grid on;
title('Output spectrum of the 2nd order sigma delta modulator'); 

figure(2); semilogx((1:nr_points/2)*fres,ffty_dB(1:nr_points/2));   
hold on;
plot(inband_bins*fres,ffty_dB(inband_bins),'g','LineWidth',3);
plot(signal_bins*fres,ffty_dB(signal_bins),'r','LineWidth',3);
hold off;
legend('Full spectrum','Inband Bins','Main tone', 4);
xlabel('frequency'); ylabel('Amplitude'); grid on;

