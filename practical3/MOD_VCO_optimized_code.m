% Simulates a VCO-based sigma delta modulator

clear all; %close all;

% Define input sinewave and sampling conditions
fin        = 10.003; % input frequency (kHz) 
fs         = 2000;  % sampling frequency (kHz) 
fres       = 0.5;  % FFT resolution
amplitude  = 0.7;
offset     = 0.00;

N          = ceil(fs/fres)
nr_periods = ceil(fin/fres)
nr_steps   = 2000; % number of simulations steps per sample period
%nr_steps   = 200000;

% Pre-allocate and initialize array variables => faster code
%in = offset + amplitude*sin(2*pi*(fin/fs)*[1:N*nr_steps]/nr_steps);
y  = zeros(1,N); y(1) = 0;
counter=zeros(size(y));
%phi = zeros(size(in));
%vco_out=phi;

ix = 2;
f0=fs*100;
kvco=1e5;
counter_ref=f0/fs;
noise_rms=0;
nr_levels=8;
counter_scaling=50;

phi(nr_steps)=0;

for a = 2:N,
    %time_interval=ix:ix+nr_steps-1;
    time_interval=1:nr_steps;
    in = offset + amplitude*sin(2*pi*(fin/fs)*(time_interval+(a-1)*nr_steps)/nr_steps);
    ctrl_vco=in-y(a-1)+randn(1,nr_steps)*noise_rms;
    phi=phi(nr_steps)+cumsum(2*pi*(f0+kvco*ctrl_vco))/nr_steps/fs;
    vco_out=2*(sin(phi)>0)-1;
    counter(a)=counter(a-1)+sum(diff(vco_out)==2)-counter_ref;
    y(a)=max([min([2/(nr_levels-1)*(round((nr_levels-1)/2*counter(a)/counter_scaling-0.5)+0.5) 1]) -1]);
    ix=ix+nr_steps;
    if ~mod(a,100), display(['Cycle ' num2str(a) '/' num2str(N)]);end;
end

%************************************************************************
% Display the 'frequency domain' output values
%************************************************************************
ffty = abs(fft(y'.*(kaiser(length(y),20))));
ffty = 20*log10(ffty/(amplitude*N/2));        % Scale the spectrum (simply)
  
figure;
semilogx((1:N/2)*fres,ffty(1:N/2),'-r','LineWidth',1);   
grid on; xlabel('Frequency'); ylabel('Amplitude [dB]');
title('Output spectrum of VCO based sigma delta modulator');