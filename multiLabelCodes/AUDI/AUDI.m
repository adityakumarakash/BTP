function query=AUDI(train_data,train_targets,n_init)
% train_data: n*d, one row for an instance with d features
% train_targets: n*m, one row for an instance, -1 means irrelevant, 1 means relevant
% n_init: how many instance should be initial fully labeled
% query: selected instance-label pairs

query=[];
[n,m]=size(train_targets);
train_targets=[train_targets,2*ones(n,1)];

pairs=[];
for k=1:m
    pairs=[pairs;[(1:n)',ones(n,1)*k]];
end

idx=randperm(n,n_init);
W=zeros(n,m);
W(idx,:)=1;
Sidx=[];
for k=1:n_init
    Sidx=[Sidx,find(pairs(:,1)==idx(k))'];
end
Uidx=1:n*m;
Uidx(Sidx)=[];

n_init=length(Sidx);
n_iter=n*m-n_init;
n_batch=size(train_targets,2);

[B,V,AB,AV,Anum,trounds,costs,norm_up,step_size0,num_sub,lambda,avg_begin,avg_size,n_repeat]=AUDI_Init(init_data, init_targets);

for tt=1:n_repeat
    [B,V,AB,AV,Anum,trounds]=AUDI_train(W,train_data,train_targets,B,V,costs,norm_up,step_size0,num_sub,AB,AV,Anum,trounds,lambda,avg_begin,avg_size);
end
more=true;
ins=[];

while(more)
    idx_selected=AUDI_select(W,pairs,Uidx,train_data,train_targets,AB/Anum,AV/Anum,num_sub);
    if((length(Sidx)-n_init+length(idx_selected))>=n_iter)
        idx_selected=idx_selected(1:n_iter+n_init-length(Sidx));
        more=false;
    end
    U=pairs(Uidx(idx_selected),:);
    for j=1:length(idx_selected)
        W(U(j,1),U(j,2))=1;
    end
    query=[query;U];
    Sidx=[Sidx,Uidx(idx_selected)];
    Uidx(idx_selected)=[];
    ins=[ins,unique(U(:,1))];
    if(length(ins)>=n_batch)
        for tt=1:n_repeat
            [B,V,AB,AV,Anum,trounds]=AUDI_train(W(ins,:),train_data(ins,:),train_targets(ins,:),B,V,costs,norm_up,step_size0,num_sub,AB,AV,Anum,trounds,lambda,avg_begin,avg_size);
        end
        ins=[];
    end
end
end

