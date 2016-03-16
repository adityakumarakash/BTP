function [ Conf ] = userConfusion(P, L, LL)
%UNTITLED7 Summary of this function goes here
%   Detailed explanation goes here
%   returns label-label confusion matrix
%   P is the prediction matrix of user, L is the consensus matrix
%   LL is label label consensus correlation values

nClass = size(P, 2);
Conf = zeros(nClass, nClass);
for l1 = 1:nClass
    for l2 = l1+1:nClass
        [po1, po2] = labelLabelConfusion(P(:, l1), P(:, l2), L(:, l1), L(:, l2));
        pe1 = LL(l1, l2);
        pe2 = LL(l2, l1);
        val = (po1 - pe1) / (1 - pe1) + (po2 - pe2) / (1 - pe2);
        Conf(l1, l2) = val;%(po1 - pe1) / (1 - pe1) + (po2 - pe2) / (1 - pe2);
    end
end

end

