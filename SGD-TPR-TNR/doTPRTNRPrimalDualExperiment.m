function doTPRTNRPrimalDualExperiment(dataList, perfMeasure)
    load splitOptions.mat
    
    if(strcmp(perfMeasure, 'hmean'))
        baseLearner = @OpHMeanPrimalDual_Mex;
    elseif(strcmp(perfMeasure, 'qmean'))
        baseLearner = @OpQMeanPrimalDual_Mex;
    elseif(strcmp(perfMeasure, 'mintprtnr'))
        baseLearner = @OpMaxFPRFNRPrimalDual_Mex;
    elseif(strcmp(perfMeasure, 'fmeasure'))
        baseLearner = @OpFmeasurePrimalDual_Mex;
    elseif(strcmp(perfMeasure, 'jac'))
        baseLearner = @OpJACPrimalDual_Mex;
    end
    
    datasets = splitOptions.datasets;
    numSplits = splitOptions.numSplits;
    
	for datasetCounter = dataList
        X = load(['datasets/' datasets{datasetCounter} '.X.mat']);
        X = X.X;
        y = load(['datasets/' datasets{datasetCounter} '.y.mat']);
        y = y.y;
        splits = load(['datasets/' datasets{datasetCounter} '.splits.mat']);
        splits = splits.splits;
        
        splits.numValidating = min(25000, floor(splits.numTraining/2));
        
        perfValues = cell(numSplits,1);
        CValues = zeros(numSplits,1);
        wVectors = cell(numSplits,1);
        tValues = cell(numSplits,1);
        tValValues = zeros(numSplits,1);
        DValues = zeros(numSplits,1);
        
        for splitCounter = 1 : numSplits
            % Normalize data            
            if(~splits.isNormalized)
                XThisSplit = bsxfun(@plus,full(X),-splits.means(:,splitCounter));
                XThisSplit = bsxfun(@rdivide,XThisSplit,splits.stds(:,splitCounter));
            else
                XThisSplit = X;
            end

            % Append extra row of ones
            XThisSplit = [XThisSplit; ones(1, size(XThisSplit,2))];            
            
            % Apply split permutation
            XThisSplit = XThisSplit(:,splits.IDs(:,splitCounter));
            yThisSplit = full(y(splits.IDs(:,splitCounter)));

            % Get the training and test splits
            XTrainingThisSplit = XThisSplit(:,1:splits.numTraining);
            yTrainingThisSplit = yThisSplit(1:splits.numTraining);			
            XTestThisSplit = XThisSplit(:,splits.numTraining+1:end);
            yTestThisSplit = yThisSplit(splits.numTraining+1:end);
            
            options.perfMeasure = perfMeasure;
            options.numPasses = 25;
            
            fprintf('(%s) Dataset %s Split %d\n',perfMeasure,datasets{datasetCounter},splitCounter);
            
            % Get a good value of C by cross Validation
            % Also get the time taken to do cross validation
            if(splitCounter == 1)
			% Validating - no need for too many tics
                options.isValidating = 1;
                if(strcmp(perfMeasure,'mintprtnr'))
                    [tValValues(splitCounter) CThisSplit DThisSplit] = doCVForCD(XThisSplit(:,1:2*splits.numValidating),yThisSplit(1:2*splits.numValidating),options,splits.numValidating,baseLearner);
                    CValues(splitCounter) = CThisSplit;
                    DValues(splitCounter) = DThisSplit;                    
                    options.C = CValues(splitCounter);
                    options.D = DValues(splitCounter);
                else
                    [tValValues(splitCounter) CThisSplit] = doCVForC(XThisSplit(:,1:2*splits.numValidating),yThisSplit(1:2*splits.numValidating),options,splits.numValidating,baseLearner);
                    CValues(splitCounter) = CThisSplit;
                    options.C = CValues(splitCounter);
                end
            else
                CValues(splitCounter) = CValues(1);
            end

            % No longer validating - have more tics
            options.isValidating = 0;
            
            % Learn!
            [tValues{splitCounter} wVectors{splitCounter} perfValues{splitCounter}] = baseLearner(XTrainingThisSplit, yTrainingThisSplit, XTestThisSplit, yTestThisSplit, options);
            
            perf = perfValues{splitCounter};
            fprintf('(%s) Dataset %s Split %d: %f\n',perfMeasure,datasets{datasetCounter},splitCounter, perf(end));
            
            save(sprintf('results/primal-dual/%s/perfValues_%s.mat',perfMeasure,datasets{datasetCounter}),'perfValues');
            save(sprintf('results/primal-dual/%s/wVectors_%s.mat',perfMeasure,datasets{datasetCounter}),'wVectors');
            save(sprintf('results/primal-dual/%s/tValues%s.mat',perfMeasure,datasets{datasetCounter}),'tValues');
            save(sprintf('results/primal-dual/%s/tValValues%s.mat',perfMeasure,datasets{datasetCounter}),'tValValues');
            save(sprintf('results/primal-dual/%s/CValues_%s.mat',perfMeasure,datasets{datasetCounter}),'CValues');
            save(sprintf('results/primal-dual/%s/DValues_%s.mat',perfMeasure,datasets{datasetCounter}),'DValues');
        end
	end
end