function [y, st] = firdsm_run(p)
% 4th-order 1-bit ct sdm with 8-tap fir feedback dac, sub-stepped integrators.
% output filtered by F(z) for the smooth feedback, (1-F(z)) added prompt = comp.
% all non-idealities are knobs in p (see firdsm_params). returns y + states st.

rng(p.seed);
fs = p.fs; ns = p.ns; N = p.Nfft; om = 1/ns;
a2=p.a(2); a3=p.a(3); a4=p.a(4); g1=p.g1; g2=p.g2; b1=p.b1;   % b1 = a(1) (input fb)

% coherent tone (lands in one bin)
fres = fs/N;
if isempty(p.fin), fin = round(10e6/fres)*fres; else, fin = round(p.fin/fres)*fres; end
st.fin = fin;

% fir taps with first-tap-zero and unit-element mismatch
ft = p.firtaps;
if p.first_tap_zero, ft(1) = 0; end
if p.tapmismatch > 0, ft = ft.*(1 + p.tapmismatch*randn(size(ft))); end
Ntap = length(ft);

% sub-step input
tt = (0:N*ns-1);
uc = p.amp*sin(2*pi*fin/fs*tt/ns);

% finite gain (leaky integrator) and bw (1-pole on the integrator input)
if isfinite(p.A_dc), pl = 1 - om/p.A_dc; else, pl = 1; end
if isfinite(p.ugb), pbw = exp(-2*pi*p.ugb/(fs*ns)); else, pbw = 0; end
nd = round(p.eld*ns);                 % eld: dac held delayed by nd sub-steps

% jitter edge errors (relative to Ts): white or sinusoidal-fm
if p.jitter_rms > 0
    if p.jitter_fmod > 0
        beta = p.jitter_rms*sqrt(2)*sin(2*pi*p.jitter_fmod/fs*(0:N-1));
    else
        beta = p.jitter_rms*randn(1,N);
    end
else
    beta = zeros(1,N);
end

x1=0; x2=0; x3=0; x4=0;
f1=0; f2=0; f3=0; f4=0;                % 1-pole bw filter states
y = zeros(1,N); fbwave = zeros(1,N);
yh = zeros(1,max(Ntap,2)); firprev = 0; firprev2 = 0; cfprev = 0;
ix = 0; mx = zeros(1,4);

for k = 1:N
    % quantizer on last integrator
    if p.nlev == 2, yk = 2*(x4>=0)-1; else, yk = mbq(x4, p.nlev, 1); end
    y(k) = yk;
    yh = [yk, yh(1:end-1)];

    % fir dac feedback waveform and prompt compensation deficit
    if p.fir_on, fir = ft*yh(1:Ntap).'; else, fir = yk; end
    fbwave(k) = fir;
    if p.comp_on && p.fir_on, cf = yk - fir; else, cf = 0; end

    dfir = fir - firprev;
    ejit = dfir*beta(k);              % jitter error (small fir steps -> small)
    firprev = fir;
    % isi: rise/fall asymmetry -> hd2 ~ signal^2; digital coeff cancels it
    uclk = uc(min(ix+1, numel(uc)));
    eisi = 0;
    if p.isi_on
        eac = uclk^2 - p.amp^2/2;     % ac (2nd-harmonic) part, dc removed
        eisi = p.isi_alpha*eac;       % even distortion -> hd2 ~ signal^2
        if p.isi_corr, eisi = eisi - p.isi_alpha_c*eac; end  % digital correction
    end
    emeta = 0;
    if p.meta_on && ~p.first_tap_zero
        td = max(p.meta_tau*log(1/max(abs(x4),1e-9)), 0);   % time-to-resolve
        emeta = ft(1)*(yk - yh(2))*td;                      % first-tap edge error
    end

    % sub-step ct integration; int1 sees the fir error (u-fir), cf added linearly
    for b = 1:ns
        ix = ix + 1; uin = uc(ix);
        if b <= nd, firv = firprev2; cfv = cfprev; else, firv = fir; cfv = cf; end
        dv = firv + cfv;                                % full feedback for inner dacs
        ev = uin - firv;                                % transconductor input (fir error)
        if p.g3 ~= 0, ev = p.Gm*ev - p.g3*ev^3; end     % weak cubic nonlinearity (pavan)
        in1 = b1*(ev - cfv) - g1*x2;
        f1 = pbw*f1 + (1-pbw)*in1;  x1 = pl*x1 + om*f1;
        in2 = x1 - a2*dv;
        f2 = pbw*f2 + (1-pbw)*in2;  x2 = pl*x2 + om*f2;
        in3 = x2 - a3*dv - g2*x4;
        f3 = pbw*f3 + (1-pbw)*in3;  x3 = pl*x3 + om*f3;
        d4 = p.kdac0*(fir+cf) + (1-p.kdac0)*dv;         % rz dac0: prompt fast feedback
        in4 = x3 - a4*d4 + p.kff*uin;                   % input feed-forward (stf peaking)
        f4 = pbw*f4 + (1-pbw)*in4;  x4 = pl*x4 + om*f4;
    end
    % lumped per-clock terms at int1: thermal noise + jitter/isi/meta dac errors
    x1 = x1 + b1*(p.noise_rms*randn - ejit - eisi - emeta);
    firprev2 = fir; cfprev = cf;
    mx = max(mx, abs([x1 x2 x3 x4]));
    if mx(1) > 1e3, break; end        % bail out if the loop has gone unstable
end

st.fbwave = fbwave; st.mx = mx; st.unstable = any(mx > 1e3);
st.x4_last = x4; st.ft = ft;
end
