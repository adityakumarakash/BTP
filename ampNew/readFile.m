function [labelMatrix, featureMatrix] = readFile(filename)
% This function reads the training data file based filename and the label
% count which is provided here
    M=dlmread(filename);
    labelCount = 6;
    [a,b]=size(M);
    featureMatrix=M(:,1:b-labelCount);
    labelMatrix=M(:,b-labelCount+1:b);
end 



