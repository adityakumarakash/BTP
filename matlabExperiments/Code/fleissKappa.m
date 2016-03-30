function [ k ] = fleissKappa( P, nClasses )
% Finds the fleiss kappa for the setting of our problem.
%   Uses 2 categories, 1 and -1
%   P is the prediction vector for each instance

Ind = P ~= 0;
P = P(Ind);
N = size(P, 2) / nClasses;
M = zeros(N, nClasses);
L = nClasses;
for i = 1 : N
    M(i, :) = P((i - 1) * nClasses + 1 : i * nClasses);
end

p0 = sum(sum(M == -1))/(N*L);
p1 = sum(sum(M == 1))/(N*L);

P0 = sum(M == -1, 1);
P1 = sum(M == 1, 1);

PObserved = 0;
for i = 1 : L
    PObserved = PObserved + P0(i) * (P0(i) - 1) + P1(i) * (P1(i) - 1);
end
if N == 1
    PObserved = 1;
else
    PObserved = PObserved / (N * (N - 1) * L);
end
PChance = (p0*p0 + p1*p1) / 2;

if PObserved == PChance
    k = 0;
else
    k = (PObserved - PChance) / (1 - PChance);
end

%k = (k + 1)/2;
end

