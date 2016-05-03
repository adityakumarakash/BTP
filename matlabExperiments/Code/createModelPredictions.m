%% This script creates model predictions using the following method
% For each experiment data is shuffled randomly, 
% k-fold CV is used to predict for each of instance. This prediction is
% done for all the instances.
% N models are create using this strategy.

%% Parameters
N = 1; % N models are created
DatasetName = 'medical';
k = 10;    % k fold CV is done
beta = 1;
expTotal = 1; % Num of experiments
libSVMPath = '../../libsvm-3.21/matlab';
config.libSVMPath = libSVMPath;
addpath(libSVMPath);
Folder = '../Output/modelsCV/';
fId = fopen(strcat(Folder, 'outputs.txt'), 'a');
fprintf(fId, '\n-----------------------------------------------------------\n');

%% loading the data from the dataset
[trainData, trainLabel, testData, testLabel] = loadDataset(DatasetName);
dataSet = [trainData; testData];
labelSet = [trainLabel; testLabel];

% dataSet = trainData;
% labelSet = trainLabel;

% write the original labels of the models
dlmwrite([Folder, DatasetName, '.label'], labelSet, 'delimiter', '\t');

%% get N number of models / predictions
instanceCount = size(dataSet, 1); % instance count in training
labelCount = size(labelSet, 2);   % labels count 

for expNum = 1 : expTotal
    for modelNum =  1 : N
        %% perfom randomization for each model generation
        fprintf(fId, 'Model Number %d\n', modelNum);
        order = randperm(instanceCount);
        data = dataSet(order, :);
        label = labelSet(order, :);
        revOrder = zeros(instanceCount, 1);
        revOrder(order) = 1 : instanceCount;

        %% select CV folds
        CV = cvpartition(instanceCount, 'KFold', k);

        %% Train SVM on each partition and each label
        CArr = zeros(labelCount, 1);
        GammaArr = zeros(labelCount, 1);
        predictionLabels = zeros(instanceCount, labelCount);
        for l = 1 : labelCount
            predictionLabel = zeros(instanceCount, 1);
            CArr(l) = -1; GammaArr(l) = -5; fMax = 0;
            lowC = 3; highC = 10;
            lowG = -4; highG = -4;
            
            if modelNum > 1
                lowC = CArr(l);
                highC = CArr(l);
                lowG = GammaArr(l);
                highG = GammaArr(l);
            end
            
            for c = lowC : highC             % from -1 to 10
                for g = lowG : highG         % from -5 to -1
                    config.C = c;
                    config.gamma = g;
                    fAvg = 0;
                    predictionLabelTemp = zeros(instanceCount, 1);
                    parfor i = 1 : k
                        trainDataCV = data(CV.training(i), :);
                        trainLabelCV = label(CV.training(i), l);
                        testDataCV = data(CV.test(i), :);
                        testLabelCV = label(CV.test(i), l);

                        % add non zero row to training data
                        nzRow = find(trainLabelCV, 1);
                        if size(nzRow, 1) * size(nzRow, 2) == 0
                            nzRow = 1;
                        end
                        % train SVM
                        model = trainSVM([trainDataCV(nzRow, :); trainDataCV], [1; trainLabelCV], config);

                        % prediction for training data
                        [predictionLabelTrn, accuracyTrn, ~] = svmpredict(trainLabelCV, trainDataCV, model);
                        [predictionLabelCV, accuracyCV, ~] = svmpredict(testLabelCV, testDataCV, model);
                        f = findFScore(predictionLabelCV, testLabelCV, beta);
                        fAvg = fAvg + f;
                        temp = zeros(instanceCount, 1);
                        temp(CV.test(i)) = predictionLabelCV;
                        predictionLabelTemp = predictionLabelTemp + temp;
                    end

                    fAvg = fAvg / k;

                    if fAvg > fMax
                        fMax = fAvg;
                        CArr(l) = config.C;
                        GammaArr(l) = config.gamma;
                        predictionLabel = predictionLabelTemp;
                    end
                end
            end


            % prediction for the test dataset
            predictionLabels(:, l) = predictionLabel;
            fprintf(fId, 'F1 score for label %d. CV FMeasure = %f\n', l, fMax);
        end

        % saved the generated prediction of the model by rearranging
        predictionLabels(revOrder, :) = predictionLabels;
        dlmwrite([Folder, DatasetName, '_model_', int2str(modelNum), '.y.', int2str(expNum)], predictionLabels, 'delimiter', '\t');
    end
end

fprintf(fId, 'Done predictions for dataset %s\n', DatasetName);