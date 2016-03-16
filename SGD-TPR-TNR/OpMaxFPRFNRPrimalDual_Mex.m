function [time, wFinal, perf] = OpMaxFPRFNRPrimalDual_Mex(XTrain, yTrain, XTest, yTest, options)
    C = options.C;
    perf = options.perfMeasure;
    numPasses = options.numPasses;
    
    if options.isValidating == 1
        numTicsExpected = 2;
    elseif options.isValidating == 0
        % We dont want too many tics!
        numTicsExpected = 100;
    else
        error('Please tell me if you are running a validation trial or a main run\nDo so by setting options.isValidating to 0 or 1');
    end
    
    % Data: number of points and features
    numData = length(yTrain);    
    d = size(XTrain,1);
    
    % Step size dual variable update
    D = options.D; %%%
    
    % Proportion of positives
    p = mean(yTrain == 1);
    
    % Reverse calculate the value of tic spacing
    ticSpacing = ceil(numPasses*numData/numTicsExpected);    
    
    % Initial weight vector
    wInit = zeros(d,1);
    
    % Learn using this stream and get the intermediate and final ws
    wInter = OpMaxFPRFNRPrimalDual_C(XTrain,yTrain,p,wInit,C,ticSpacing,numPasses,D);
    
    % The last row of the matrix contains timestamps
    time = wInter(d+1,:);
    
    % Testing time !!
    % The first d rows of the matrix contain the parameter vectors
    yPredicted = sign(sign(XTest'*wInter(1:d,:))-0.5);
    
    % calculatePrecAtK can find out perf for multiple scorings at the same time!
    perf = calculateTPRTNR(yPredicted,yTest,perf);
    
    % Seed for the next pass
    % Be careful that the only the first d rows are parameters
    wFinal = wInter(1:d,end);
end