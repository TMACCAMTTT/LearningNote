%% function: build kTreeStar
%% premise: have built decision tree (name: attrNode)
%% input: X_tr denotes training samples: training samples +?k value
%% output: kStarTree
function [attrNode]=AddNNSampleRecord20151021(X_tr)
[row col]=size(X_tr);
global attrNode;
for i=1:length(attrNode)
    if ~isempty(attrNode(i).Lleaflabel)|~isempty(attrNode(i).Rleaflabel)
        [m n]=size(attrNode(i).Record);
        for tp=1:m
            ktemp=attrNode(i).kvalue(tp,1);
            ind_kNN=knnsearch(X_tr(:,1:col-1),X_tr(attrNode(i).Record(tp),1:col-1),'k',ktemp+1);
            kNNsample=X_tr(ind_kNN,:);
            ind_NN=knnsearch(X_tr(:,1:col-1),kNNsample(:,1:col-1),'k',1+1);
            ind_NNnew=ind_NN(:,2);
            NNsample=X_tr(ind_NNnew,:);    
            r=[kNNsample(:,col);NNsample(:,col)];
            ur=unique(r);
            attrNode(i).set{tp}=ur;
        end
    end
end