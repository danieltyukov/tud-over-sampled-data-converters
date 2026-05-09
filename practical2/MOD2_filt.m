clear all
close all;
clc;

%Input signal definition
%Offset input

% This is the DC offset applied to the input of the modulator
offset = 50e-3;

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
    y(i) = 2*(w2(i)>=0)-1;
    w1(i) = w1(i-1) + in(i-1) - y(i);
end

%************************************************************************
% Display the integrator values
%************************************************************************

figure(2);
subplot(2,1,1);plot(w1,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('w1 (1st Accumulator)');grid;
subplot(2,1,2);plot(w2,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('w2 (2nd Accumulator)');grid;
    
% Defining a Kaiser FIR filter at the output of the second order modulator
%************************************************************************
% The length of the filter
window_size = nr_points;
kai_filt = window(@kaiser,window_size,20);

% Triangular filter
%tr_filt = window(@triang,window_size);

% Applying the filter to the modulator output
%************************************************************************
y_kai_filt = y'.*kai_filt;

% Plot the time-domain bitstream, and the filtered bitstream
%************************************************************************
figure(3);
subplot(2,1,1);plot(y,'k','LineWidth',1.5);
xlabel('Samples'); ylabel('y');grid;
subplot(2,1,2);plot(y_kai_filt,'k');ylabel('y-kai');
xlabel('Samples'); ylabel('filtered y');grid;

% Printing the decimated values in Matlab command prompt
%************************************************************************

disp('Non filtered output:');
y_avg = sum(y)/length(y)
Q_non_filtered = abs(offset-y_avg)

disp('Filtered output:');
y_avg_kai = sum(y_kai_filt)/sum(kai_filt)
Q_filtered = abs(offset-y_avg_kai)
