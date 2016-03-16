function [ U, Q ] = WeightedMLCMr( nInstance, nClass, nModel, A, alpha, B, K)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
%   This version of MLCMr includes the reliability values, K
%   

U = 1 / nClass * ones(nInstance, nClass);
Q = zeros(nClass * nModel, nClass);

Dn = diag(1./sum(A, 2));
Dv = diag(1./(sum(A, 1) + alpha));

epsilon = 0.00001;
error = 1;
KRep = repmat(K, nInstance, 1);
A = A.*KRep;
h=waitbar(0,'Waiting for convergence...');
count = 0;
while error > epsilon && count < 30
    error = 0;
    Uold = U;
    Q = Dv * (A' * U + alpha * B);
    U = Dn * A * Q;
    error = RMSE(Uold, U);
    waitbar(epsilon/error);
    count = count + 1;
end
close(h);
end


