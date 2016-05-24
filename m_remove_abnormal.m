clc;clear;close all;
GL_no=3;
[data0,date0,commenVar]=f_get_raw_data(GL_no);
%% 去除异常炉况
normalState=...
    data0(:,17)>0.32    ...
    & data0(:,8)>20     ...
    & data0(:,20)<450   ...
    & data0(:,7)>2000;
%% 去除输入变量
% filter_manual=[2:6,8:24];
% data0=data0(:,filter_manual);
% commenVar=commenVar(filter_manual);
%% 分段
[m,n]=size(data0);
normal_bool=false(m,n);
segmentation_length=8000*1/4;
t1=1;
wb=waitbar(0);
while t1<m
    waitbar(t1/m,wb);
    t2=min(m,t1+segmentation_length-1);
    data1=data0(t1:t2,:);
    ns1=normalState(t1:t2,:);
    data2=data1(ns1,:);
    M1=mean(data2);
    S1=std(data2);
    data1_st_abs=abs((data1-repmat(M1,t2-t1+1,1))./repmat(S1,t2-t1+1,1));
    for i1=1:n
        normal_bool(t1:t2,i1)=f_abnormal_expand(data1_st_abs(:,i1));
    end
    t1=t2+1;
end
close(wb);
%% 画图验证
loc=3e5;
range=loc:loc+segmentation_length;
for i1=1:length(commenVar)
    a=find(~normal_bool(range,i1));
    y1=data0(range,i1);
    y2=y1(a);
    figure;
    plot(1:length(range),y1,a,y2,'o');
    title(commenVar{i1});
end

