clear all
close all;

%Input signal definition
% Input and sampling definitions
fin        = 1.003;  % input frequency (kHz) 
fs         = 1000;   % sampling frequency (kHz) 
amplitude  = 0;
offset     = 34.6e-3;
nr_periods = 200;

% system bandwidth
fb = 2;

N = round(nr_periods*fs/fin);

in = offset + amplitude*sin(2*pi*[1:N]/(fs/fin));

% define noise parameters

noise_rms_1=0;
%noise_rms_1=100e-6;

% Pre-allocate and initialize array variables => faster code
% w2 is the second accumulator's output
% w1 is the first accumulator's output
% a is the stabilizing zero coefficient

a = 1;

w1 = zeros(1,N);
w2 = zeros(1,N);
y = zeros(1,N);
y(1) = 1;
w1(1) = 0;
w2(1) = 0;

% The main loop simulating the second order loop
%************************************************************************

for i = 2:N,
    w2(i) = w2(i-1) + w1(i-1) - a*y(i-1);
    y(i) = 2*(w2(i)>=0)-1;
    w1(i) = w1(i-1) + in(i-1) - y(i) + noise_rms_1*randn;
end

%************************************************************************

% Display the spectrum
%************************************************************************
% Locaate the bins related to the main tone, as well as the inband bins
fres = fs/N;
maintone = round(fin/fres);
signal_bins = [maintone-7:maintone+7];
inband_bins = [1:round(fb/fres)];
noise_bins = setdiff(inband_bins,signal_bins);

fres = fs/N;

ffty = abs(fft(y'.*(kaiser(length(y),20)))); % compute magnitude spectrum


figure(2);
semilogx((1:N/2)*fres,20*log10(ffty(1:N/2)),...
         signal_bins*fres,20*log10(ffty(signal_bins)),...
         noise_bins*fres,20*log10(ffty(noise_bins)));   
grid on; xlabel('Frequency'); ylabel('Amplitude [dB]');
title('Output spectrum of the 2nd order feed-back sigma delta modulator with noise');

%compute signal and noise power
signal_power = sum(ffty(signal_bins).^2);
noise_power  = sum(ffty(noise_bins).^2);

% calculate SNR in dB
SNR  = 10*log10(signal_power/noise_power)

    