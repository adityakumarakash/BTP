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

%% loading the data from the dataset
[trainData, trainLabel, testData, testLabel] = loadDataset(DatasetName);
% trainData = trainData(100 : 200, :);
% testData = testData(100 : 200, :);
% trainLabel = trainLabel(100 : 200, :);
% testLabel = testLabel(100 : 200, :);

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
fprintf('Training Data generated\n');

%% train each model
modelSet = cell(N, 1);
for i = 1 : N    
    M = trainModelUsingCV(trainDataModels{i}, trainLabelModels{i}, k);size(M)
    modelSet{i} = M;size(modelSet{i})
    fprintf('%d Model trained\n', i);
end

%% prediction from each model
P = zeros(size(testData, 1), size(testLabel, 2) * N);
labelCount = size(testLabel, 2);
for i = 1 : N
    P(:, (i - 1) * labelCount + 1 : i * labelCount) = predictLabels(modelSet{i}, testData);
end

fprintf('Prediction Done\n');

%% MLCM on the prediction
index = sum(P, 2) ~= 0;
P = P(index, :);
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
fprintf('MLCM prediction done\n');

L = binarizeProbDist(U, P);
fprintf('Binarization Done\n');

% get the agreement values of the instances
K = zeros(nInstances, 1);
parfor i = 1 : nInstances
    K(i) = findAgreement(L(i, :), P(i, :));
end
