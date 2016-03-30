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

epsilon = 0.5 * max(U')';     %mean(U,2) - 0.5*std(U')'; Deciding the threshold for probability values
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

% Fleiss kappa for agreement measure
K8 = zeros(nInst, 1);
for i = 1 : nInst
    K8(i) = fleissKappa(P(i, :), nClasses);
end

KAll = [K1 K2 K3 K4 K5 K6 K7 K8];
Color = ['y', 'm', 'c', 'r', 'g', 'b', 'w', 'k'];
XRange = 1 : size(KAll, 1);
figure; cla;
hold on
for i = 1 : size(KAll, 2)
    plot(XRange, KAll(:, i), 'color', Color(i)); 
end

%% selection of instances with high confusion / low Kappa values
K = K8;
HC = []; % set of instances with high confusion based on kappa values
minKappa = min(K);
maxKappa = max(K);
thresholdKappa = minKappa + 0.01 * maxKappa;
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

for i = 1 : size(HC)
    Prob = ones(nClasses, 1);
    instance = HC(i);
    cond1 = U(instance, :) <= threshold(instance) + delta;
    cond2 = U(instance, :) >= threshold(instance) - delta;
    cond = cond1 .* cond2;
    Prob(cond==1) = 2;
    Prob = Prob / sum(Prob);
    
    % sampling the labels
    % selecting l labels as sample
    l = 5;
    Cdf = cumsum(Prob);
    for j = 1 : l
        t = rand;
        confusedLabel = sum(Cdf <= t)
        
        % check for the correctness of the selection
%         if L(instance, confusedLabel) ~= P(instance, confusedLabel)
%             hitCount = hitCount + 1;
%         else
%             missCount = missCount + 1;
%         end
    end
    
    % recommending the users about the selected confused instance
    % label-pair
    % TODO ---
end

fprintf('Hit , Miss is %f, %f\n', hitCount, missCount);
