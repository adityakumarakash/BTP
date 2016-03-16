function [ U, Q ] = MLCMrClosedForm( nInstance, nClass, nModel, A, alpha, B )
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
Dv = diag(1./(sum(A, 1)+alpha));
Dl = diag(sum(A, 1)) * diag(1./(sum(A, 1) + alpha));
Doml = diag(alpha./(sum(A, 1) + alpha));

Q = inv(eye(nModel * nClass) - Dv * A' * Dn * A) * Doml * B;
U = Dn * A * Q;

end