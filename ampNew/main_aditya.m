clear;
clc;

%% Configuration Setup
% Set Configuration Params
[config] = setConfig();

% Set the libSVM Path
addpath(config.libSVMPath);

fid_parameters = fopen(config.resultFile, 'w');

%% Reading Training File
fprintf(fid_parameters,'\n,-----------------------------------------------------------------------------------------------,\n');
fclose(fid_parameters);

%% Reading Training File
disp('Reading Training file');
[labelMatrix, featureMatrix] = readFile(config.TrainFile);
[instanceCount, labelCount] = size(labelMatrix);
config.labelCount = labelCount;
[x,max_feature] = size(featureMatrix);
disp('Training File reading done');


%% Reading test file
[labelMatrixTest, featureMatrixTest] = readFile(config.TestFile);


%% Creating training and CV set from the training set
[labelMatrixTraining, labelMatrixCV, featureMatrixTraining, featureMatrixCV] = createValidationSet(labelMatrix, featureMatrix, config);


%% Data generation on own
data = generateTrainData(6000,1);

train_cnt_tot = 1:12000;
test_cnt = 12001:18000; 
cv_cnt = 9001:12000;
train_cnt = 1:9000;

featureMatrix = data(train_cnt_tot,1:2);
labelMatrix = data(train_cnt_tot,3:5);

[count_of_sentences, labelCount] = size(labelMatrix);
config.labelCount = labelCount;

[x,max_feature] = size(featureMatrix);
disp('Training File reading done');

% [gold_db_matrix_test, feature_vect_test] = scene_read_example(config.TestFile);
labelMatrixTest = data(test_cnt,3:5);
featureMatrixTest = data(test_cnt,1:2);

% NO_OF_RELNS=1;
config.labelCount = labelCount;
% gold_db_matrix=gold_db_matrix(:,NO_OF_RELNS);


labelMatrixTraining = labelMatrix(train_cnt,:);
labelMatrixCV = labelMatrix(cv_cnt,:); 
featureMatrixTraining = featureMatrix(train_cnt,:);
featureMatrixCV = featureMatrix(cv_cnt,:);


%% Separate SVM for each class
% separate svm for each class is trained in this multilabel svm
for class = 1:1
    % for each class a SVM is trained separate on the same training and CV
    % dataset
    thetaMicroTraining = calculateTheta(labelMatrixTraining(:, class));
    thetaMicroCV = calculateTheta(labelMatrixCV(:, class));
    thetaMicroTest = calculateTheta(labelMatrixCV(:, class));
    
    iterationNo = 0;
    epsilonError = 0.00001;
    config.w0Cost = 0.5;
    config.w1Cost = 0.5;
    vPrev = -1;
    vTraining = 0;
    config.vTrainingBest = -1;
    vBest = -1;
    
        
    while abs(vPrev - vTraining) > epsilonError
        iterationNo = iterationNo + 1
        vPrev = vTraining
                
        for curC = config.cRange
            % This loops checks for different parameters of C in C-SVC
            config.c = curC;
            if curC == 0
                continue;
            end

            %for curG = config.gRange
                % This loops checks for different parameters for gamma 
                curG = 0;
                config.g = curG;
    
                % This loop in the AMP procedure
                nzRow = find(labelMatrixTraining(:,class),1);

                % training the SVM
                [model] = trainSVM([1;labelMatrixTraining(:,class)], 1, [featureMatrixTraining(nzRow,:); featureMatrixTraining], config);

                % obtain the prediction
                [predictedMatrixTrainingTemp, accuracyTraining, decisionValuesTraining] = svmpredict([1;labelMatrixTraining(:,class)], [featureMatrixTraining(nzRow,:);featureMatrixTraining], model);
                predictedMatrixTraining = predictedMatrixTrainingTemp(2:end,:);


                [predictedMatrixCv, accuracyCv, decisionValuesCvTemp] = svmpredict(labelMatrixCV(:,class), featureMatrixCV, model);

                % obtain f measures
                [TPMicroTraining, TNMicroTraining] = findTPTNMicro(labelMatrixTraining(:, class), predictedMatrixTraining);
                [TPMicroCv, TNMicroCv] = findTPTNMicro(labelMatrixCV(:, class), predictedMatrixCv);

                % F-Score
                [vTraining] = findFScoreMicro(config, TPMicroTraining, TNMicroTraining, thetaMicroTraining);
                [vCv] = findFScoreMicro(config, TPMicroCv, TNMicroCv, thetaMicroCV);

                if vCv > vBest
                    modelTraining = model;
                    config.vTrainingBest = vTraining;
                    config.TPMicroTraining = TPMicroTraining;
                    config.TNMicroTraining = TNMicroTraining;
                    config.TPMicroCv = TPMicroCv;
                    config.TNMicroCv = TNMicroCv;
                    vBest = vCv;
                    config.bestC = config.c;
                    config.bestG = config.g;   
                end
            %end
        end
        
        % best c, g values found
        config.w1Cost = (1 + config.BETA^2 - config.vTrainingBest) * thetaMicroTraining;
        config.w0Cost = config.vTrainingBest * thetaMicroTraining;
        denominator = config.w0Cost + config.w1Cost;
        config.w0Cost = config.w0Cost/denominator;
        config.w1Cost = config.w1Cost/denominator;
        config.model(class) = modelTraining;
        
        % calculating the f score for the test dataset
        [predictedMatrixTest, accuracy, decisionValues] = svmpredict(labelMatrixTest(:, class), featureMatrixTest(:,class), config.model(class));
        [TP, TN] = findTPTNMicro(labelMatrixTest(:, class), predictedMatrixTest);
        fScoreTest = findFScoreMicro(config, TP, TN, thetaMicroTest)
        vTraining = config.vTrainingBest
        
    end
    
    
