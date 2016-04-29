%% This script is for experiment of case 1
% The models are trained on different dataset. MLCM identifies which models
% need to be retrained, thus updating the training set of the models

%% setup configuration
N = 10;                     % N models are created
DatasetName = 'medical';
k = 10;                     % k fold CV is done for training the models
expNum = 1;
libSVMPath = '../../libsvm-3.21/matlab';
config.libSVMPath = libSVMPath;
addpath(libSVMPath);

%% loading the data from the dataset
[trainData, trainLabel, testData, testLabel] = loadDataset(DatasetName);

%% Partition data for training each of the models
trainDataModels = cell(N, 1);
trainLabelModels = cell(N, 1);
fraction = 0.9;
trainInst = int32(size(trainData, 1) * 0.9);
totalInstance = size(trainData, 1);
for i = 1 : N
    index = randsample(totalInstance, trainInst);
    trainDataModels{i} = trainData(index, :);
    trainLabelModels{i} = trainLabel(index, :);
end


%% train each model
modelSet = cell(N, 1);
for i = 1 : N
    modelSet{i} = trainModelUsingCV(trainDataModels{i}, trainLabelModels{i}, k);
end

%% prediction from each model
P = zeros(size(testData, 1), size(testData, 2) * N);
labelCount = size(testData, 2);
for i = 1 : N
    P(:, (i - 1) * labelCount + 1 : i * labelCount) = predictLabels(modelSet{i}, testData);
end

%% MLCM on the prediction
A = P;
P(P == 0) = -1;
nInstances = size(testData, 1);
nClasses = size(testData, 2);
nModels = N;
alpha = 1;

% label matrix for group nodes
L = eye(nClasses);
B = repmat(L, nModels, 1);
[U, Q] = MLCMrClosedForm(nInstances, nClasses, nModels, A, alpha, B);
L = binarizeProbDist(U, P);

% get the agreement values of the instances
K = zero(nInstaces, 1);
for i = 1 : nInstances
    K(i) = findAgreement(L(i, :), P(i, :));
end
