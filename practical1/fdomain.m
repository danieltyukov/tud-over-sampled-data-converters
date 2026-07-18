% sampling and aliasing

clc
close all;
clear all;

%%% [MOD] === Exercise 1.5: FFT exploration ================================
%%% [MOD] We compare:
%%% [MOD]   (a) in-bin frequency  (fin = k*fs/N)  -> single clean spike
%%% [MOD]   (b) out-of-bin freq  (fin = (1/pi)*1e6) -> spectral leakage
%%% [MOD]   (c) different sample counts N         -> resolution Fs/N
%%% [MOD]   (d) Hann window vs no window          -> reduced leakage
%%% [MOD]   (e) varied amplitude                  -> peak ~ A*N/2 for in-bin

% Sampling parameters
%**************************
fs            = 1e6;                 % sampling frequency
nr_samples_v  = [128, 256, 1024];    %%% [MOD] sample-count sweep
ain_v         = [1, 0.25];           %%% [MOD] amplitude sweep
fin_inbin     = (81/256)*1e6;        % in-bin frequency
fin_oob       = (1/pi)*1e6;          % out-of-bin (irrational)

cases = struct( ...
    'name', {'inbin_N256_A1', 'oob_N256_A1', 'oob_N256_A1_HANN', ...
             'inbin_N1024_A1', 'oob_N1024_A1_HANN', 'inbin_N256_A025'}, ...
    'N',    {256, 256, 256, 1024, 1024, 256}, ...
    'fin',  {fin_inbin, fin_oob, fin_oob, fin_inbin, fin_oob, fin_inbin}, ...
    'A',    {1, 1, 1, 1, 1, 0.25}, ...
    'win',  {'none','none','hann','none','hann','none'} );

figure('Name','fdomain sweep','Position',[100 100 1200 900]);
for k = 1:length(cases)
    c = cases(k);
    N   = c.N;  fin = c.fin;  ain = c.A;  wname = c.win;

    t = 0:(1/fs):(N-1)/fs;
    x = ain * sin(2*pi*fin*t);

    %%% [MOD] Optional Hann window
    if strcmp(wname,'hann')
        x_w = x' .* window(@hann, N);
    else
        x_w = x';
    end

    fftx = abs(fft(x_w));
    fres = fs/N;

    half = 1:N/2;
    subplot(3,2,k);
    plot(half*fres, 20*log10(fftx(half)+1e-12),'k');
    grid on;
    xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
    title(sprintf('%s | N=%d  f_{in}=%.3g Hz  A=%.2g  win=%s', ...
                  c.name, N, fin, ain, wname));
    axis([0 fs/2 -80 inf]);
end
saveas(gcf,'results/fdomain_sweep.png');

%%% [MOD] Print peak amplitude for in-bin/no-window case to verify A*N/2 rule
N = 256; ain = 1; fin = fin_inbin;
t = 0:(1/fs):(N-1)/fs;
x = ain*sin(2*pi*fin*t);
fftx = abs(fft(x));
fprintf('\n[FFT-amplitude check] in-bin sinusoid, N=%d, A=%g\n', N, ain);
fprintf('  expected  peak = A*N/2 = %.3f\n', ain*N/2);
fprintf('  measured  peak = %.3f\n', max(fftx));

ain = 0.25;
x = ain*sin(2*pi*fin*t);
fftx = abs(fft(x));
fprintf('  amplitude=%.2f -> measured peak = %.3f (expected %.3f)\n', ...
        ain, max(fftx), ain*N/2);

%%% [MOD] Out-of-bin: peak is no longer A*N/2 because energy spreads (leakage)
fin = fin_oob;
ain = 1;
x = ain*sin(2*pi*fin*t);
fftx = abs(fft(x));
fprintf('  out-of-bin (no window):  peak = %.3f  (expected %.3f if it were in-bin)\n',...
        max(fftx), ain*N/2);
x_w = x'.*window(@hann,N);
fftx_w = abs(fft(x_w));
fprintf('  out-of-bin (Hann window): peak = %.3f\n', max(fftx_w));
