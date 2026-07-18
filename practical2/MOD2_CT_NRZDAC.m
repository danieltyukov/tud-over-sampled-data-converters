% Continuous Time second order sigma delta modulator

clear all
close all;


nr_steps=20;

% Defining DAC feedback signals with asymmetric rise and fall times
DAC_wave(1,(1:nr_steps)) = ones(1,nr_steps);
DAC_wave(2,(1:nr_steps)) = ones(1,nr_steps); DAC_wave(2,(1:4))=-1 + 0.5*(0:3);
DAC_wave(3,(1:nr_steps)) = -1*ones(1,nr_steps);DAC_wave(3,(1:2))= 1 - (1:2);
DAC_wave(4,(1:nr_steps)) = -1*ones(1,nr_steps);

% Defining DAC feedback signals with symmetrical rise and fall times
% (remove the comments to make the DAC ideal)
%DAC_wave(1,(1:nr_steps)) = ones(1,nr_steps);
%DAC_wave(2,(1:nr_steps)) = ones(1,nr_steps);
%DAC_wave(3,(1:nr_steps)) = -1*ones(1,nr_steps);
%DAC_wave(4,(1:nr_steps)) = -1*ones(1,nr_steps);


%Sinusoidal input
sig_freq=10.003;
nyq_freq=2000;
nr_periods=200;
amplitude=0.7;
offset=0;

nr_points=ceil(nr_periods*nyq_freq/sig_freq);

in = offset + amplitude*sin(2*pi*[1:nr_points*nr_steps]/(nyq_freq/sig_freq)/nr_steps);



y=zeros(1,nr_points);
w=zeros(1,nr_points*nr_steps);
w2=zeros(1,nr_points*nr_steps);
w12=zeros(1,nr_points*nr_steps);
DAC_Test=zeros(1,nr_points*nr_steps);
y(1)=1;
DAC = DAC_wave(1,:);



fs = nyq_freq;

% Feed back filter coefficients
%==================================

% Unity gain frequency of the first integrator (ft1 = 1KHz)
ft1 = 1e3;
% Unity gain frequency of the second integrator (ft2 = 1KHz)
ft2 = 1e3;

% Calculating omega1 of the first continuous time integrator
omega1 = 2*pi*ft1/fs/nr_steps;
% Calculating omega2 of the second continuous time integrator
omega2 = 2*pi*ft2/fs/nr_steps;


%Feed Forward filter coefficients
a1=1;
c1=2*omega1*nr_steps;
c2=1;



index=1;

for a = 2:nr_points,

    for b = 1:nr_steps

        index=index+1;
        %2nd order filter
        w2(index) = w2(index-1) + omega2*w(index-1);
%        w(index) = w(index-1) + omega1*(in(index-1) - a1*y(a-1));
        w(index) = w(index-1) + omega1*(in(index-1) - a1*DAC(b));
        w12(index) = c1*w(index) + c2*w2(index);
       
        % for test
        DAC_Test(index) = DAC(b);
        
    end

    y(a) = sign(w12(index));
    if (y(a)==1) && (y(a-1)==1)
        DAC = DAC_wave(1,:);
    elseif (y(a)==1 && (y(a-1))==-1)
        DAC = DAC_wave(2,:);
    elseif (y(a)==-1 && y(a-1)==1)
        DAC = DAC_wave(3,:);
    elseif (y(a)==-1 && y(a-1)==-1)
        DAC = DAC_wave(4,:);
    end;

end

%************************************************************************
% Display the 'time domain' output values
%************************************************************************

    figure(1);
    subplot(3,1,1);plot(w,'k','LineWidth',1.5);
    xlabel('Samples'); ylabel('W1 (1st Integrator)');grid;
    subplot(3,1,2);plot(w2,'k','LineWidth',1.5);
    xlabel('Samples'); ylabel('W2 (2nd Integrator)');grid;
    subplot(3,1,3);plot(y,'k','LineWidth',1.5);
    xlabel('Samples'); ylabel('Y (Bitstream)');grid;
    saveas(gcf,'results/MOD2_CT_NRZDAC_time.png');


    
%************************************************************************
% Display the 'frequency domain' output values
%************************************************************************
    
    N = nr_points;
    fs = nyq_freq;
    fres = fs/N;
    fin = sig_freq;


    ffty = abs(fft(y'.*(kaiser(length(y),20))));
    % Scale the spectrum
    ffty = 20*log10(ffty/max(ffty)/sqrt(2));
    % Plot the output spectrum
    figure(2);semilogx((1:round(N/2))*fres,ffty(1:round(N/2)),'-r','LineWidth',1);

    xlabel('Frequency');ylabel('Amplitude [dB]');title('Output spectrum of the continuous time 2nd order feed forward sigma delta modulator');
    grid on;
    saveas(gcf,'results/MOD2_CT_NRZDAC_spectrum.png');

    figure(3);plot(DAC_Test(1:1000));hold on;plot(DAC_Test(1:1000),'r*');
    title('A few samples of the feedback DAC signal with asymmetric rise and fall times');
    saveas(gcf,'results/MOD2_CT_NRZDAC_waveform.png');

%%% [MOD] === Exercise 2.8 follow-up: compute in-band SNR for the FF CT MOD ==
%%% [MOD] Quick SNR over a baseband fb that covers our 10 kHz input safely.
fb_band = 100;                                  % kHz, baseband used for SNR
maintone    = round(sig_freq/fres);
signal_bins = maintone-7:maintone+7;
inband_bins = 1:round(fb_band/fres);
noise_bins  = setdiff(inband_bins, signal_bins);

ffy_lin = abs(fft(y' .* kaiser(length(y),20)));
sp = sum(ffy_lin(signal_bins).^2);
np = sum(ffy_lin(noise_bins).^2);
SNR_asym = 10*log10(sp/np);
fprintf('\n[CT MOD2 with asymmetric DAC]  SNR over %g kHz = %.2f dB\n', ...
        fb_band, SNR_asym);
fprintf('Note: re-run with the IDEAL DAC_wave block uncommented for the\n');
fprintf('ideal-DAC reference value; the difference is the resolution loss\n');
fprintf('caused by DAC ISI (intersymbol interference).\n');