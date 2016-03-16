function [ B ] = myInv( A )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
%B = A\eye(size(A));
B = pinv(A);
end

