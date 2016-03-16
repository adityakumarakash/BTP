function [ U, Q ] = MLCMr( nInstance, nClass, nModel, A, alpha, B )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
% This function uses the MLCM-r method to establish consensus using the
% data in form of instance vs group prediction which would be sent as
% parameter :-
% A     -> instance x group matrix
% alpha -> relaxation parameter
% B     -> the original label of the group nodes

U = 1 / nClass * ones(nInstance, nClass);
Q = zeros(nClass * nModel, nClass);

Dn = diag(1./sum(A, 2));
Dv = diag(1./(sum(A, 1) + alpha));

epsilon = 0.00001;
error = 1;
h=waitbar(0,'Waiting for convergence...');
count = 0;
while error > epsilon% && count < 30
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

