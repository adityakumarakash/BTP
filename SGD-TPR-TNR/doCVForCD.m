function [time CBest DBest] = doCVForCD(XTrain, yTrain, options, numValidating, trainingRoutine)
	CVOptions = options;
    
    if size(XTrain,2) ~= length(yTrain)
        error('Mismatch in number of validation examples and labels\n');
    end
    
    if length(yTrain) ~= 2*numValidating
        error('Too few or too many validation examples given\n');
    end
    
    time = 0;
	CBest = -inf;
    DBest = -inf;
	perfBest = -1;
    
    XTrainFold = XTrain(:,1:numValidating);
    XTestFold = XTrain(:,numValidating+1:end);
    
    yTrainFold = yTrain(1:numValidating);
    yTestFold = yTrain(numValidating+1:end);

    Crange = 10.^[-6:2];
    Drange = 10.^[-6:0];
    
    for i = Crange
        CVOptions.C = i;
        
        if(strcmp(options.perfMeasure, 'mintprtnr'))        
            % Try out this value of C, D
            % The training routine may return an array of results - take only the last one.            
            for j = Drange
                CVOptions.D = j;
                [tempTime, ~, tempPerf] = trainingRoutine(XTrainFold, yTrainFold, XTestFold, yTestFold, CVOptions);
                time = time + tempTime(end);

                fprintf('%d  %d: %d\n', i, j, tempPerf(end));

                if tempPerf(end) > perfBest
                    perfBest = tempPerf(end);
                    CBest = i;
                    DBest = j;                    
                end
            end
        else
            % Try out this value of C
            % The training routine may return an array of results - take only the last one.
            [tempTime, ~, tempPerf] = trainingRoutine(XTrainFold, yTrainFold, XTestFold, yTestFold, CVOptions);
            time = time + tempTime(end);

            fprintf('%d: %d\n', i, tempPerf(end));

            if tempPerf(end) > perfBest
                perfBest = tempPerf(end);
                CBest = i;
            end
        end
    end
    
    if(CBest == -Inf)
        CBest = Crange(1);
    end
    if(DBest == -Inf)
        DBest = Drange(1);
    end
    
    fprintf(1,'OpAM: The best %s value is %d\n', options.perfMeasure, perfBest);        
    if(strcmp(options.perfMeasure, 'mintprtnr'))        
        fprintf(1,'OpAM: The best penalty parameter is %d, %d\n', CBest, DBest);
    else
        fprintf(1,'OpAM: The best penalty parameter is %d\n', CBest);
    end
end