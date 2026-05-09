% 2nd order sigma-delta with feed-forward loop filter

% Input and sampling definitions
fin        = 1.003;  % input frequency (kHz) 
fs         = 1000;   % sampling frequency (kHz) 
amplitude  = 0.7;
offset     = 0.00;
nr_periods = 200;

N = round(nr_periods*fs/fin);

in = offset + amplitude*sin(2*pi*[1:N]/(fs/fin));

% Pre-allocation of vectors
y = zeros(1,N); w1 = y; w2 = y; w12 = y; y(1) = 1;

% Feed Forward filter coefficients
b1 = 1; b2 = 1;
c1 = 2; c2 = 1;

% Main modulator Loop
for a = 2:N    
    w2(a)  = w2(a-1) + b2*w1(a-1);
    w1(a)  = w1(a-1)  + b1*(in(a-1) - y(a-1));
    w12(a) = c1*w1(a) + c2*w2(a);
    y(a)   = 2*(w12(a)>=0)-1;
end

%************************************************************************
% Display the 'time domain' output values
%************************************************************************

figure(1);
subplot(3,1,1); plot(w1,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('w1 (1st Accumulator)');  grid on;
subplot(3,1,2); plot(w2,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('w2 (2nd Accumulator)');  grid on;
subplot(3,1,3); plot(y,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('y (Bitstream)');  grid on;

%************************************************************************
% Display the 'frequency domain' output values
%************************************************************************

fres = fs/N;

ffty = abs(fft(y'.*(kaiser(length(y),20)))); % compute magnitude spectrum
    
ffty = 20*log10(ffty/max(ffty)/sqrt(2)); % Scale the spectrum
   
figure(2);
semilogx((1:N/2)*fres,ffty(1:N/2),'-r','LineWidth',1);   
grid on; xlabel('Frequency'); ylabel('Amplitude [dB]');
title('Output spectrum of the 2nd order feed forward sigma delta modulator');