% Exercise 3.1 / 3.2 - 3-bit (8-level) 2nd order modulator with a thermometer DAC.
% Same modulator run with 4 different element-selection strategies so we can
% see what DAC mismatch does and how DEM (randomization) and DWA fix it:
%   1) matched elements          -> ideal reference (no mismatch)
%   2) mismatch + plain thermoDAC -> static selection, mismatch -> tones (no DEM)
%   3) mismatch + thermoDACrnd    -> randomization (DEM), tones become white noise
%   4) mismatch + DWA             -> sequential selection, mismatch is 1st order shaped

clear all; close all; clc;

% Define input sinewave
fin        = 1.003;   % input frequency (kHz) (no simple integer relationship with fs)
amplitude  = 0.7;     % input amplitude (Volts)
offset     = 0.0;     % input offset (Volts)
fb         = 20;      % signal bandwidth (kHz)
fres       = 0.02;    % FFT resolution (kHz)
OSR        = 60;
fs         = 2*fb*OSR;        % sampling frequency (kHz)
N          = round(fs/fres);
nr_periods = round(fin/fres); % whole number of periods => input lands in an FFT bin

% Quantizer definitions
nr_levels = 8;    % number of levels
Vref      = 1.0;  % reference voltage
nr_elem   = nr_levels - 1;

% Element mismatch. Same mismatched DAC is reused for cases 2-4 so the
% comparison is fair (one physical DAC, three selection schemes).
mismatch = 0.01;          % 1% std unit-element mismatch
rng(1);                   % fix seed so the run is reproducible
elem_ideal = ones(1,nr_elem);
elem_mis   = 1 + mismatch*randn(1,nr_elem);

%**********************************************************************
% Locate the bins related to the main tone, the inband bins, harmonics
%**********************************************************************
maintone    = nr_periods + 1;                   % pointer to main tone
signal_bins = [maintone-7 : maintone+7];        % Kaiser(20) main lobe width
inband_bins = [1:fb/fres];                       % pointer to inband bins
noise_bins  = setdiff(inband_bins,signal_bins);  % everything inband except the tone

% harmonic bins (HD2..HD5) so we can separate distortion from the noise floor
harm_bins = [];
for k = 2:5
    hb = k*nr_periods + 1;
    harm_bins = [harm_bins, hb-3:hb+3];
end
harm_bins = intersect(harm_bins, inband_bins);
noiseonly_bins = setdiff(noise_bins, harm_bins);  % inband minus tone minus harmonics

% Coefficients (no scaling, 2nd order feedback modulator)
a2 = 2; b1 = 1; b2 = 1;

in = offset + amplitude*sin(2*pi*fin*(1:N)/fs);

cases = {'matched','mismatch + thermoDAC (no DEM)','mismatch + DEM (random)','mismatch + DWA'};
ffty_dB = zeros(N, numel(cases));
SNDR = zeros(1,numel(cases));   % signal vs (noise + distortion)
SNR  = zeros(1,numel(cases));   % signal vs noise only (harmonics removed)

