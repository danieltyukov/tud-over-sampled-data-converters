clear y w time_ma b Pffty scPfy
close all;

%%% [MOD] === Exercise 1.6: spectrum of MOD1 output for various DC inputs ====
%%% [MOD] We sweep the requested offset values and plot each output spectrum.
%%% [MOD] Idle tones appear at frequencies related to the bitstream pattern;
%%% [MOD] for x=0 -> single tone at fs/2 (limit cycle ±1,-1,+1,...).

%Input signal definition
sig_freq    = 100;
fs          = 1000;
nr_periods  = 1000;
nr_points   = (nr_periods*fs/sig_freq);

%%% [MOD] List of DC offsets requested by the PDF (slide 30)
offset_list = [0, 0.25, 0.5, 0.05, 0.0346];

figure('Name','MOD1 output spectra','Position',[100 100 1200 900]);
for k = 1:length(offset_list)
    offset = offset_list(k);
    in     = offset*(ones(1,nr_points));

    % Pre-allocates and initializes array variables
    w = zeros(1,nr_points);
    y = zeros(1,nr_points);
    w(1) = 0.5;
    y(1) = 1;

    % The main loop simulating the accumulator and the quantizer
    %************************************************************************
    for a = 2:nr_points
        w(a) = w(a-1) + in(a-1) - y(a-1);
        y(a) = sign(w(a));
    end
    %************************************************************************

    % Calculating and plotting the modulator output in frequency domain
    %************************************************************************
    Pffty       = (abs(fft(2*(y.*(kaiser(length(y),20))')))+1E-3);
    scPfy       = Pffty/max(Pffty)/sqrt(2);
    size_ffty   = ceil(length(scPfy)/2);
    ffty_ax     = fs*([1:size_ffty]-1)/size_ffty/2;

    subplot(3,2,k);
    plot(ffty_ax, 20*log10(scPfy(1:size_ffty)),'k','LineWidth',1);
    xlabel('Frequency [Hz]'); ylabel('Spectrum [dB]'); grid;
    title(sprintf('DC offset = %.4f V (y_{avg} = %.4f)', ...
                  offset, sum(y)/length(y)));
    axis([0 fs/2 -120 5]);
end
saveas(gcf,'results/MOD1_fft_sweep.png');

%%% [MOD] Print bitstream averages for record
fprintf('\n  offset      y_avg          |y_avg - x|\n');
fprintf(' --------   -----------    ------------\n');
for k = 1:length(offset_list)
    offset = offset_list(k);
    in = offset*ones(1,nr_points);
    w = zeros(1,nr_points); y = zeros(1,nr_points); w(1)=0.5; y(1)=1;
    for a = 2:nr_points
        w(a) = w(a-1) + in(a-1) - y(a-1);
        y(a) = sign(w(a));
    end
    yavg = sum(y)/length(y);
    fprintf(' %+7.4f   %+10.6f    %10.2e\n', offset, yavg, abs(yavg-offset));
end
