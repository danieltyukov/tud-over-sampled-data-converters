function p = firdsm_params()
% default parameter block for the fir-dac modulator (shettigar & pavan 2012).
% every knob lives here so any value can be changed live during the oral and
% the effect shown. non-ideality knobs default to off (= ideal modulator).

%% design point (paper)
p.fs    = 3.6e9;                 % sampling rate
p.fb    = 36e6;                  % signal bandwidth (also run 25e6)
p.OSR   = p.fs/(2*p.fb);         % ~50
p.order = 4;                     % ntf order
p.OBG   = 1.5;                   % out-of-band gain (lee's rule, 1-bit)
p.Ntap  = 8;                     % fir dac taps
p.firtaps = [0.07 0.12 0.15 0.16 0.16 0.15 0.12 0.07];   % eq.(1), sum = 1

%% coefficients (derived, see firdsm_coeffs)
c = firdsm_coeffs(p.OSR, p.OBG, [0.46 0.89]);
p.a = c.a; p.g1 = c.g1; p.g2 = c.g2; p.b1 = c.b1;
p.numz = c.numz; p.Dt = c.Dt; p.coeff = c;
p.kff = 1.2;                     % input feed-forward into last integrator (stf peaking)

%% simulation grid
p.ns    = 20;                    % ct sub-steps per clock
p.Nfft  = 2^16;                  % clock samples for spectra
p.amp   = 0.5;                   % default input amplitude (full scale = 1)
p.fin   = [];                    % set coherent in firdsm_run if empty (~10 mhz)
p.seed  = 1;                     % rng seed

%% technique switches (default = full proposed design)
p.fir_on   = 1;                  % 8-tap fir feedback dac
p.comp_on  = 1;                  % analog fir-delay compensation path
p.first_tap_zero = 0;            % set f1=0 (explicit 1-clock delay, metastability)

%% non-ideality knobs (default off / ideal)
p.jitter_rms  = 0;               % white clock jitter, rms as fraction of Ts
p.jitter_fmod = 0;               % sinusoidal-fm jitter frequency (Hz), 0 = white
p.A_dc = inf;                    % opamp dc gain (linear, not dB)
p.ugb  = inf;                    % opamp unity-gain bandwidth (Hz)
p.eld  = 0;                      % excess loop delay, fraction of Ts
p.kdac0 = 0;                     % rz dac0 prompt feedback for eld compensation
p.tapmismatch = 0;               % fir unit-element sigma (fraction)
p.g3 = 0;                        % input integrator weak-cubic coeff (i=Gm*v-G3*v^3)
p.Gm = 1;                        % input integrator transconductance (normalised)
p.noise_rms = 0;                 % input-referred thermal noise rms
p.meta_on = 0;                   % comparator metastability on first tap
p.meta_tau = 0.02;              % regen time constant as fraction of Ts
p.isi_on = 0;                    % dac rise/fall asymmetry (isi)
p.isi_alpha = 0;                 % isi 2nd-order coeff (hd2 strength)
p.isi_corr = 0;                  % digital isi correction on/off
p.isi_alpha_c = 0;               % calibrated correction coeff (~isi_alpha)
p.nlev = 2;                      % quantizer levels (2 = 1-bit; >2 for 4-bit ref)
end
