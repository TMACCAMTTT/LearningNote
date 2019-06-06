%% Classify multiple samples 
%% input: Xtrain denotes X_tr+Y_tr; Xtest denotes X_te+Y_te
%% output:The correct number of predictions
function [correctnum]=kStarTreeClassify20151021(attrNode2,i,Xtrain,row,col,Xtest)
global attrNode;
if ~isempty(attrNode(1,i).Lleaflabel)|~isempty(attrNode(1,i).Rleaflabel)
    Recordsample=Xtrain(attrNode(1,i).Record,1:col-1);
    [rr rc]=size(Xtest);
    ind_NN=knnsearch(Recordsample,Xtest(:,1:rc-1),'k',1);
    for it=1:rr
        tempset=attrNode(i).set{ind_NN(it)};
        tempsetsample=Xtrain(tempset,:);
        kval=attrNode(i).kvalue(ind_NN(it));
        ind_kNN=knnsearch(tempsetsample(:,1:col-1),Xtest(it,1:rc-1),'k',kval);%第it个测试样本的k近邻
        sample=tempsetsample(ind_kNN,:);
        samplelabel=sample(:,col);
        ul=unique(samplelabel);
        fy=histc(samplelabel,ul);
        [mv mi]=max(fy);
        predictlabel(it)=ul(mi);
    end
    INDF=find((predictlabel'-Xtest(:,rc))==0);
    correctnum=length(INDF); 
    return;
end

D{1}=Xtest(Xtest(:,attrNode(1,i).splitattr)<=attrNode(1,i).splitpoint,:);
D{2}=Xtest(Xtest(:,attrNode(1,i).splitattr)>attrNode(1,i).splitpoint,:);
for j=1:2
    if isempty(D{j})
        if j==1
            Lcorrectnum=0;
        end
        if j==2
            Rcorrectnum=0;
        end
        continue;
    end
    if j==1
        Lcorrectnum=kStarTreeClassify20151021(attrNode2,attrNode(1,i).leftchildNode,Xtrain,row,col,D{j});
    end
    if j==2
        Rcorrectnum=kStarTreeClassify20151021(attrNode2,attrNode(1,i).rightchildNode,Xtrain,row,col,D{j});
    end
end
correctnum=Lcorrectnum+Rcorrectnum;