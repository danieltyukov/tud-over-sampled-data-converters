clear
close all;
clc;
format long;

%%% [MOD] === Exercise 1.3: accumulator vs quantizer offset ================
%%% [MOD] We sweep three (a_off, q_off) cases and report the decimated value
%%% [MOD] (mean of bitstream).  Linear-model prediction:
%%% [MOD]   - a_off acts on the signal path  -> appears at the output
%%% [MOD]   - q_off sees NTF=(1-z^-1) which is ZERO at DC -> suppressed

% Input signal definition
nr_points = 8192;            %%% [MOD] longer for accurate decimated value
offset    = 50e-3;
in        = offset*(ones(1,nr_points));

%%% [MOD] List of (a_off, q_off) cases to compare
cases = [0.0  0.0;
         0.5  0.0;
         0.0  0.5;
         0.2  0.2];           %%% [MOD] extra "try other values" point

fprintf('\n  a_off    q_off    decimated_y    y - x      effective_input(x+a_off)\n');
fprintf(' -------  -------  ------------- ----------- -----------------------\n');

for c = 1:size(cases,1)
    a_off = cases(c,1);
    q_off = cases(c,2);

    % Pre-allocates and initializes array variables
    w=zeros(1,nr_points);
    y=zeros(1,nr_points);
    w(1)=0.5;
    y(1)=1;

    % The main loop simulating the accumulator and the quantizer
    %************************************************************************
    for a = 2:nr_points
        w(a) = a_off + w(a-1) + in(a-1) - y(a-1);     %%% accumulator offset
        y(a) = sign(w(a) + q_off);                    %%% quantizer offset
    end
    %************************************************************************

    output_average = sum(y)/length(y);
    fprintf(' %+5.2f    %+5.2f   %+10.6f   %+8.4f   %+10.4f\n', ...
            a_off, q_off, output_average, output_average-offset, offset+a_off);

    % Plot waveforms
    figure('Name',sprintf('a_off=%.2f, q_off=%.2f',a_off,q_off));
    subplot(2,1,1); plot(w(1:200),'k','LineWidth',1);
    xlabel('Samples'); ylabel('W (Accumulator)'); grid;
    title(sprintf('a\\_off=%.2f  q\\_off=%.2f   y_{avg}=%.4f', ...
                  a_off, q_off, output_average));
    subplot(2,1,2); plot(y(1:200),'k','LineWidth',1);
    xlabel('Samples'); ylabel('Y (Bitstream)'); grid; ylim([-1.5 1.5]);
    saveas(gcf, sprintf('results/MOD1_offset_a%.2f_q%.2f.png', a_off, q_off));
end
