close all; clear;


% Input and sampling definitions
% input frequency
fin= 1.003e3; %[Hz]
%system bandwidth
fb=20e3; %[Hz]
%low limit of noise bandwidth
fbl=20; %[Hz]
%OSR
OSR=200;250;
%sampling freq
fs=2*fb*OSR; %[Hz] 
offset     = 0.00;
nr_periods = 50;

nr_points = round(nr_periods*fs/fin);

% Pre-allocation of vectors
y = zeros(1,nr_points);
w1 = y;
w2 = y;
y1 = y;
y2=y;

alpha=1;

%input noise
noise_rms_1=0*0.9/sqrt(2)/10^(90/20)*sqrt(OSR);

% Main modulator Loop
amplitude_vec=0.9;
%amplitude_vec=logspace(-1,0,50);

for i=1:length(amplitude_vec),
    fin=1.003e3;
    display(['Run ' num2str(i) '/' num2str(length(amplitude_vec))]);
    in = offset + amplitude_vec(i)*sin(2*pi*[1:nr_points]/(fs/fin));
    for a = 2:nr_points,
        w1(a) = alpha*w1(a-1) + in(a-1) - y1(a-1)+randn*noise_rms_1;
        y1(a) = 2*(w1(a)>=0)-1;

        y(a)  = y1(a);

    end
    
    % Locate the bins related to the main tone, as well as the inband bins
    fres = fs/nr_points;
    maintone = round(fin/fres);
    signal_bins = [maintone-7:maintone+8];
    inband_bins = [max([1 round(fbl/fres)]):round(fb/fres)];
    noise_bins = setdiff(inband_bins,signal_bins);

    Y=abs(fft(y.*kaiser(length(y),20)')).^2;
    signal_power = sum(Y(signal_bins)); % sum signal power
    noise_power  = sum(Y(noise_bins));  % sum noise power
    SNR(i)=10*log10(signal_power/noise_power); % calculate SNR in dB
end;

YdB=20*log10(Y);
Y1dB=20*log10(abs(fft(y1.*kaiser(length(y),20)')).^2);
Y2dB=20*log10(abs(fft(y2.*kaiser(length(y),20)')).^2);
f=(1:nr_points)*fres;

%%
figure
set(gcf, 'Position', [100 100 900 600])
semilogx(f,YdB,f(inband_bins),YdB(inband_bins),f(signal_bins),YdB(signal_bins),'Linewidth',3);
xlim([100 5e6])
set(gca,'FontSize', 20)
ylabel('Spectrum [dB]','Fontsize',16);
xlabel('Frequency [Hz]','Fontsize',16)
legend('Full spectrum','Inband Bins','Main tone', 4);
grid

%%
figure
set(gcf, 'Position', [100 100 900 600])
semilogx(f,Y2dB,f,Y1dB,f,YdB,'Linewidth',3);
xlim([100 5e6])
set(gca,'FontSize', 20)
ylabel('Spectrum [dB]','Fontsize',16);
xlabel('Frequency [Hz]','Fontsize',16)
legend('Y2','Y1','Y', 4);
grid

%%
figure
set(gcf, 'Position', [100 100 1200 800])
semilogx(amplitude_vec,SNR,'Linewidth',3);
ylim([70 95])
set(gca,'FontSize', 20)
ylabel('SNR [dB]','Fontsize',25);
xlabel('Signal amplitude[V]','Fontsize',25)
grid

