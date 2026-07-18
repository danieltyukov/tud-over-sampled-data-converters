function [DAC] = thermoDAC(index, elements, nr_levels)
% Realizes a thermometer DAC implementing "nr_levels" levels
% "elements" is a vector of NORMALIZED unit DAC elements 
% "index" = [0 .. nr_levels-1] is the thermometer code provided by the quantizer

nr_elements = nr_levels - 1;      % number of DAC elements
DACvect = -ones(1,nr_elements);   % Reset all elements to -1
DACvect(1:index) = 1;             % Set "index" DAC elements to +1
DAC = (elements*DACvect')/nr_elements; % Build the DAC output from the given unit elements





