% Simulates a CT 2nd order sigma delta modulator (FB architecture)

clear all; close all;

% Define input sinewave and sampling conditions
fin        = 10.03; % input frequency (kHz) 
fs         = 2000;  % sampling frequency (kHz) 
fres       = 0.05;  % FFT resolution
amplitude  = 0.7;
offset     = 0.00;

N          = ceil(fs/fres)
nr_periods = ceil(fin/fres)
nr_steps   = 20; % number of simulations steps per sample period

% Pre-allocate and initialize array variables => faster code
in = offset + amplitude*sin(2*pi*(fin/fs)*[1:N*nr_steps]/nr_steps);
y  = zeros(1,N); y(1) = 1;
w1 = zeros(1,N*nr_steps); w2 = w1; w12 = w1; 

%========================================
% Prototype Feed back filter coefficients
%========================================
om1 = 2*pi*fs; % Unity gain frequency (rads/s) of the first integrator
om2 = 2*pi*fs; % Unity gain frequency (rads/s) of the second integrator
a1  = 1;
a2  = 4*pi; 

% Adjust coefficients to account for simulation step-size
om1 = om1/(2*pi*fs*nr_steps); 
om2 = om2/(2*pi*fs*nr_steps); 

ix = 1;

for a = 2:N

    for b = 1:nr_steps
        ix = ix+1;
        w2(ix) = w2(ix-1) + om2*(w1(ix-1) - a2*y(a-1));
        w1(ix) = w1(ix-1) + om1*(in(ix-1) - a1*y(a-1));
     end

    y(a) = sign(w2(ix));
end

%************************************************************************
% Display the 'time domain' output values
%************************************************************************
figure(1);
subplot(3,1,1); plot(w1,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('W1 (1st Integrator)'); grid on;
subplot(3,1,2); plot(w2,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('W2 (2nd Integrator)'); grid on;
subplot(3,1,3); plot(y,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('Y (Bitstream)'); grid;
saveas(gcf,'results/MOD2_CT_FB_time.png');

%************************************************************************
% Display the 'frequency domain' output values
%************************************************************************
ffty = abs(fft(y'.*(kaiser(length(y),20))));
ffty = 20*log10(ffty/(amplitude*N/2));        % Scale the spectrum (simply)
  
figure(2);
semilogx((1:N/2)*fres,ffty(1:N/2),'-r','LineWidth',1);
grid on; xlabel('Frequency'); ylabel('Amplitude [dB]');
title('Output spectrum of the 2nd order CT feed-back sigma delta modulator');
saveas(gcf,'results/MOD2_CT_FB_spectrum.png');