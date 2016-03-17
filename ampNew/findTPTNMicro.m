function [ TP, TN ] = findTPTNMicro( Y, predictedY)
%UNTITLED Summary of this function goes here
% for the single label case TP, TN finding

TP = sum(Y.*predictedY) / sum(Y);
TN = sum((1-Y).*(1-predictedY)) / sum(1-Y);

end

