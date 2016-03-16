function [idx_selected]=AUDI_select(W,pairs,Uidx,train_data,train_targets,B,V,num_sub)
testidx=find(sum(W==0,2)>0);
testidx=testidx(randperm(length(testidx),min(length(testidx),2*size(W,2))));
test_data=train_data(testidx,:);
pres=RankAL_test(test_data,B,V,num_sub);
thresh=pres(:,end);
n_class=size(W,2);
pres=pres(:,1:end-1)-repmat(thresh,1,n_class);

%idx_ins=randperm(length(testidx),1);
labels=sign(pres);
trainidx=find(sum(W==0,2)==0);
avgP=mean(sum(train_targets(trainidx,:)==1,2));
insvals=-abs((sum(labels==1,2)-avgP)./max(sum(W(testidx,:)==1,2),0.5));
idx_ins=find(insvals==min(insvals));
idx_ins=idx_ins(randperm(length(idx_ins),1));

pres=pres(idx_ins,:);
pres(W(testidx(idx_ins),:)==1)=inf;
[~,idx_label]=min(abs(pres));

idx_ins=testidx(idx_ins);
tmp=pairs(Uidx,:);
idx_selected=find(tmp(:,1)==idx_ins&tmp(:,2)==idx_label);
