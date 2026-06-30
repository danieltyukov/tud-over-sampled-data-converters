function c = firdsm_coeffs(OSR, OBG, alpha)
% 4th-order cifb coefficients (hand-rolled, no delsig): two in-band resonator
% zeros, butterworth-hp poles bisected to the obg, dac gains from the char poly.

if nargin < 1, OSR = 50;  end
if nargin < 2, OBG = 1.5; end
if nargin < 3, alpha = [0.46 0.89]; end

fbn = 1/(2*OSR);
thz = 2*pi*alpha*fbn;            % zero angles
g1 = 2*(1-cos(thz(1)));          % resonators -> two optimised zeros
g2 = 2*(1-cos(thz(2)));
numz = [1, -4, g1+g2+6, -2*g1-2*g2-4, g1+g2+g1*g2+1];   % ntf numerator

% denominator: butterworth high-pass, bisect cutoff to hit the obg
w = linspace(0,pi,8000); ejw = exp(1j*w);
obg = @(D) max(abs(polyval(numz,ejw))./abs(polyval(D,ejw)));
lo = 0.02; hi = 0.45;
for it = 1:60
    Wc = (lo+hi)/2;
    [~,D] = butter(4, Wc, 'high'); D = D/D(1);
    if obg(D) > OBG, hi = Wc; else lo = Wc; end
end
[~,Dt] = butter(4, Wc, 'high'); Dt = Dt/Dt(1);

% char poly of the loop is affine in a, so solve a 4x4 system to match Dt
Amat = @(a) [1,-g1,0,-a(1); 1,1-g1,0,-(a(1)+a(2)); ...
             1,1-g1,1,-(g2+a(1)+a(2)+a(3)); 1,1-g1,1,1-g2-sum(a)];
cp = @(a) charpoly(Amat(a));
c0 = cp([0 0 0 0]);
Jm = zeros(4,4);
for j = 1:4
    e = zeros(1,4); e(j) = 1; cj = cp(e);
    Jm(:,j) = (cj(2:5)-c0(2:5)).';
end
a = (Jm \ (Dt(2:5)-c0(2:5)).').';

c.a = a; c.g1 = g1; c.g2 = g2; c.b1 = a(1);
c.numz = numz; c.Dt = Dt; c.Wc = Wc; c.OSR = OSR; c.OBG = OBG;
c.alpha = alpha; c.zero_angles = thz;
end
