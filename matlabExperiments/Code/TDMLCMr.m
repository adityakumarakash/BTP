function [ U, Q, K ] = TDMLCMr( nInstance, nClass, nModel, A, alpha, B, P)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
%   This version of MLCMr includes the reliability values, K 
gamma = 0.1;
K = ones(1, nModel * nClass);
Kprev = zeros(1, nModel * nClass);
iteration = 0;
while sum(sum(abs(K-Kprev)))/sum(sum(abs(Kprev))) > 0.01
    Kprev = K;
    iteration = iteration + 1;
    KRep = repmat(K, nInstance, 1);
    [U, Q] = MLCMrClosedForm(nInstance, nClass, nModel, A .* KRep, alpha, B);
    epsilon = 0.2*max(U')';     %mean(U,2) - 0.5*std(U')'; Deciding the threshold for probability values
    L = U;          % getting the consensus label matrix, This is the prediction result for each instance
    for i=1:nInstance
        lId = L(i,:) < epsilon(i,1);
        L(i,lId) = -1;
        lId = L(i,:) >= epsilon(i,1);
        L(i,lId) = 1;
    end

    % now we evaluate the kappa values for each user and label
    LRep = repmat(L, 1, nModel);
    KNew = findKappaUserLabel(P, LRep);          % kappa values for each user , label
    K = K + gamma * (KNew- K);
end

fprintf('Iteration = %d\n', iteration);