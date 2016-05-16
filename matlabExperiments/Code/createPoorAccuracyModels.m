%% This script is for generating different manual labelers with different ability on different labels
% The models are trained on different dataset. 
% First 1 to 5 models are kept are manual labelers in each dataset.


%% setup configuration
N = 5;                     % N models are created
DatasetName = 'medical';
experimentTotal = 5;

Folder = '../Output/modelsBias/';
fId = fopen(strcat(Folder, 'outputs_', DatasetName, '.txt'), 'a');
fprintf(fId, '\n-----------------------------------------------------\n');


%% loading the data from the dataset
[trainData, trainLabel, testData, testLabel] = loadDataset(DatasetName);
% trainData = trainData(100 : 200, :);
% testData = testData(100 : 200, :);
% trainLabel = trainLabel(100 : 200, :);
% testLabel = testLabel(100 : 200, :);


%% Partition data for training each of the models
data = [trainData; testData];
labels = [trainlabel; testLabels];
labelCount = size(labels, 2);
instanceCount = size(labels, 1);


for expNum = 1 : experimentTotal
	% create subset of Labels for each model
	for l = 1 : labelCount
		lData = data;
		lLabels = labels(:, l);
				
		
						

    for i = 1 : N
        index = randsample(totalInstance, trainInst);
        trainDataModels{i} = trainData(index, :);
        trainLabelModels{i} = trainLabel(index, :);
    end
    fprintf(fId, 'Training Data generated\n');

    %% train each model
    modelSet = cell(N, 1);
    for i = 1 : N    
        M = trainModelUsingCV(trainDataModels{i}, trainLabelModels{i}, k);
        modelSet{i} = M;
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
