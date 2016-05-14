%% This script is to test the relation between cosnensus maximization and ground truth
% We take the prediction of each of the models and plot the consensus
% against the F measure wrt ground truth, taking 1 %, 2 %, 3 %.. from top
% and bottom of the instances.

%% Parameters
experimentTotal = 9;    % Number of experiments
N = 10;                 % count of models for each experiment
DatasetName = 'bibtex';
Folder = '../Output/modelsCV/';%'../ICDMDATA/';%'../Output/models/';
alpha = 1;



for expNum = 1 : 5%experimentTotal
    % for each experiment this is repeated
    fprintf('Experiment Number = %d\n', expNum);
    models = ones(N, 1);
    modelIndex = [1:N]';
    maxIteration = 4;
    capacityMatrix = zeros(N, maxIteration);
    for iteration = 1 : maxIteration
        %% Read the data
        P=load([Folder, DatasetName,'_model_1.y.1']);
        [nInst, nClasses] = size(P);
        nModels = sum(models);
        P=zeros(nInst, nClasses*nModels);	% connection matrix
        i = 0;
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
        %P(P==0) = -1;
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
        
        fScore = findFScore2(L, OL, 1);
        fprintf('f score is %f\n', fScore);

        userConfidenceMicro = zeros(nModels, 1);
        for i = 1 : nModels
            userConfidenceMicro(i) = findKappaUser(L, P(:, (i - 1) * nClasses + 1 : i * nClasses));
        end

        userConfidenceMacro = zeros(nModels, 1);
        for i = 1 : nModels
            userConfidenceMacro(i) = findUserConfidenceMacro(L, P(:, (i - 1) * nClasses + 1 : i * nClasses));
        end

        userConfidenceMean = zeros(nModels, 1);
        LRep = repmat(L, 1, nModels);
        K = findKappaUserLabel(P, LRep);          % kappa values for each user , label
        for i = 1 : nModels
            temp = K((i - 1) * nClasses + 1 : i * nClasses);
            userConfidenceMean(i) = sum(temp) / sum(temp~=-2);
        end

        userCapacity = userConfidenceMacro;
        output = zeros(N, 1);
        output(models==1) = userCapacity;
        capacityMatrix(:, iteration) = output; 
        
        if iteration > 1
            change = sum(models.*(capacityMatrix(:, iteration) - capacityMatrix(:, iteration - 1)));
            fprintf('change aggregate is %f\n', change);
        end

        % We remove the bottom k users and see if there is improvement
        k = 1;
        [~, index] = sort(userCapacity);
        modelsRemoved = modelIndex(index(1:k));
        modelIndex = sort(modelIndex(index(k+1:end)));
        models(modelsRemoved) = 0;
    end
    disp(capacityMatrix);
end