end


%% Separate SVM for each class
% separate svm for each class is trained in this multilabel svm
for class = 1:1
    % for each class a SVM is trained separate on the same training and CV
    % dataset
    thetaMicroTraining = calculateTheta(labelMatrixTraining(:, class));
    thetaMicroCV = calculateTheta(labelMatrixCV(:, class));
    thetaMicroTest = calculateTheta(labelMatrixCV(:, class));
    
    iterationNo = 0;
    epsilonError = 0.00001;
    config.w0Cost = 0.5;
    config.w1Cost = 0.5;
    vPrev = -1;
    vTraining = 0;
    config.vTrainingBest = -1;
    vBest = -1;
    
        
    while abs(vPrev - vTraining) > epsilonError
        iterationNo = iterationNo + 1
        vPrev = vTraining
                
        for curC = config.cRange
            % This loops checks for different parameters of C in C-SVC
            config.c = curC;
            if curC == 0
                continue;
            end

            %for curG = config.gRange
                % This loops checks for different parameters for gamma 
                curG = 0;
                config.g = curG;
    
                % This loop in the AMP procedure
                nzRow = find(labelMatrixTraining(:,class),1);

                % training the SVM
                [model] = trainSVM([1;labelMatrixTraining(:,class)], 1, [featureMatrixTraining(nzRow,:); featureMatrixTraining], config);

                % obtain the prediction
                [predictedMatrixTrainingTemp, accuracyTraining, decisionValuesTraining] = svmpredict([1;labelMatrixTraining(:,class)], [featureMatrixTraining(nzRow,:);featureMatrixTraining], model);
                predictedMatrixTraining = predictedMatrixTrainingTemp(2:end,:);


                [predictedMatrixCv, accuracyCv, decisionValuesCvTemp] = svmpredict(labelMatrixCV(:,class), featureMatrixCV, model);

                % obtain f measures
                [TPMicroTraining, TNMicroTraining] = findTPTNMicro(labelMatrixTraining(:, class), predictedMatrixTraining);
                [TPMicroCv, TNMicroCv] = findTPTNMicro(labelMatrixCV(:, class), predictedMatrixCv);

                % F-Score
                [vTraining] = findFScoreMicro(config, TPMicroTraining, TNMicroTraining, thetaMicroTraining);
                [vCv] = findFScoreMicro(config, TPMicroCv, TNMicroCv, thetaMicroCV);

                if vCv > vBest
                    modelTraining = model;
                    config.vTrainingBest = vTraining;
                    config.TPMicroTraining = TPMicroTraining;
                    config.TNMicroTraining = TNMicroTraining;
                    config.TPMicroCv = TPMicroCv;
                    config.TNMicroCv = TNMicroCv;
                    vBest = vCv;
                    config.bestC = config.c;
                    config.bestG = config.g;   
                end
            %end
        end
        
        % best c, g values found
        config.w1Cost = (1 + config.BETA^2 - config.vTrainingBest);% * thetaMicroTraining;
        config.w0Cost = config.vTrainingBest * thetaMicroTraining;
        denominator = config.w0Cost + config.w1Cost;
        config.w0Cost = config.w0Cost/denominator;
        config.w1Cost = config.w1Cost/denominator;
        config.model(class) = modelTraining;
        
        % calculating the f score for the test dataset
        [predictedMatrixTest, accuracy, decisionValues] = svmpredict(labelMatrixTest(:, class), featureMatrixTest(:,class), config.model(class));
        [TP, TN] = findTPTNMicro(labelMatrixTest(:, class), predictedMatrixTest);
        fScoreTest = findFScoreMicro(config, TP, TN, thetaMicroTest)
        vTraining = config.vTrainingBest
        
    end
    
    
end
