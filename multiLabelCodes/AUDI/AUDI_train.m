function [B,V,AB,AV,Anum,trounds]=AUDI_train(W,train_data,train_targets,B,V,costs,norm_up,step_size0,num_sub,AB,AV,Anum,trounds,lambda,average_begin,average_size)

[n,n_class]=size(train_targets);
train_targets=train_targets.*[W,ones(n,1)];
tmpnums=sum(train_targets>=1,2);
train_pairs=zeros(sum(tmpnums),1);
tmpidx=0;
for i=1:n
    train_pairs(tmpidx+1:tmpidx+tmpnums(i))=i;
    tmpidx=tmpidx+tmpnums(i);
end
train_targets=train_targets';
train_pairs=[train_pairs,mod(find(train_targets(:)>=1),n_class)];
train_pairs(train_pairs(:,2)==0,2)=n_class;
train_targets=train_targets';
n=size(train_pairs,1);
random_idx=randperm(n);
for i=1:n
    idx_ins=train_pairs(random_idx(i),1);
    xins=train_data(idx_ins,:)';
    idx_class=train_pairs(random_idx(i),2);
    if(idx_class==n_class)
        idx_irr=find(train_targets(idx_ins,:)==-1);
    else
        idx_irr=[find(train_targets(idx_ins,:)==-1),n_class];
    end
    n_irr=length(idx_irr);
    
    By=B(:,(idx_class-1)*num_sub+1:idx_class*num_sub);
    Vins=V*xins;
    [fy,idx_max_class]=max(By'*Vins,[],1);    
    By=By(:,idx_max_class);    
    fyn=-inf;
    for j=1:n_irr
        idx_pick=idx_irr(randi(n_irr));        
        Byn=B(:,(idx_pick-1)*num_sub+1:idx_pick*num_sub);
        [fyn,idx_max_pick]=max(Byn'*Vins,[],1);
        
        if(fyn>fy-1)
            break;
        end
    end    
    if(fyn>fy-1) 
        step_size=step_size0/(1+lambda*trounds*step_size0);
        trounds=trounds+1;
        Byn=B(:,(idx_pick-1)*num_sub+idx_max_pick);        
        loss=costs(1,floor(n_irr/j));
        tmp1=By+step_size*loss*Vins;%V*xins1;
        tmp3=norm(tmp1);
        if(tmp3>norm_up)
            tmp1=tmp1*norm_up/tmp3;
        end
        tmp2=Byn-step_size*loss*Vins;%V*xins2;
        tmp3=norm(tmp2);
        if(tmp3>norm_up)
            tmp2=tmp2*norm_up/tmp3;
        end
        V=V-step_size*loss*(B(:,[(idx_pick-1)*num_sub+idx_max_pick,(idx_class-1)*num_sub+idx_max_class])*[xins,-xins]');
        norms=DNorm2(V);
        idx_down=find(norms>norm_up);
        B(:,(idx_class-1)*num_sub+idx_max_class)=tmp1;
        B(:,(idx_pick-1)*num_sub+idx_max_pick)=tmp2;
        if(~isempty(idx_down))
            norms(norms<=norm_up)=[];
            for k=1:length(idx_down)
                V(:,idx_down(k))=V(:,idx_down(k))*norm_up./norms(k);
            end
        end
    end
    if(trounds>average_begin&&mod(i,average_size)==0)
        AB=AB+B;
        AV=AV+V;
        Anum=Anum+1;
    end
end