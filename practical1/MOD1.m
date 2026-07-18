clear
close all;

%%% [MOD] === Exercise 1: sweep DC inputs and nr_points to study bitstream avg
%%% [MOD] Original: single run with offset=0, nr_points=100.
%%% [MOD] We loop over (offset, nr_points) pairs and report y_avg each time.
offsets   = [0, 0.05, 0.3142];        %%% [MOD] DC inputs requested by the PDF
lengths   = [100, 1000, 10000];        %%% [MOD] "nr_periods" sweep 10 -> 1000

fprintf('\n   offset       N        y_avg        |y_avg - x|\n');
fprintf('  --------    ------    ----------    -------------\n');

for k_off = 1:length(offsets)
    for k_len = 1:length(lengths)

        offset    = offsets(k_off);
        nr_points = lengths(k_len);

        % Input signal definition
        in = offset*(ones(1,nr_points));

        % Pre-allocate and initialize array variables => faster code
        w=zeros(1,nr_points);
        y=zeros(1,nr_points);
        w(1)=0;
        y(1)=1;

        % The main loop simulating the accumulator and the quantizer
        %************************************************************************
        for a = 2:nr_points

            w(a) = w(a-1) + in(a-1) - y(a-1);

            y(a) = sign(w(a));

        end
        %************************************************************************

        %%% [MOD] Bitstream average (decimated DC value)
        average = sum(y)/length(y);
        fprintf('  %7.4f    %6d    %10.6f    %10.6f\n', ...
                offset, nr_points, average, abs(average-offset));

        %%% [MOD] Plot only the longest run for each offset, in its own figure
        if nr_points == lengths(end)
            figure;
            subplot(2,1,1); plot(w,'k','LineWidth',1);
            xlabel('Samples'); ylabel('W (Accumulator)'); grid;
            title(sprintf('MOD1: offset = %.4f V, N = %d, y_{avg} = %.6f', ...
                          offset, nr_points, average));
            subplot(2,1,2); plot(y,'k','LineWidth',1);
            xlabel('Samples'); ylabel('Y (Bitstream)'); grid;
            ylim([-1.5 1.5]);
            saveas(gcf, sprintf('results/MOD1_off_%.4f.png', offset));
        end
    end
end
