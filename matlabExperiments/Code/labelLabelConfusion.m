function [ po1, po2 ] = labelLabelConfusion( P1, P2, L1, L2)
%UNTITLED8 Summary of this function goes here
%   Detailed explanation goes here
po1 = sum(L1 == -1 & L2 == 1 & P1 == 1);
po2 = sum(L1 == 1 & L2 == -1 & P2 == 1);
t1 = sum(L1 == -1 & L2 == 1 & (P1 ~= 0));
t2 = sum(L1 == 1 & L2 == -1 & (P2 ~= 0));
if t1 < 10
    po1 = 0;
else
    po1 = po1/t1;
end
if t2 < 10
    po2 = 0;
else
    po2 = po2/t2;
end
end

