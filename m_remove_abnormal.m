clc;clear;close all;
GL_no=3;
[data0,date0,commenVar]=f_get_raw_data(GL_no);
% 去除异常炉况
normalState=...
    data0(:,17)>0.32    ...
    & data0(:,8)>20     ...
    & data0(:,20)<450   ...
    & data0(:,7)>2000;
[m,n]=size(data0);
f_save_data(GL_no,'normalState',normalState);
%% 去除输入变量
% filter_manual=[2:6,8:24];
% data0=data0(:,filter_manual);
% commenVar=commenVar(filter_manual);
%% 分段选取小于3倍标准差的样本点
%{
normal_bool=false(m,n);
segmentation_length=8000*1/8;
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
%}
%% 画图验证
%{
loc=3e5;
range=loc:loc+8000;
esemble_bool=normal_bool(:,1);
for i1=2:length(commenVar)
    esemble_bool=esemble_bool&normal_bool(:,i1);
end

% a=find(~esemble_bool(range));
for i1=1:length(commenVar)
    a=find(~normal_bool(range,i1));
    y1=data0(range,i1);
    y2=y1(a);
    figure;
    plot(1:length(range),y1,a,y2,'o');
    title(commenVar{i1});
end
%}
%% 取中值滤波后，误差小于2倍标准差的数据，且对热风压力17进行换炉扰动去除
%
window_len=100; %中值滤波窗口长度
% normal_bool=false(m,n); %正常波动幅度内的样本
hotwind_bool=false(m,1); %去除换炉扰动后的样本点,0是换炉
% data0_diff=zeros(size(data0));
segmentation_length=8000*10; %每次处理的数据的长度
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
    data1_st=(data1-repmat(M1,t2-t1+1,1))./repmat(S1,t2-t1+1,1);
    data1_med=medfilt1(data1_st,window_len,[],1);
    data1_diff=abs(data1_st-data1_med);
%     data0_diff(t1:t2,:)=data1_diff;
%     for i1=1:n
%         normal_bool(t1:t2,i1)=data1_diff(:,i1)<2;
%     end
    hotwind_bool(t1:t2,1)=f_abnormal_expand(data1_diff(:,17),1.5,0.3,6);
    t1=t2+1;
end
close(wb);
%}
%% 画图：中值滤波
%
loc=2e6; %画图的起始位置
range=loc:loc+8000; %画图的长度
% 看data0_diff的分布直方图
%{
num_sub=3;
for i1=1:length(commenVar)
    a=find(~normal_bool(range,i1));
    y1=data0(range,i1);
    y2=data0_diff(range,i1);
    if mod(i1-1,num_sub)==0
        figure;
    end
    subplot(3,3,3*mod(i1-1,num_sub)+1);
    plot(range,y1);
    title(commenVar{i1});
    subplot(3,3,3*mod(i1-1,num_sub)+2);
    plot(range,y2);
    title(commenVar{i1});
    subplot(3,3,3*mod(i1-1,num_sub)+3);
    hist(y2,50);
    title(commenVar{i1});
end
%}

% esemble_bool=normal_bool(:,1);
% for i1=2:length(commenVar)
%     esemble_bool=esemble_bool&normal_bool(:,i1);
% end
% a1=find(~esemble_bool(range));
a2=find(~hotwind_bool(range,1));
for i1=1:length(commenVar)
     y0=data0(range,i1);
%     a1=find(~normal_bool(range,i1));
%     y1=y0(a1);
    y2=y0(a2);
    figure;
    plot(1:length(range),y0,a2,y2,'*');
%     plot(1:length(range),y0,a1,y1,'o',a2,y2,'*');
    title(commenVar{i1});
end
%}
%}
%% 保存数据
f_save_data(GL_no,'hotwind_bool',hotwind_bool);%GL_no,file_name,data0

