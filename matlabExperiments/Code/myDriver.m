% This script implements the MLCM-r and also finds the values of the
% confusion and reliability matrix
% Print each parameter after running the code, to see the results

alpha = 1;
nModels = 10;
datasetname = 'medical';
expNo = 9;
change = 1;
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
%U = UTD;
epsilon = 0.9 * max(U')';     %mean(U,2) - 0.5*std(U')'; Deciding the threshold for probability values
%epsilon = ones(nInst, 1) * 0.0001;
L = U;          % getting the consensus label matrix, This is the prediction result for each instance
for i=1:nInst 
    lId = L(i,:) < epsilon(i,1);
    L(i,lId) = -1;
    lId = L(i,:) >= epsilon(i,1);
    L(i,lId) = 1;
end

%% User capacity calculations
% now we evaluate the kappa values for each user and label
K = zeros(1, nClasses*nModels);   % kappa values for each user for each label
LRep = repmat(L, 1, nModels);
K = findKappaMat(P, LRep);          % kappa values for each user , label


% selecting users with highest confidence for each labels
confidentUser = zeros(nClasses, 1);
ind = 0 : nModels - 1;
ind = ind * nClasses;
for l = 1 : nClasses
    temp = K(ind + l);
    [~, confidentUser(l)] = max(temp);
end

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

%% Load the original labels
OL =load(['../ICDMDATA/',datasetname,'.label']);
OL = OL(Inst, :);
OL = predictionConvert(OL);
rankLoss = rankingLoss(OL, U)/nInst;
fprintf('Ranking loss using MLCM-r = %f\n', rankLoss);
rankLoss = rankingLoss(OL, UTD)/nInst;
fprintf('Ranking loss using TD MLCM-r = %f\n', rankLoss);


%% Prediction using threshold selection to maximize kappa measure
if change == 1
    U = UTD;
end
LKappa = U;
thresholdKappaVec = zeros(nInst, 1);
for i = 1 : nInst
    % find the threshold for the case
    temp = U(i, :);
    [temp, index] = sort(temp);
    threshold = (temp(1:nClasses-1) + temp(2:nClasses)) / 2;
    threshold = [0 threshold 1];
    maxK = 0;
    maxTau = 0;
    for tau = threshold
        temp = U(i, :);
        temp(temp <= tau) = -1;
        temp(temp > tau) = 1;
        sumK = 0;
        count = 0;
        for j = 1 : nModels
            [KVal, ind] = findKappaVec(P(i, (j - 1) * nClasses + 1 : j * nClasses), temp);
            if ind == 1
                count = count + 1;
                sumK = sumK + KVal;
            end
        end
        sumK = sumK/count;
        if sumK > maxK
            maxTau = tau;
            maxK = sumK;
        end
    end
    LKappa(i, U(i, :) <= maxTau) = -1;
    LKappa(i, U(i, :) > maxTau) = 1;
    thresholdKappaVec(i) = maxTau;
end


%% calculating f measure
fM = fMeasure(L, OL);
err = findError(L, OL);
fprintf('F = %f, err = %f \n', fM, err);
fMArr = zeros(nModels, 1);
errArr = zeros(nModels, 1);
for i = 1 : nModels
    errArr(i) = findError(P(:, (i - 1) * nClasses + 1 : i * nClasses), OL);
    fMArr(i) = fMeasure(P(:, (i - 1) * nClasses + 1 : i * nClasses), OL);
end
meanFM = mean(fMArr);
meanErr = mean(errArr);
fprintf('mean F = %f, err = %f \n', meanFM, meanErr);
fM = fMeasure(LKappa, OL);
err = findError(LKappa, OL);
fprintf('new F = %f, err = %f \n', fM, err);


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
% Color = ['b', 'r', 'w', 'w', 'w', 'w', 'w', 'w'];
% XRange = 1 : size(KAll, 1);
% YRange = [4, 8];
% for i = 1 : size(YRange, 2)
%     plot(XRange, KAll(:, YRange(i)), 'color', Color(i)); 
% end

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
%threshold = epsilon;  % the threshold for the instances
threshold = thresholdKappaVec;
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
    l = 10;
    Cdf = cumsum(Prob);
    for j = 1 : l
        t = rand;
        confusedLabel = sum(Cdf <= t);
        if confusedLabel == 0
            continue;
        end
        
        % check for the correctness of the selection
        if L(instance, confusedLabel) == OL(instance, confusedLabel)
            hitCount = hitCount + 1; 
        else
            missCount = missCount + 1; 
        end
        
        % correctness by comparing with the confident users
%         correctLabelValue = P(instance, (confidentUser(confusedLabel) - 1) * nClasses + confusedLabel);
%         if correctLabelValue ~= L(instance, confusedLabel)
%             if correctLabelValue == OL(instance, confusedLabel)
%                 hitCount = hitCount + 1;
%             else
%                 missCount = missCount + 1;
%             end
%         end
        
    end
    
    % recommending the users about the selected confused instance
    % label-pair
    % TODO ---
end
fprintf('Confused Instance = %d\n', size(HC, 2));
fprintf('Hit = %d, Miss = %d, Hit percent = %.2f \n', hitCount, missCount, (hitCount*100.0)/(missCount+hitCount));

mean(sum(OL==1, 1))



%% Experiment with all users to increase the consensus using GT

%U, Q from MLCM
%L is the labels
L = LKappa;
K = K3;     % kappa values for the instances
[sortedValues, sortedIndex] = sort(K);



%% Experiment with all users but experts

% expert evaluation

userConfidenceMicro = zeros(nModels, 1);
for i = 1 : nModels
    userConfidenceMicro(i) = findKappaUser(L, P(:, (i - 1) * nClasses + 1 : i * nClasses));
end

userConfidenceMacro = zeros(nModels, 1);
for i = 1 : nModels
    userConfidenceMacro(i) = findUserConfidenceMacro(L, P(:, (i - 1) * nClasses + 1 : i * nClasses));
end

userConfidenceMean = zeros(nModels, 1);
LRep = repmat(L, 1, nModels);
K = findKappaUserLabel(P, LRep);          % kappa values for each user , label
for i = 1 : nModels
    temp = K((i - 1) * nClasses + 1 : i * nClasses);
    userConfidenceMean(i) = sum(temp) / sum(temp~=-2);
end

% figure;
% hold on;
% plot(userConfidenceMicro);
% plot(userConfidenceMacro);
% plot(userConfidenceMean);
% plot(fMArr);
% hold off;

userCapacity = userConfidenceMacro;

% expert selection 
% selecting top 'expertNum' users as the experts
expertNum = 3;                                              % parameter
[sortedValues, sortIndex] = sort(userCapacity ,'descend');  
maxIndex = sortIndex(1 : expertNum); 
genIndex = sortIndex(expertNum + 1 : end);

% generating the new data using by removing the experts
% expert opinion
expertL = zeros(nInst, nClasses); 
for i = maxIndex
    expertL = expertL + P(:, (i - 1) * nClasses + 1 : i * nClasses);
end
expertL(expertL > 0) = 1;
expertL(expertL < 0) = -1;

% non experts
nModelsGen = nModels - expertNum;
genP = zeros(nInst, nClasses * nModelsGen);
for i = 1 : nModelsGen
    modelNo = genIndex(i);
    genP(:, (i - 1) * nClasses + 1 : i * nClasses) = P(:, (modelNo - 1) * nClasses + 1 : modelNo * nClasses);
end
P = genP;
nModels = nModelsGen;

d = sum(P~=0,2);
Inst = [1:nInst]';
P = P(d~=0, :);
Inst = Inst(d~=0, :);
oldInst = nInst;
nInst = size(P, 1);

expertL = expertL(Inst, :);
OL = OL(Inst, :);
% MLCM on the general models data
A = P;
lId = A(:,:) == -1;
A(lId) = 0;

% label matrix for group nodes
temp = eye(nClasses);
B = repmat(temp, nModels, 1);

% Closed form values of U and Q
[U, Q] = MLCMrClosedForm(nInst, nClasses, nModels, A, alpha, B);

% obtaining the prediction
% Prediction using threshold selection to maximize kappa measure
L = U;
thresholdKappaVec = zeros(nInst, 1);
for i = 1 : nInst
    % find the threshold for the case
    temp = U(i, :);
    [temp, index] = sort(temp);
    threshold = (temp(1:nClasses-1) + temp(2:nClasses)) / 2;
    threshold = [0 threshold 1];
    maxK = 0;
    maxTau = 0;
    for tau = threshold
        temp = U(i, :);
        temp(temp <= tau) = -1;
        temp(temp > tau) = 1;
        sumK = 0;
        count = 0;
        for j = 1 : nModelsGen
            [KVal, ind] = findKappaVec(P(i, (j - 1) * nClasses + 1 : j * nClasses), temp);
            if ind == 1
                count = count + 1;
                sumK = sumK + KVal;
            end
        end
        sumK = sumK/count;
        if sumK > maxK
            maxTau = tau;
            maxK = sumK;
        end
    end
    L(i, U(i, :) <= maxTau) = -1;
    L(i, U(i, :) > maxTau) = 1;
    thresholdKappaVec(i) = maxTau;
end

% ordering the instances based on the confusion

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

% Fleiss kappa for agreement measure
K4 = zeros(nInst, 1);
for i = 1 : nInst
    K4(i) = fleissKappa(P(i, :), nClasses);
end

% using one of the kappa
K = K3;

[sortedValues, sortedIndex] = sort(K); 
% for percentile = 1 : 100
for inst = 1 : 10
    i = sortedIndex(inst);
    delta = 0.01;
    Prob = U(i, :);
    ind = logical((Prob >= (thresholdKappaVec(i) - delta)) .* (Prob <= (thresholdKappaVec(i) + delta)));
    % find the new labels
    LNew = L(i, :);
    LNew(ind) = OL(i, ind);
    
    % calculating the consensus
    count = 0;
    k = 0;
    for j = 1 : nModels
        [KVal, temp] = findKappaVec(P(i, (j - 1) * nClasses + 1 : j * nClasses), LNew);
        if temp == 1
            k = k + (1 + KVal)/2.0;
            count = count + 1;
        end
    end
    k = k/count;
    fprintf('For inst = %d, Consensus old = %f, new = %f\n', i, sortedValues(inst), k);
end
% end

