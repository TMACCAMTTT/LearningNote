clear;clc;

A=load('German.txt');  %    download dataset
A=A(1:250,:);         
XdataNor=A(:,1:24);    %    training samples without labels
XdataNor= NormalizeFea(XdataNor,0);
[m n]=size(XdataNor);
cmaker=A(:,25);        %    labels

ind=crossvalind('Kfold',m,10);
for i=1:10
test=(ind==i);    
train=~test;

alltest{i}=test;

X_tr=XdataNor(train,:);   
X_te=XdataNor(test,:);     

Y_tr=cmaker(train,1);
Y_te=cmaker(test,1);
trainnum=size(X_tr,1);  
testnum=size(X_te,1);  
%% prepare before decision tree
trainnum=size(X_tr,1);
Xdt=[];Ydt=[];   
X_trconvert=X_tr';
for j=1:trainnum
    Xdt{j}=X_tr';
    Ydt{j}=X_trconvert(:,j);
end

%% using training samples to reconstruct themselves
% German dataset parameter settings
rho1_ts=0;  rho4_ts=5*10^-3; rho3_ts=7.5*10^-3;   
p_ts=1;
for j2_ts=1:length(rho3_ts)
    for k2_ts=1:length(rho4_ts)
        [W_ts, funcVal_ts] = L2LPP_L21L1(Xdt,Ydt,rho1_ts,rho3_ts(j2_ts),rho4_ts(k2_ts));
        W_ts(W_ts<0)=0;    
        logicW_ts=W_ts&1;  
        colvalue_ts=sum(logicW_ts);
        if all(colvalue_ts)
            Wcollection_ts(p_ts)={W_ts};
            indexCollection_ts(p_ts)={[j2_ts k2_ts]};
            p_ts=p_ts+1;
        end
    end
end
%% build kStarTree
recordnum=1:1:trainnum;
X_tr2=[X_tr recordnum'];
global attrNode;
global icount;
attrNode=struct([]);
icount=0;
attrlist=1:1:n;
pn_ts=1;
w_ts=Wcollection_ts{pn_ts};         %w:n*c
logicw_ts=w_ts&1; 
colvalue_ts=sum(logicw_ts);
YDs=colvalue_ts';   
D=[X_tr2 YDs];
AttrNode=CreateKTree20151021(D,attrlist,1,1,0); % create decision tree 
AttrNodeKTS0=FillMissingChildNode20151021(1,AttrNode);     % Supplement the missing child node
AttrNodeKTS=AddNNSampleRecord20151021(X_tr2);       %  build kStarTree
%% use kStarTree to classify
tic;
Xtrain=[X_tr Y_tr];
Xtest=[X_te Y_te];
[row col]=size(Xtrain);
ClassfiyResult=kStarTreeClassify20151021(AttrNodeKTS,1,Xtrain,row,col,Xtest); % use kStarTree to classify test samples
correctnum=ClassfiyResult;
correct_kTreeStar(i)=correctnum/testnum;       % classification accuracy
time_kTreeStar(i)=toc;                         % classification time
end
mcorrect_kTreeStar=mean(correct_kTreeStar);
