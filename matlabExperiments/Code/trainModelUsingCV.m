function [ modelMatrix ] = trainModelUsingCV( trainData, trainLabel, CVFold )
%   Returns a matrix of SVM models for each of the labels
%   Detailed explanation goes here

%% Parameters
k = CVFold;    
beta = 1;

%% get N number of models / predictions
instanceCount = size(trainData, 1); % instance count in training
labelCount = size(trainLabel, 2);   % labels count 

data = trainData;
label = trainLabel;

%% select CV folds
CV = cvpartition(instanceCount, 'KFold', k);

%% Train SVM on each partition and each label
CArr = zeros(labelCount, 1);
GammaArr = zeros(labelCount, 1);


for l = 1 : labelCount
    CArr(l) = -1; GammaArr(l) = -5; fMax = 0;
    for c = -1 : 9
        for g = -4 : -1
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
                if size(nzRow, 1) * size(nzRow, 2) == 0
                    nzRow = 1;
                end
                model = trainSVM([trainDataCV(nzRow, :); trainDataCV], [1; trainLabelCV], config);

                % prediction for training data
                %[predictionLabelTrn, accuracyTrn, ~] = svmpredict(trainLabelCV, trainDataCV, model);
                [predictionLabelCV, ~, ~] = svmpredict(testLabelCV, testDataCV, model);
                f = findFScore(predictionLabelCV, testLabelCV, beta);
                fAvg = fAvg + f;
            end
            
            fAvg = fAvg / k;
            if fAvg > fMax
                fMax = fAvg;
                CArr(l) = config.C;
                GammaArr(l) = config.gamma;
            end
        end
    end

    % add non zero row to training data
    nzRow = find(label(:, l), 1);
    
    if size(nzRow, 1) * size(nzRow, 2) == 0
        nzRow = 1;
    end
    % train SVM on the optimum parameters
    config.C = CArr(l);
    config.gamma = GammaArr(l);
    model = trainSVM([data(nzRow, :); data], [1; label(:, l)], config);   % train the model on the entire data
    if l == 1
        modelMatrix = model;
    else
        modelMatrix = [modelMatrix model];  % append each label model to the matrix
    end
end

end

