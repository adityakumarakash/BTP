function [ f ] = fMeasure( X, Y )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
%  Y is the original matrix
%  X is the prediction
A = sum(sum(X == 1 & Y == 1));
B = sum(sum(X == -1 & Y == -1));
C = sum(sum(X == 1 & Y == -1));
D = sum(sum(X == -1 & Y == 1));
p = A / (A + C);
r = A / (A + D);

f = 2 * (p * r) / (p + r);


end

