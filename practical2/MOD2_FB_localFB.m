% 2nd order sigma-delta with feedback loop filter and local feedback

clear all; close all;

% Input and sampling definitions
fin        = 1.003;  % input frequency (kHz) 
fs         = 5600;   % sampling frequency (kHz) 
amplitude  = 0.5;
offset     = 0.00;
nr_periods = 200;

% system bandwidth
fb = 20;

N = round(nr_periods*fs/fin);

in = offset + amplitude*sin(2*pi*[1:N]/(fs/fin));

% calculation of signal and noise bins

% Locaate the bins related to the main tone, as well as the inband bins
fres = fs/N;
maintone = round(fin/fres);
signal_bins = [maintone-7:maintone+7];
inband_bins = [1:round(fb/fres)];
noise_bins = setdiff(inband_bins,signal_bins);

% Pre-allocation of vectors
y = zeros(1,N); w1 = y; w2 = y;  y(1) = 1;

% Feedback filter coefficients
b1 = 1; b2 = 1;
a1 = 1; a2 = 2;
d=0.00017;

% Main Modulator Loop
for a = 2:N,
    w2(a) = w2(a-1) + b2*(w1(a-1)-a2*y(a-1));
    y(a) = 2*(w2(a)>=0)-1;
    w1(a) = w1(a-1) + b1*(in(a-1)-a1*y(a-1)-d*w2(a-1));
end

%************************************************************************
% Display the 'time domain' output values
%************************************************************************
 
figure(1);
subplot(3,1,1); plot(w1,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('11 (1st Accumulator)');  grid on;
subplot(3,1,2); plot(w2,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('12 (2nd Accumulator)');  grid on;
subplot(3,1,3); plot(y,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('y (Bitstream)');  grid on;
    
%************************************************************************
% Display the 'frequency domain' output values
%************************************************************************
    
fres = fs/N;

ffty = abs(fft(y'.*(kaiser(length(y),20)))); % compute magnitude spectrum


figure(2);
semilogx((1:N/2)*fres,20*log10(ffty(1:N/2)),...
         signal_bins*fres,20*log10(ffty(signal_bins)),...
         noise_bins*fres,20*log10(ffty(noise_bins)));   
grid on; xlabel('Frequency'); ylabel('Amplitude [dB]');
title('Output spectrum of the 2nd order feed-back sigma delta modulator with local feedback');

%compute signal and noise power
signal_power = sum(ffty(signal_bins).^2);
noise_power  = sum(ffty(noise_bins).^2);

% calculate SNR in dB
SNR  = 10*log10(signal_power/noise_power)