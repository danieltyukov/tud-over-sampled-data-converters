clear all
close all;

%Input signal definition
% This is the DC offset applied to the input of the modulator
offset = 0;

nr_points = 1000;

in = offset*(ones(1,nr_points));

% Pre-allocate and initialize array variables => faster code
% w2 is the second accumulator's output
% w1 is the first accumulator's output
% a is the stabilizing zero coefficient

a = 1;

w1 = zeros(1,nr_points);
w2 = zeros(1,nr_points);
y = zeros(1,nr_points);
y(1) = 1;
w1(1) = 0;
w2(1) = 0;

% The main loop simulating the second order loop
%************************************************************************

for i = 2:nr_points,
    w2(i) = w2(i-1) + w1(i-1) - a*y(i-1);
    y(i) = sign(w2(i));
    %y(i) = 2*(w2(i)>=0)-1;
    w1(i) = w1(i-1) + in(i-1) - y(i);
end

%************************************************************************

% Display the output values
%************************************************************************

figure(2);
subplot(3,1,1);plot(w1,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('w1 (1st Accumulator)');grid;
subplot(3,1,2);plot(w2,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('w2 (2nd Accumulator)');grid;
subplot(3,1,3);plot(y,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('y (Bitstream)');grid;
    