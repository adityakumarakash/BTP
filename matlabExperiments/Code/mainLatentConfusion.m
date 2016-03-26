%% Script includes the latent capacity of the users in a temporal difference learning way
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
[U, Q] = MLCMrClosedForm(nInst, nClasses, nModels, A, alpha, B);


epsilon = 0.2*max(U')';     %mean(U,2) - 0.5*std(U')'; Deciding the threshold for probability values
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

