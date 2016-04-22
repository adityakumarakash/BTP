function [ K ] = findUserConfidenceMacro( X, Y )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

A = sum(X == 1 & Y == 1);
B = sum(X == -1 & Y == -1);
C = sum(X == 1 & Y == -1);
D = sum(X == -1 & Y == 1);
T = A + B + C + D;
po = (A + B) ./ T;
pe = ((A + C).*(A + D) + (B + C).* (B + D)) ./ (T .* T) ;

PO = mean(po);
PE = mean(pe);
if PO == PE
    K = 0;
else
    K = (PO - PE) / (1 - PE);
end

end

