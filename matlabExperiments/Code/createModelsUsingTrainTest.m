%% This script is for generating different models using CV on train data
% The models are trained on different dataset. 

%% setup configuration
N = 10;                     % N models are created
DatasetName = 'medical';
k = 5;                     % k fold CV is done for training the models
experimentTotal = 1;
libSVMPath = '../../libsvm-3.21/matlab';
config.libSVMPath = libSVMPath;
addpath(libSVMPath);
Folder = '../Output/modelsTrainTest/';
fId = fopen(strcat(Folder, 'outputs.txt'), 'a');
fprintf(fId, '\n-----------------------------------------------------\n');

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

for expNum = 1 : experimentTotal
    for i = 1 : N
        index = randsample(totalInstance, trainInst);
        trainDataModels{i} = trainData(index, :);
        trainLabelModels{i} = trainLabel(index, :);
    end
    fprintf(fId, 'Training Data generated\n');

    %% train each model
    modelSet = cell(N, 1);
    for i = 1 : N    
        M = trainModelUsingCV(trainDataModels{i}, trainLabelModels{i}, k);size(M)
        modelSet{i} = M;size(modelSet{i})
        fprintf(fId, '%d Model trained\n', i);
    end

    %% prediction from each model
    labelCount = size(testLabel, 2);
    parfor i = 1 : N
        P = predictLabels(modelSet{i}, testData);
        dlmwrite([Folder, DatasetName, '_model_', int2str(i), '.y.', int2str(expNum)], predictionLabels, 'delimiter', '\t');
    end

    fprintf(fId, 'Prediction Done for dataset %s\n', DatasetName);
end