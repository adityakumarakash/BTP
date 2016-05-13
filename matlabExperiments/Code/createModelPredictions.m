%% This script creates model predictions using the following method
% For each experiment data is shuffled randomly, 
% k-fold CV is used to predict for each of instance. This prediction is
% done for all the instances.
% N models are create using this strategy.

%% Parameters
N = 1; % N models are created
DatasetName = 'bibtex';
k = 5;    % k fold CV is done
beta = 1;
expTotal = 1; % Num of experiments
libSVMPath = '../../libsvm-3.21/matlab';
addpath(libSVMPath);
Folder = '../Output/modelsCV/';
fId = fopen(strcat(Folder, 'outputs_', DatasetName ,'.txt'), 'a');
fprintf(fId, '\n-----------------------------------------------------------\n');
fprintf(fId, 'Dataset = %s\n', DatasetName);
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
featureCount = size(dataSet, 2);

disp('starting model training');
for expNum = 1 : expTotal
    disp(strcat('experiment ', num2str(expNum)));
    for modelNum =  1 : N
        %% perfom randomization for each model generation
        tic
        fprintf(fId, 'Model Number %d\n', modelNum);
        disp(strcat('model ', num2str(modelNum)));
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
        fMArr = zeros(labelCount, 1);
        for l = 1 : labelCount
            disp(strcat('label ', num2str(l)));
            predictionLabel = zeros(instanceCount, 1);
            %CArr(l) = -1; GammaArr(l) = -5; 
            fMax = 0;
            lowC = 3; highC = 8; % 3, 8
            lowG = 2 - log2(featureCount); highG = 4 - log2(featureCount); % 2,4
            
            bestC = lowC; bestG = lowG;
            for c = lowC : highC             % from -1 to 10
                for g = lowG : highG         % from -5 to -1
                    fAvg = 0;
                    predictionLabelTemp = zeros(instanceCount, 1);
                    for i = 1 : k                    
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
                        tic
                        fitcsvm([trainDataCV(nzRow, :); trainDataCV], [1; trainLabelCV]);
                        toc
                        break;
                        %model = trainRbfSVM([trainDataCV(nzRow, :); trainDataCV], [1; trainLabelCV], c, g);
                        
                        
                        % prediction for training data
                        %[predictionLabelTrn, accuracyTrn, ~] = svmpredict(trainLabelCV, trainDataCV, model);
                        %[predictionLabelCV, accuracyCV, ~] = svmpredict(testLabelCV, testDataCV, model);
                        f = findFScore(predictionLabelCV, testLabelCV, beta);
                        fAvg = fAvg + f;
                        temp = zeros(instanceCount, 1);
                        temp(CV.test(i)) = predictionLabelCV;
                        predictionLabelTemp = predictionLabelTemp + temp;
                    end

                    fAvg = fAvg / k;

                    if fAvg > fMax
                        fMax = fAvg;
                        bestC = c;
                        bestG = g;
                        predictionLabel = predictionLabelTemp;
                    end
                end
            end


            % prediction for the test dataset
            predictionLabels(:, l) = predictionLabel;
            %fprintf(fId, 'F1 score for label %d. CV FMeasure = %f\n', l, fMax);
            fMArr(l) = fMax;
            CArr(l) = bestC;
            GammaArr(l) = bestG;
            disp(strcat(num2str(l), ' done'));
        end

        % saved the generated prediction of the model by rearranging
        predictionLabels(revOrder, :) = predictionLabels;
        dlmwrite([Folder, DatasetName, '_model_', int2str(modelNum), '.y.', int2str(expNum)], predictionLabels, 'delimiter', '\t');
        accuracy = sum(sum(predictionLabels == labelSet)) / (size(labelSet, 1) * size(labelSet, 2));
        fMeasure = findFScore(predictionLabels, labelSet, 1);
        for l = 1 : labelCount
            fprintf(fId, 'F1 score for label %d. CV FMeasure = %f\n', l, fMArr(l));
        end
        fprintf(fId, 'Accuracy = %f, F1 Score = %f\n', accuracy, fMeasure);
        dlmwrite([Folder, DatasetName, '_gamma.txt'], GammaArr);
        dlmwrite([Folder, DatasetName, '_c.txt'], CArr);
        toc
    end
    
    

end


fprintf(fId, 'Done predictions for dataset %s\n', DatasetName);