for c = 1:numel(cases)
    % pick the element vector for this run
    if c == 1, elements = elem_ideal; else, elements = elem_mis; end
    rng(7);  % reset randomizer so case 3 is repeatable

    % Pre-allocate and initialize array variables => faster code
    y  = zeros(1,N); y(1) = 1;
    DAC = zeros(1,N);
    w1 = y;  w1(1) = 0;
    w2 = y;  w2(1) = 0.1;
    ptr = 0;                 % DWA pointer (only used in case 4)

    for a = 2:N
        w2(a) = w2(a-1) + b2*(w1(a-1) - a2*y(a-1));
        w1(a) = w1(a-1) + b1*(in(a-1) - DAC(a-1));
        [y(a), index] = mbq(w2(a), nr_levels, Vref);

        switch c
            case {1,2}
                DAC(a) = thermoDAC(index, elements, nr_levels);    % static thermometer
            case 3
                DAC(a) = thermoDACrnd(index, elements, nr_levels); % DEM: random subset
            case 4
                % data weighted averaging, sequential rotation
                % DWA: take 'index' consecutive elements starting at ptr, wrap around.
                % Keeping the pointer between cycles is what shapes the mismatch.
                DACvect = -ones(1,nr_elem);
                if index > 0
                    sel = mod((ptr:ptr+index-1), nr_elem) + 1; % this does the wrap-around selection of 'index' elements starting at 'ptr'
                    DACvect(sel) = 1;
                end
                % DAC(a) = (elements*DACvect')/nr_elem; % linear average of the selected elements
                DAC(a) = (2*sum(elements(sel)) - sum(elements)) / nr_elem; % this form uses the fact that the unselected elements are -1, so we can do 2*sum(selected) - sum(all) which means we only need to sum the selected elements instead of summing all and subtracting the unselected ones.
                DAC(a)
                ptr = mod(ptr + index, nr_elem);
        end
    end

    % FFT of the quantizer output, signal / noise / distortion powers
    ffty = fft(y'.*(kaiser(length(y),20)));
    power = ffty.*conj(ffty);
    signal_power = sum(power(signal_bins));
    nd_power     = sum(power(noise_bins));      % noise + distortion (slide calls this SNR)
    n_power      = sum(power(noiseonly_bins));  % noise floor only

    SNDR(c) = 10*log10(signal_power/nd_power);
    SNR(c)  = 10*log10(signal_power/n_power);

    ffty_magn = abs(ffty)/(amplitude*N/2);
    ffty_dB(:,c) = 20*log10(ffty_magn);

    fprintf('%-32s  SNDR = %5.1f dB   SNR(noise only) = %5.1f dB\n', cases{c}, SNDR(c), SNR(c));
end

%**********************************************************************
% Plots
%**********************************************************************
f = (1:round(N/2))*fres;

% Figure 1: no-DEM vs DEM vs DWA spectra overlaid
figure('Position',[100 100 1000 650]);
semilogx(f, ffty_dB(1:round(N/2),2), 'Color',[0.85 0.3 0.1]); hold on;
semilogx(f, ffty_dB(1:round(N/2),3), 'Color',[0.1 0.5 0.9]);
semilogx(f, ffty_dB(1:round(N/2),4), 'Color',[0.1 0.7 0.2]);
xline(fb,'k--');
hold off; grid on; xlim([0.1 fs/2]); ylim([-180 10]);
xlabel('Frequency [kHz]'); ylabel('Spectrum [dB]');
legend('no DEM (static)','DEM (random)','DWA','signal band edge','Location','northwest');
title(sprintf('3-bit MOD2, %.0f%% mismatch: static vs DEM vs DWA', mismatch*100));
print(gcf, fullfile('results','MOD2_3Bit_DEM_DWA_spectrum.png'), '-dpng','-r110');

% Figure 2: zoom into the signal band to show the harmonic tones
figure('Position',[100 100 1000 650]);
semilogx(f, ffty_dB(1:round(N/2),2), 'Color',[0.85 0.3 0.1],'LineWidth',1.2); hold on;
semilogx(f, ffty_dB(1:round(N/2),3), 'Color',[0.1 0.5 0.9]);
semilogx(f, ffty_dB(1:round(N/2),4), 'Color',[0.1 0.7 0.2]);
for k = 2:4
    semilogx(k*fin*[1 1], [-180 0],'k:');
    text(k*fin, -8, sprintf('HD%d',k));
end
hold off; grid on; xlim([0.3 fb]); ylim([-160 10]);
xlabel('Frequency [kHz]'); ylabel('Spectrum [dB]');
legend('no DEM (static)','DEM (random)','DWA','Location','southeast');
title('In-band zoom: static DAC shows harmonic tones, DEM/DWA do not');
print(gcf, fullfile('results','MOD2_3Bit_DEM_DWA_inband.png'), '-dpng','-r110');

% Figure 3: matched reference vs mismatched static, full picture
figure('Position',[100 100 1000 650]);
semilogx(f, ffty_dB(1:round(N/2),1), 'Color',[0.4 0.4 0.4]); hold on;
semilogx(f, ffty_dB(1:round(N/2),2), 'Color',[0.85 0.3 0.1]);
xline(fb,'k--'); hold off; grid on; xlim([0.1 fs/2]); ylim([-180 10]);
xlabel('Frequency [kHz]'); ylabel('Spectrum [dB]');
legend('matched elements','1% mismatch (static DAC)','signal band edge','Location','northwest');
title('Effect of element mismatch with a static thermometer DAC');
print(gcf, fullfile('results','MOD2_3Bit_matched_vs_mismatch.png'), '-dpng','-r110');
