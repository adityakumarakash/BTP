function [ f ] = findFScore2( P, L, beta )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
% L is the original set of labels
% P is the prediction

TP = sum((L==1) .* (P==1));
FP = sum((L==-1) .* (P==1));
FN = sum((L==1) .* (P==-1));
precision = TP/(TP + FP);
recall = TP / (TP + FN);
f = (1 + beta^2)*(precision * recall)/(beta^2 * precision + recall);
if TP == 0
    f = 0;
end

end