% This script implements the MLCM-r and also finds the values of the
% confusion and reliability matrix
% Print each parameter after running the code, to see the results

alpha=3;
nModels = 4;
datasetname = 'test';
P=load(['../Data/',datasetname,'_model_0']);
[nInst, nClasses] = size(P);

P=zeros(nInst, nClasses*nModels);	% connection matrix
for i=1:nModels
    P(:,(i-1)*nClasses+1:i*nClasses)=load(['../Data/',datasetname,'_model_',int2str(i-1)]);
end

d = sum(P~=0,2);
Inst = [1:nInst]';
P = P(d~=0, :);
Inst = Inst(d~=0, :);
oldInst = nInst;
nInst = size(P, 1);
A = zeros(nInst, nClasses * nModels); % Connection matrix with -1 replaced by 0
A = P;
lId = A(:,:) == -1;
A(lId) = 0;

% label matrix for group nodes
L = eye(nClasses);
B = repmat(L, nModels, 1);

% obtain the consensus probability distribution
[U, Q] = MLCMr(nInst, nClasses, nModels, A, alpha, B);


epsilon = 0.4*max(U')';     %mean(U,2) - 0.5*std(U')'; Deciding the threshold for probability values
L = U;          % getting the consensus label matrix, This is the prediction result for each instance
for i=1:nInst 
    lId = L(i,:) < epsilon(i,1);
    L(i,lId) = -1;
    lId = L(i,:) >= epsilon(i,1);
    L(i,lId) = 1;
end

% now we evaluate the kappa values for each user and label
K=zeros(nInst, nClasses*nModels);   % kappa values for each user for each label
LRep = repmat(L, 1, nModels);
K = findKappaMat(P, LRep);          % kappa values for each user , label


% evaluating label-label comparision for each user
% first finding the p(l1|l2) values
LL = zeros(nClasses, nClasses);
for i=1:nModels
    LL = LL + Q((i-1)*nClasses+1:i*nClasses, :);
end
LL = 1/nInst * LL;

Conf = zeros(nClasses, nClasses * nModels);
for i=1:nModels
    Conf(:, (i-1)*nClasses+1:i*nClasses) = userConfusion(P(:, (i-1)*nClasses+1 : i*nClasses), L, LL);
end
Conf = 0.5 * Conf;


% Weighted MLCMr
UW = 1 / nClasses * ones(nInst, nClasses);
QW = zeros(nClasses * nModels, nClasses);
KW = K;
for test=1:5
    a = min(KW);
    b = max(KW);
    if a ~= b
        KW = (KW - a + 0.1)/(b + 0.1 - a);
    end
        
    [UW, QW] = WeightedMLCMr(nInst, nClasses, nModels, A, alpha, B, KW);
    epsilon = 0.35*max(UW')';     %mean(U,2) - 0.5*std(U')'; Deciding the threshold for probability values
    LW = UW;          % getting the consensus label matrix, This is the prediction result for each instance
    for i=1:nInst 
        lId = LW(i,:) < epsilon(i,1);
        LW(i,lId) = -1;
        lId = LW(i,:) >= epsilon(i,1);
        LW(i,lId) = 1;
    end
    % now we evaluate the kappa values for each user and label
    KW=zeros(nInst, nClasses*nModels);   % kappa values for each user for each label
    LWRep = repmat(LW, 1, nModels);
    KW = findKappaMat(P, LWRep);          % kappa values for each user , label
end


