function [ loss ] = rankingLoss(L, P)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
%   L is the actual label set, P is the predicted relevance

[nInst, nClass] = size(P);
Rel = (L == 1).*P;
NRel = (L == -1).*P;
loss = 0;
for i = 1:nInst
    A = Rel(i, :);
    B = NRel(i, :);
    %[X, Y] = meshgrid(A(A~=0), B(B~=0));
    %count = sum(sum(X<=Y), 2);
    count = 0;
    A=A(A~=0); B=B(B~=0);
    %[countP, countN] = size(X);
    
    countP = size(A, 2);
    countN = size(B, 2);
    
    for i1 = 1:countP
        for i2 = 1:countN
            if A(i1) <= B(i2)
                count = count + 1;
            end
        end
    end
    
    tot = countP * countN;
    if tot > 0
        loss = loss + count / tot;
    end
end

