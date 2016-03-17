function [labelMatrixTraining, labelMatrixCV, featureMatrixTraining, featureMatrixCV] = createValidationSet(labelMatrix, featureMatrix, config)
    
    %% Create Cross validation set
    rand_smpl_cv = randsample([1:size(labelMatrix,1)],ceil(size(labelMatrix,1)/config.vcFoldSize));
    featureMatrixCV = featureMatrix(rand_smpl_cv,:);
    labelMatrixCV = labelMatrix(rand_smpl_cv,:);
    
    %% Create Training set
    rand_smpl_trn = setdiff([1:size(labelMatrix,1)],rand_smpl_cv);
    featureMatrixTraining = featureMatrix(rand_smpl_trn,:);
    labelMatrixTraining = labelMatrix(rand_smpl_trn,:);
    

end