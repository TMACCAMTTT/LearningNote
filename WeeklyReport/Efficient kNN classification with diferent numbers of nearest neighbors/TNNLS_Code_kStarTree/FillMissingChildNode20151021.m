function [attrNode]=FillMissingChildNode20151021(i,attrNode3)
global attrNode;
global icount;
if isempty(attrNode(i).rightchildNode)&isempty(attrNode(i).Rleaflabel)&~isempty(attrNode(i).leftchildNode) % 修改过
    attrNode(i).rightchildNode=icount+1;
    attrNode(icount+1).id=icount+1;
    attrNode(icount+1).Rleaflabel=2;  
    attrNode(icount+1).Record=FindMissingRecord20151021(attrNode3,i,[]); 
    attrNode(icount+1).kvalue=FindMissingkvalue20151021(attrNode3,i,[]); 
    icount=icount+1;
end
if isempty(attrNode(i).leftchildNode)&isempty(attrNode(i).Lleaflabel)&~isempty(attrNode(i).rightchildNode) % 修改过
    attrNode(i).leftchildNode=icount+1;
    attrNode(icount+1).id=icount+1;
    attrNode(icount+1).Lleaflabel=1;  
    attrNode(icount+1).Record=FindMissingRecord20151021(attrNode3,i,[]);   
    attrNode(icount+1).kvalue=FindMissingkvalue20151021(attrNode3,i,[]); 
    icount=icount+1;
end

if ~isempty(attrNode(i).Lleaflabel)|~isempty(attrNode(i).Rleaflabel)
    return;
end
if ~isempty(attrNode(i).leftchildNode)&isempty(attrNode(i).Lleaflabel)
    FillMissingChildNode20151021(attrNode(i).leftchildNode,attrNode3);
end
if ~isempty(attrNode(i).rightchildNode)&isempty(attrNode(i).Rleaflabel)
    FillMissingChildNode20151021(attrNode(i).rightchildNode,attrNode3);
end 