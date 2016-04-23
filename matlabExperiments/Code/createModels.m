%% This script creates models 

%% Parameters
N = 50; % 50 models are created
DatasetName = 'medical';
k = 10;    % 10 fold CV is done
beta = 1;
expNum = 1;
libSVMPath = '../../libsvm-3.21/matlab';
config.libSVMPath = libSVMPath;
addpath(libSVMPath)

%% loading the data from the dataset
[trainData, trainLabel, testData, testLabel] = loadDataset(DatasetName);

%% get N number of models / predictions
instances = size(trainData, 1); % instance count in training
labels = size(trainLabel, 2);   % labels count 
for modelNum =  1 : 1
    %% perfom randomization for each model generation
    order = randperm(instances);
    data = trainData(order, :);
    label = trainData(order, :);
    
    %% select CV folds
    CV = cvpartition(instances, 'KFold', k);
    
    %% Train SVM on each partition and each label
    CArr = zeros(labels, 1);
    GammaArr = zeros(labels, 1);
    
    for l = 1 : 1
        CArr(l) = -1; GammaArr(l) = -5; fMax = 0;
        for c = -1 : 10
            for g = -5 : -1
                config.C = c;
                config.gamma = g;
                fAvg = 0;
                for i = 1 : k
                    trainDataCV = data(CV.training(i), :);
                    trainLabelCV = label(CV.training(i), l);
                    testDataCV = data(CV.test(i), :);
                    testLabelCV = label(CV.test(i), l);

                    % add non zero row to training data
                    nzRow = find(trainLabelCV, 1);

                    % train SVM
                    model = trainSVM([trainDataCV(nzRow, :); trainDataCV], [1; trainLabelCV], config);

                    % prediction for training data
                    [predictionLabelTrn, accuracyTrn, ~] = svmpredict(trainLabelCV, trainDataCV, model);
                    [predictionLabelCV, accuracyCV, ~] = svmpredict(testLabelCV, testDataCV, model);
                    f = findFScore(predictionLabelCV, testLabelCV, beta);
                    fAvg = fAvg + f;
                end
                fAvg = fAvg / k;
                
                if fAvg > fMax
                    fMax = fAvg;
                    CArr(l) = config.C;
                    GammaArr(l) = config.gamma;
                    % add non zero row to training data
                    nzRow = find(trainLabel(:, l), 1);
                    % train SVM
                    %model = trainSVM([trainData(nzRow, :); trainData], [1; trainLabel(:, l)], config);
                    modelMax = model;
                end
            end
        end
        
        % prediction for the test dataset
        ModelArr(l) = modelMax;
        [predictionLabelTest, accuracyTest, ~] = svmpredict(testLabel(:, l), testData, ModelArr(l));
        f = findFScore(predictionLabelTest, testLabel(:, l), beta);
        fprintf('F1 score for label %d is %f. CV FMeasure = %f\n', l, f, fMax);
    end
end

