%% build decision tree, perserve leaf node samples (ID3)
%% attrNode denotes built tree
%% D denotes training samples + labels
%% attrlist is used for record weather the atrribute is use, initial values are [1 2 3 4 ....], denotes [attribute1, attribute2, attrbute3,...]
%% i denotes generated i-th node
%% iparenttag is used for record father node variable
%% j=1 denotes generate left child node, j=2 denotes generate right child node
function [attrNode]=CreateKTree20151021(D,attrlist,i,iparenttag,j)
global attrNode;
global icount;
[r c]=size(D);
X=D(:,1:c-2);
Y=D(:,c);
attrNode(i).id=i;
icount=icount+1;
if length(unique(Y))==1   
    if j==1
        attrNode(i).Lleaflabel=1;
        attrNode(iparenttag).leftchildNode=attrNode(i).id;
    end
    if j==2
        attrNode(i).Rleaflabel=2;
        attrNode(iparenttag).rightchildNode=attrNode(i).id;
    end
    attrNode(i).kvalue=D(:,c);   % Added 1th(Notation)
    for temp=1:r
        attrNode(i).Record(temp)=D(temp,c-1);  
    end
    attrNode(i).Record=attrNode(i).Record';
    
    return;
end
if isempty(attrlist)     
    if j==1
        attrNode(i).Lleaflabel=1;
        attrNode(iparenttag).leftchildNode=attrNode(i).id;
    end
    if j==2
        attrNode(i).Rleaflabel=2;
        attrNode(iparenttag).rightchildNode=attrNode(i).id;
    end
    attrNode(i).kvalue=D(:,c);   % Added 1th(Notation)
    for temp=1:r
        attrNode(i).Record(temp)=D(temp,c-1);  
    end
    attrNode(i).Record=attrNode(i).Record';
    
    return;
end
[splitattr, splitpoint]=AttributeSelectMethod([D(:,1:c-2) D(:,c)],attrlist);   %Through the attribute selection method to select the split attribute, split point
attrNode(i).splitattr=splitattr;
attrNode(i).splitpoint=splitpoint;
if j==1                  %  The current node is the left child of his father's node
    attrNode(iparenttag).leftchildNode=attrNode(i).id;
end
if j==2
    attrNode(iparenttag).rightchildNode=attrNode(i).id;
end
iparenttag=i;
t=1;
for al=1:length(attrlist) 
    if attrlist(al)~=splitattr
        attrlistnew(t)=attrlist(al);
        t=t+1;
    end
    if length(attrlist)==1
        attrlistnew=[];
    end
end
if ~isempty(attrlistnew)
    attrlist=attrlistnew;
else
    attrlist=[];
end
D2{1}=D(D(:,splitattr)<=splitpoint,:);
D2{2}=D(D(:,splitattr)>splitpoint,:);
for j=1:2
    if isempty(D2{j})
        continue;
    else 
        CreateKTree20151021(D2{j},attrlist,icount+1,iparenttag,j);
    end
end