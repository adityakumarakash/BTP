%% This script is to test the relation between cosnensus maximization and ground truth
% We take the prediction of each of the models and plot the consensus
% against the F measure wrt ground truth, taking 1 %, 2 %, 3 %.. from top
% and bottom of the instances.

%% Parameters
experimentTotal = 1;    % Number of experiments
N = 10;                 % count of models for each experiment
DatasetName = 'medical';
Folder = '../ICDMDATA/';%'../Output/models/';
alpha = 1;



for expNum = 1 : 1%experimentTotal
    % for each experiment this is repeated
    fprintf('Experiment Number = %d\n', expNum);
    
    %% Read the data
    P=load([Folder, DatasetName,'_model_0.y.0']);
    [nInst, nClasses] = size(P);
    nModels = N;
    
    P=zeros(nInst, nClasses*nModels);	% connection matrix
    for i=1:nModels
        temp = load([Folder, DatasetName, '_model_', int2str(i-1), '.y.', int2str(expNum)]);
        P(:,(i-1)*nClasses+1:i*nClasses) = predictionConvert(temp);
    end

    % load ground truth
    OL = load([Folder, DatasetName, '.label']);
    
    % preprocess the data to remove unpredicted instances 
    d = sum(P~=0,2);
    Inst = [1:nInst]';
    
    P = P(d~=0, :);         % filter unpredicted rows
    OL = OL(d~=0, :);       % filter unpredicted rows
    Inst = Inst(d~=0, :);
    OL(OL == 0) = -1;
    
    oldInst = nInst;
    nInst = size(P, 1);
    
    
    A = zeros(nInst, nClasses * nModels);   % Connection matrix with -1 replaced by 0
    A = P;
    lId = A(:,:) == -1;
    A(lId) = 0;

    %% Run MLCM model
    % Using MLCM closed form
    % label matrix for group nodes
    L = eye(nClasses);
    B = repmat(L, nModels, 1);

    % obtain the consensus probability distribution
    %[U, Q] = MLCMr(nInst, nClasses, nModels, A, alpha, B);

    % Closed form values of U and Q
    [U, Q] = MLCMrClosedForm(nInst, nClasses, nModels, A, alpha, B);
    fprintf('MLCM prediction done\n');

    
    %% Obtain the Labels using threshold
    
    L = binarizeProbDist(U, P);
    fprintf('Binarization Done\n');

    
    
end