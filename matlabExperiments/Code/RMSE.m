function [ error ] = RMSE( Aold , A)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
% Finds the root mean squared error
error = max(sqrt(sum((Aold - A).^2, 2)));
end

