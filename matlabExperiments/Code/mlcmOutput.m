%% Parameters
experimentTotal = 5;    % Number of experiments
N = 10;                 % count of models for each experiment
DatasetName = 'medical';
Folder = '../Output/modelsCV/';%'../ICDMDATA/';%'../Output/models/';
OutputFolder = '../Output/MLCMOutput/';
alpha = 1;
fprintf('\n--------------------------------------\n');
fprintf('Dataset %s\n', DatasetName);

%% Loop for experiment
for expNum = 6 : 10
    % for each experiment this is repeated
    fprintf('Experiment Number = %d\n', expNum);
    for j=1:N
        if models(j) == 1
            i = i + 1;
            temp = load([Folder, DatasetName, '_model_', int2str(j), '.y.', int2str(expNum)]);
            P(:,(i-1)*nClasses+1:i*nClasses) = predictionConvert(temp);
        end
    end

    % load ground truth
    OL = load([Folder, DatasetName, '.label']);


    % preprocess the data to remove unpredicted instances 
    d = sum(P~=0, 2);
    Inst = [1:nInst]';

    P = P(d~=0, :);         % filter unpredicted rows
    OL = OL(d~=0, :);       % filter unpredicted rows
    Inst = Inst(d~=0, :);
    OL(OL == 0) = -1;

    oldInst = nInst;
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
    [U, Q] = MLCMrClosedForm(nInst, nClasses, nModels, A, alpha, B);
    fprintf('MLCM prediction done\n');
    dlmwrite([OutputFolder, DatasetName, '_U.', expNum], U);
    dlmwrite([OutputFolder, DatasetName, '_Q.', expNum], Q);        

end