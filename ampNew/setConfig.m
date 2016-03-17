function [config] = setConfig()

%%Make
% system('make clean')
% system('make')

%% Mention the Params in this file
    config.libSVMPath = '../libsvm-3.21/matlab';
    config.BETA = 1;
    config.EPOCHS_COUNT = 1;
    config.TEST_RELATIONS = -1;
    config.TrainFile = 'dataset/scene/scene-train.arff';
    config.TestFile = 'dataset/scene/scene-test.arff';
    config.resultFile = 'results/scene-results.data';
    config.w1Cost=0.5;
    config.w0Cost=0.5;
    
    config.cRange = [-1:10];
    config.gRange = [-5:-1];
    config.g = log2(0.1);
    config.vcFoldSize = 5;
    
    %%% Training prediction Type
    %%%     1 = W'phi(x)
    %%%     2 = Naacl prediction (joint inference)
    %%%     3 = Simple Multilabel
    config.trainingPredictionType=3;
end