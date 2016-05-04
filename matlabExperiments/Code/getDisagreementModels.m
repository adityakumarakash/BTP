function [ modelSet ] = getDisagreementModels( L, P, count)
% find the agreement between users on a instance using average kappa 
%   Detailed explanation goes here

nClasses = size(L, 2);
nModels = size(P, 2) / nClasses;
K = ones(nModels, 1);
validCount = 0;
for i = 1 : nModels
    [KVal, ind] = findKappaVec(P((i - 1) * nClasses + 1 : i * nClasses), L);
    if ind == 1
        K(i) = KVal;
        validCount = validCount + 1;
    end
end
[~, modelSet] = sort(K);
modelSet = modelSet(1 : count);

end



