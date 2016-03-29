%% Script includes the latent capacity of the users in a temporal difference learning way
alpha = 3;
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

%% The MLCM without incorporating the user ratings

% obtain the consensus probability distribution
[U, Q] = MLCMrClosedForm(nInst, nClasses, nModels, A, alpha, B);
U

epsilon = 0.2 * max(U')';     %mean(U,2) - 0.5*std(U')'; Deciding the threshold for probability values
L = U;          % getting the consensus label matrix, This is the prediction result for each instance
for i=1:nInst 
    lId = L(i,:) < epsilon(i,1);
    L(i,lId) = -1;
    lId = L(i,:) >= epsilon(i,1);
    L(i,lId) = 1;
end

% now we evaluate the kappa values for each user and label
LRep = repmat(L, 1, nModels);
KUserLabel = findKappaUserLabel(P, LRep);          % kappa values for each user , label
KUser = zeros(nModels, 1);
for i = 1 : nModels
   KUser(i) = findKappaUser(P(:, (i - 1) * nClasses + 1 : i * nClasses), L);
end


%% MLCM with user ratings changed as temporal difference learning
[U, Q, K] = TDMLCMr(nInst, nClasses, nModels, A, alpha, B, P);


%% Confused instance detection

% For each instance find the GM over the kappa with consensus
K1 = zeros(nInst, 1);   % Confusion using GM
K2 = zeros(nInst, 1);   % Confusion using HM
K3 = zeros(nInst, 1);   % Confusion using AM
for i = 1 : nInst
    count = 0;
    for j = 1 : nModels
        [KVal, temp] = findKappaVec(P(i, (j - 1) * nClasses + 1 : j * nClasses), L(i, :));
        if temp == 1
            K1(i) = K1(i) + log((1 + KVal)/2.0);
            K2(i) = K2(i) + 2.0/(1 + KVal);
            K3(i) = K3(i) + (1 + KVal)/2.0;
            count = count + 1;
        end
    end
    K1(i) = K1(i) / count;
    K1(i) = exp(K1(i));
    K2(i) = count/K2(i);
    K3(i) = K3(i)/count;
end

% finding the Confusion using Kappa over the entire data
LRep = repmat(L, 1, nModels);
K4 = zeros(nInst, 1);   % Confusion using overall Kappa
for i = 1 : nInst
    K4(i) = (1 + findKappaVec(P(i, :), LRep(i, :)))/2.0;
end


% find confusion using pairwise kappa of the labellers
K5 = zeros(nInst, 1);   % GM   
K6 = zeros(nInst, 1);   % HM
K7 = zeros(nInst, 1);   % AM
for inst = 1 : nInst
    count = 0;
    for i = 1 : nModels
        for j = 1 : nModels
            if i ~= j
                [KVal, temp] = findKappaVec(P(inst, (i - 1) * nClasses + 1 : i * nClasses), P(inst, (j - 1) * nClasses + 1 : j * nClasses));
                if temp == 1
                    K5(inst) = K5(inst) + log((1 + KVal)/2.0);
                    K6(inst) = K6(inst) + 2.0/(1 + KVal);
                    K7(inst) = K7(inst) + (1 + KVal)/2.0;
                    count = count + 1;
                end
            end
        end
    end
    if count ~= 0
        K5(inst) = K5(inst) / count;
        K5(inst) = exp(K5(inst));
        K6(inst) = count/K6(inst);
        K7(inst) = K7(inst)/count;
    else
        K5(inst) = 1;
        K6(inst) = 1;
        K7(inst) = 1;
    end
end

[K1 K2 K3 K4 K5 K6 K7]