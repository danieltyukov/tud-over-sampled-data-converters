clear
close all;
clc;
format long;

%%% [MOD] === Exercise 1.4: Leaky accumulator ==============================
%%% [MOD] Leaky integrator difference eqn:  w(i) = a * w(i-1) + (x - y)
%%% [MOD] Z-transform:  H(z) = 1 / (1 - a*z^-1)
%%% [MOD]   DC gain  = 1/(1-a) = A
%%% [MOD] An ideal integrator (a=1) makes NTF zero at DC; for a<1 the NTF
%%% [MOD] no longer kills DC perfectly -> measurable DC error appears.

% Input signal definition
nr_points = 8192;          %%% [MOD] longer for accurate decimation
offset    = 34.6e-3
in        = offset*(ones(1,nr_points));

%%% [MOD] Sweep amplifier finite-gain values to expose the leakage effect
A_list = [1e6, 1000, 100, 30, 10];

fprintf('\n   A         alpha        DC-gain      y_avg          y_avg - x\n');
fprintf(' --------  ----------  -----------   -----------   -------------\n');

for k = 1:length(A_list)
    A = A_list(k);
    p = 1 - 1/A;            % loss factor (alpha)

    w = zeros(1,nr_points); y = zeros(1,nr_points);
    w(1) = 0.5; y(1) = 1;

    for a = 2:nr_points
        w(a) = p*w(a-1) + in(a-1) - y(a-1);
        y(a) = sign(w(a));
    end

    output_average = sum(y)/length(y);
    fprintf(' %8g  %10.6f  %10.4f   %+10.6f    %+10.6f\n', ...
            A, p, 1/(1-p), output_average, output_average-offset);

    if A == 100   % keep figure for the canonical "A=100" requested by PDF
        figure;
        subplot(2,1,1); plot(w(1:200),'k','LineWidth',1);
        xlabel('Samples'); ylabel('W (Accumulator)'); grid;
        title(sprintf('Leaky accumulator A=%g, alpha=%.4f, y_{avg}=%.4f',...
                      A, p, output_average));
        subplot(2,1,2); plot(y(1:200),'k','LineWidth',1);
        xlabel('Samples'); ylabel('Y (Bitstream)'); grid; ylim([-1.5 1.5]);
        saveas(gcf,'results/MOD1_leak_A100.png');
    end
end
