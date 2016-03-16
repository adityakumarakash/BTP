function [] = printConfStats(P1, P2, L1, L2)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
po1 = sum(L1 == -1 & L2 == 1 & P1 == 1)
po2 = sum(L1 == 1 & L2 == -1 & P2 == 1)
t1 = sum(L1 == -1 & L2 == 1 & (P1 ~= 0))
t2 = sum(L1 == 1 & L2 == -1 & (P2 ~= 0))

end

