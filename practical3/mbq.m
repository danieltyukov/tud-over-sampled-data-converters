function [q_out, index] = mbq(in, nr_levels, vref)
% Realizes a mid-rise multi-bit quantizer
% "nr_levels" = number of levels between -vref and +vref
% "index" = [0 .. nr_levels-1] is the number of DAC elements with the value of +1
% All other DAC elements should have a value of -1

delta = 2/(nr_levels-1);                      % calculate normalized spacing between quantizer levels         
q_out = quant(in/vref + 1,delta) - 1;         % shift normalized input range, use quant, then shift back
q_out = sign(in)*min(abs(q_out),1);           % clip quantized input value
index = round((q_out+1)/delta); % Assign a thermometer code index to the decided quantizer level
