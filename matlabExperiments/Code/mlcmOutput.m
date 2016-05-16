%% Parameters
experimentTotal = 5;    % Number of experiments
N = 10;                 % count of models for each experiment
DatasetName = 'bibtex';
Folder = '../Output/modelsCV/';%'../ICDMDATA/';%'../Output/models/';
OutputFolder = '../Output/MLCMOutput/';
alpha = 1;
fprintf('\n--------------------------------------\n');
fprintf('Dataset %s\n', DatasetName);

%% Loop for experiment
for expNum = 1 : 5
    % for e ach experiment this is repeated
    fprintf('Experiment Number = %d\n', expNum);
    P=load([Folder, DatasetName,'_model_1.y.1']);
    [nInst, nClasses] = size(P);
    nModels = N;
    P=zeros(nInst, nClasses*nModels);	% connection matrix
    for i=1:N
        temp = load([Folder, DatasetName, '_model_', int2str(i), '.y.', int2str(expNum)]);
        P(:,(i-1)*nClasses+1:i*nClasses) = predictionConvert(temp);        
    end

    % load ground truth
    OL = load([Folder, DatasetName, '.label']);


    % preprocess the data to remove unpredicted instances 
    d = sum(P~=0, 2);
    Inst = [1:nInst]';
    oldInst = nInst;
    P = P(d~=0, :);         % filter unpredicted rows
    OL = OL(d~=0, :);       % filter unpredicted rows
    Inst = Inst(d~=0, :);
    OL(OL == 0) = -1;

    nInst = size(P, 1);


    A = zeros(nInst, nClasses * nModels);   % Connection matrix with -1 replaced by 0
    A = P;
    P(P==0) = -1;
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
    [Utemp, Qtemp] = MLCMrClosedForm(nInst, nClasses, nModels, A, alpha, B);
    U = zeros(oldInst, size(Utemp, 2));
    U(Inst, :) = Utemp;
    Q = Qtemp;
    fprintf('MLCM prediction done\n');
    dlmwrite([OutputFolder, DatasetName, '_U.', num2str(expNum)], U);
    dlmwrite([OutputFolder, DatasetName, '_Q.', num2str(expNum)], Q);        
    
end