% This script implements the MLCM-r and also finds the values of the
% confusion and reliability matrix
% Print each parameter after running the code, to see the results

alpha = 1;
nModels = 10;
datasetname = 'medical';
expNo = 7;
fprintf('Experiment = %d\n', expNo);
P=load(['../ICDMDATA/',datasetname,'_model_0.y.0']);
[nInst, nClasses] = size(P);

P=zeros(nInst, nClasses*nModels);	% connection matrix
for i=1:nModels
    temp = load(['../ICDMDATA/',datasetname,'_model_',int2str(i-1),'.y.', int2str(expNo)]);
    P(:,(i-1)*nClasses+1:i*nClasses) = predictionConvert(temp);
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
%[U, Q] = MLCMr(nInst, nClasses, nModels, A, alpha, B);

% Closed form values of U and Q
[U, Q] = MLCMrClosedForm(nInst, nClasses, nModels, A, alpha, B);

% MLCM with TD learning 
[UTD, QTD, KTD] = TDMLCMr(nInst, nClasses, nModels, A, alpha, B, P);

epsilon = 0.4 * max(U')';     %mean(U,2) - 0.5*std(U')'; Deciding the threshold for probability values
%epsilon = ones(nInst, 1) * 0.01;
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

% Load the original labels
OL =load(['../ICDMDATA/',datasetname,'.label']);
OL = OL(Inst, :);
OL = predictionConvert(OL);
rankLoss = rankingLoss(OL, U)/nInst;
%fprintf('Ranking loss using MLCM-r = %f\n', rankLoss);
rankLoss = rankingLoss(OL, UTD)/nInst;
%fprintf('Ranking loss using TD MLCM-r = %f\n', rankLoss);

%% calculating f measure
fM = fMeasure(L, OL);
fprintf('F measure = %f \n', fM);


%% Confused instance detection in MLCM-r


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

% Fleiss kappa for agreement measure
K8 = zeros(nInst, 1);
for i = 1 : nInst
    K8(i) = fleissKappa(P(i, :), nClasses);
end

KAll = [K1 K2 K3 K4 K5 K6 K7 K8];
Color = ['b', 'r', 'w', 'w', 'w', 'w', 'w', 'w'];
XRange = 1 : size(KAll, 1);
YRange = [4, 8];
for i = 1 : size(YRange, 2)
    plot(XRange, KAll(:, YRange(i)), 'color', Color(i)); 
end

%% selection of instances with high confusion / low Kappa values
K = K8;
HC = []; % set of instances with high confusion based on kappa values
minKappa = min(K);
maxKappa = max(K);
thresholdKappa = minKappa + 0.005 * maxKappa;
for i = 1 : nInst
    if K(i) < thresholdKappa
        HC = [HC i];
    end
end


%% selection of labels from the instances based on the threshold
threshold = epsilon;  % the threshold for the instances
delta = 0.01;         % the dela nearness of the instance probability which are to be selected
hitCount = 0;
missCount = 0;

for i = 1 : size(HC, 2)
    Prob = ones(nClasses, 1);
    instance = HC(i);
    cond1 = U(instance, :) <= threshold(instance) + delta;
    cond2 = U(instance, :) >= threshold(instance) - delta;
    cond = cond1 .* cond2;
    Prob(cond==1) = 10;
    Prob = Prob / sum(Prob);
    
    % sampling the labels
    % selecting l labels as sample
    l = 1000;
    Cdf = cumsum(Prob);
    for j = 1 : l
        t = rand;
        confusedLabel = sum(Cdf <= t);
        if confusedLabel == 0
            continue;
        end
        % check for the correctness of the selection
        if L(instance, confusedLabel) ~= P(instance, confusedLabel)
            hitCount = hitCount + 1; 
        else
            missCount = missCount + 1; 
        end
    end
    
    % recommending the users about the selected confused instance
    % label-pair
    % TODO ---
end
fprintf('Confused Instance = %d\n', size(HC, 2));
fprintf('Hit = %d, Miss = %d, Hit percent = %.2f \n', hitCount, missCount, (hitCount*100.0)/(missCount+hitCount));


%% Weighted MLCMr Old Code - Results not as expected
% UW = 1 / nClasses * ones(nInst, nClasses);
% QW = zeros(nClasses * nModels, nClasses);
% KW = K;
% for test=1:1
%     a = min(KW);
%     b = max(KW);
%     c = 10;
%     if a ~= b
%         KW = 0.1*(KW - a + 1)/(b + 1 - a);
%     end
%         
%     [UW, QW] = WeightedMLCMr(nInst, nClasses, nModels, A, alpha, B, KW);
%     epsilon = 0.35*max(UW')';     %mean(U,2) - 0.5*std(U')'; Deciding the threshold for probability values
%     LW = UW;          % getting the consensus label matrix, This is the prediction result for each instance
%     for i=1:nInst 
%         lId = LW(i,:) < epsilon(i,1);
%         LW(i,lId) = -1;
%         lId = LW(i,:) >= epsilon(i,1);
%         LW(i,lId) = 1;
%     end
%     % now we evaluate the kappa values for each user and label
%     KW=zeros(nInst, nClasses * nModels);   % kappa values for each user for each label
%     LWRep = repmat(LW, 1, nModels);
%     KW = findKappaMat(P, LWRep);          % kappa values for each user , label
%     rankingLoss(OL, UW)/nInst
% end
% 
% % load the actual values
% y=zeros(nInst, nClasses);
% y(d~=0,:) = U;
% dlmwrite(['../Output/',datasetname, '.out.', int2str(expNo)],y,'delimiter','\t','precision',6);
% 
% 
% % prediction by people
% Pred =load(['../ICDMDATA/',datasetname,'.ml_bgcm.y.', int2str(expNo)]);
% Pred = Pred(d~=0, :);
% Pred = predictionConvert(Pred);
% rankingLoss(OL, Pred)/nInst

