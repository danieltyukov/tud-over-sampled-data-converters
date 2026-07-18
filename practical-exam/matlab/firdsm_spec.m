function s = firdsm_spec(y, p, fin)
% spectrum + snr/sndr/hd2/hd3 from the bitstream y. kaiser(N,20) window, coherent
% tone fin, true dbfs (full scale = 0 dB), bin-sum snr (no calculateSNR).

N    = length(y);
fs   = p.fs; fb = p.fb;
fres = fs/N;
win  = kaiser(N,20);
ffty = fft(y(:).*win);
mag  = abs(ffty)/(sum(win)/2);       % full-scale (amp=1) sine reads 0 dbfs (window gain)
s.fdB  = 20*log10(mag(1:round(N/2)) + eps);
s.faxis = (1:round(N/2))*fres;
s.fres = fres;

maintone   = round(fin/fres);        % tone bin (0-based bin number)
s.maintone = maintone;
sigc        = maintone + 1;          % 1-based fft index of the tone
signal_bins = sigc + (-7:7);         % ~15 bins = kaiser(20) main lobe
inband_bins = 2:round(fb/fres);      % skip dc bin
% harmonics (fold above fs/2 if needed)
hb = @(k) foldbin(k*maintone, N) + 1;
harm_bins = [];
for k = 2:5, harm_bins = [harm_bins, hb(k)+(-3:3)]; end
harm_bins = harm_bins(harm_bins>=2 & harm_bins<=round(N/2));

P = abs(ffty).^2;
sig = sum(P(signal_bins));
% sndr: everything in band except the signal main lobe counts as noise+distortion
noise_sndr = setdiff(inband_bins, signal_bins);
% snr: also remove the harmonic bins (floor only)
noise_snr  = setdiff(noise_sndr, harm_bins);

s.SNDR = 10*log10(sig/sum(P(noise_sndr)));
s.SNR  = 10*log10(sig/sum(P(noise_snr)));
% hd2/hd3 in dbc relative to the tone
s.HD2 = 10*log10(sum(P(hb(2)+(-3:3)))/sig);
s.HD3 = 10*log10(sum(P(hb(3)+(-3:3)))/sig);
s.signal_bins = signal_bins; s.inband_bins = inband_bins;
end

function b = foldbin(k, N)
% fold a harmonic bin number into [0, N/2]
b = mod(k, N);
if b > N/2, b = N - b; end
end
