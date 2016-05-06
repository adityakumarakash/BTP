%% This script is for experiment of case 1
% The models are trained on different dataset. MLCM identifies which models
% need to be retrained, thus updating the training set of the models

%% setup configuration
N = 10;                     % N models are created
DatasetName = 'medical';
k = 5;                     % k fold CV is done for training the models
expNum = 1;
libSVMPath = '../../libsvm-3.21/matlab';
config.libSVMPath = libSVMPath;
addpath(libSVMPath);
fileName = '../Output/temp_expCase1.txt';
fId = fopen(fileName, 'a');

fprintf(fId, '\n--------------------------------------------------\n');
fprintf(fId, 'Dataset %s\n', DatasetName);
%% loading the data from the dataset
[trainData, trainLabel, testData, testLabel] = loadDataset(DatasetName);
OL = testLabel;
OL(OL==0) = -1;
% trainData = trainData(100 : 200, :);
% testData = testData(100 : 200, :);
% trainLabel = trainLabel(100 : 200, :);
% testLabel = testLabel(100 : 200, :);
for exp = 1 : 5
    fprintf(fId, 'experiment = %d\n', exp);
%% Partition data for training each of the models
trainDataModels = cell(N, 1);
trainLabelModels = cell(N, 1);
fraction = 0.9;
trainInst = int32(size(trainData, 1) * 0.9);
totalInstance = size(trainData, 1);
parfor i = 1 : N
    index = randsample(totalInstance, trainInst);
    trainDataModels{i} = trainData(index, :);
    trainLabelModels{i} = trainLabel(index, :);
end

fprintf(fId, 'Training Data generated\n');
maxIteration = 2;
agreementMatrix = zeros(N, maxIteration);
instanceAgreement = zeros(size(testData, 1), maxIteration);

for iteration = 1 : maxIteration
    %% train each model
    modelSet = cell(N, 1);
    parfor i = 1 : N    
        M = trainModelUsingCV(trainDataModels{i}, trainLabelModels{i}, k);
        modelSet{i} = M;
    end
    fprintf(fId, 'Models trained\n');

    %% prediction from each model
    P = zeros(size(testData, 1), size(testLabel, 2) * N);
    labelCount = size(testLabel, 2);
    for i = 1 : N
        P(:, (i - 1) * labelCount + 1 : i * labelCount) = predictLabels(modelSet{i}, testData);
    end

    fprintf(fId, 'Prediction Done\n');

    %% MLCM on the prediction
    index = sum(P, 2) ~= 0;
    index = index .* [1:size(P,1)]';
    index = index(index~=0);
    P = P(index, :);
    OL = testLabel;
    OL(OL==0) = -1;
    OL = OL(index, :);
    A = P;
    P(P == 0) = -1;
    nInstances = size(A, 1);
    nClasses = size(testLabel, 2);
    nModels = N;
    alpha = 1;

    % label matrix for group nodes
    L = eye(nClasses);
    B = repmat(L, nModels, 1);
    [U, Q] = MLCMrClosedForm(nInstances, nClasses, nModels, A, alpha, B);
    fprintf(fId, 'MLCM prediction done\n');

    L = binarizeProbDist(U, P);
    fprintf(fId, 'Binarization Done\n');
    labelPredictions = L;
    labelPredictions(L==-1) = 0;
    % get the agreement values of the instances
    K = zeros(nInstances, 1);
    parfor i = 1 : nInstances
        K(i) = findAgreement(L(i, :), P(i, :));
    end


    fScore = findFScore2(L, OL, 1);
    fprintf(fId, 'f score is %f\n', fScore);


%     % find predictions
%     userConfidenceMicro = zeros(nModels, 1);
%     for i = 1 : nModels
%         userConfidenceMicro(i) = findKappaUser(L, P(:, (i - 1) * nClasses + 1 : i * nClasses));
%     end
% 
    userConfidenceMacro = zeros(nModels, 1);
    for i = 1 : nModels
        userConfidenceMacro(i) = findUserConfidenceMacro(L, P(:, (i - 1) * nClasses + 1 : i * nClasses));
    end
% 
%     userConfidenceMean = zeros(nModels, 1);
%     LRep = repmat(L, 1, nModels);
%     K = findKappaUserLabel(P, LRep);          % kappa values for each user , label
%     for i = 1 : nModels
%         temp = K((i - 1) * nClasses + 1 : i * nClasses);
%         userConfidenceMean(i) = sum(temp) / sum(temp~=-2);
%     end
% 
    userCapacity = userConfidenceMacro;
    agreementMatrix(:, iteration) = userCapacity;

    instanceAgreement(index, iteration) = K;

    if iteration > 1
        fprintf(fId, 'Average Change in agreement Instance = %f\n', sum(instanceAgreement(:, iteration) - instanceAgreement(:, iteration - 1)));
        fprintf(fId, 'Average Change in agreement User = %f\n', sum(agreementMatrix(:, iteration) - agreementMatrix(:, iteration - 1)));
    end
    %histogram(K);
    lthreshold = 0.85; rthreshold = 0.90;
    fprintf(fId, 'Range = %f, %f\n', lthreshold, rthreshold);
    improvementSet = (K >= lthreshold).*(K<rthreshold);
    fprintf(fId, '%d instances\n', sum(improvementSet));
    improvementSet = [1:nInstances]' .* improvementSet;
    improvementSet = improvementSet(improvementSet ~= 0);
    count = size(improvementSet, 1);
    for i = 1 : count
        inst = improvementSet(i);
        modelNum = 1;
        disModel = getDisagreementModels(L(inst, :), P(inst, :), modelNum);
        % appending the new instances
        for j = 1 : modelNum
            trainDataModels{disModel(j)} = [trainDataModels{disModel(j)}; testData(index(inst), :)];
            % consensus output is given as GT
            trainLabelModels{disModel(j)} = [trainLabelModels{disModel(j)}; labelPredictions(inst, :)]; 
        end
    end

end
end

