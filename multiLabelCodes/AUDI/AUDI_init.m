function [B,V,AB,AV,Anum,trounds,costs,norm_up,step_size0,num_sub,lambda,avg_begin,avg_size,n_repeat]=AUDI_init(init_data, init_targets)
% initialization

d=size(init_data,2);
n_class=size(init_targets,2);
n_repeat=10;
D=200;
num_sub=5;
norm_up=inf;
lambda=0;%.0000001;
step_size0=0.05;
avg_begin=10;
avg_size=5;
AB=0;
AV=0;
Anum=0;
trounds=0;

costs=1./(1:n_class);
for k=2:n_class
    costs(k)=costs(k-1)+costs(k);
end

V=normrnd(0,1/sqrt(d),D,d); % D*m
B=normrnd(0,1/sqrt(d),D,n_class*num_sub); % D*n_class
for k=1:d
    tmp1=V(:,k);
    if(tmp1>norm_up)
        V(:,k)=tmp1*norm_up/norm(tmp1);
    end
end
for k=1:n_class*num_sub
    tmp1=B(:,k);
    if(tmp1>norm_up)
        B(:,k)=tmp1*norm_up/norm(tmp1);
    end
end