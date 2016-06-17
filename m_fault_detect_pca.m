clc;close all;clear;
%% fault time
info={
    '20120323-悬料','2012-03-21 20:49','2012-03-22 16:25','2012-03-23 12:08:22'
    % 不太明显
    '20120325-疑似滑料','2012-03-21 20:49','2012-03-22 16:25','2012-03-25 12:46:13'
    % 凸包可辨识
    '20120330-管道','2012-03-29 08:07','2012-03-30 03:43','2012-03-30 19:56:08'
    % 提前两小时出现故障
    '20130115-疑似悬料','2013-01-14 07:24','2013-01-15 14:07','2013-01-15 23:43:11'
    % 提前一个半小时报警，但更早就开始了工作点跳变
    '20130125-悬料','2013-01-22 05:40','2013-01-25 00:37','2013-01-25 06:55'
    % 轨迹异常变化，提前半个小时预警
    '20130213-管道引发悬料','2013-02-12 23:23','2013-02-13 08:22','2013-02-13 14:42'
    %
    '20130225-管道引发炉凉事故','2013-02-15 00:00','2013-02-19 23:57','2013-02-25 16:45:14'
};
%% import data
ipt=[7;8;13;17;20;24];
plotvariable;
GL_no=3;%高炉编号
choose=7;% 故障编号
opt=struct(...
    'date_begin_train',info{choose,2}, ...
    'date_end_train',info{choose,3}, ...
    'date_begin_test',info{choose,3}, ...
    'date_end_test',info{choose,4}, ...
    'step',360 ... % 每次更新数据的个数
    );
[data0,date0]=f_get_raw_data(GL_no);
hotwind_bool=f_get_data(GL_no,'hotwind_bool');
normalState=f_get_data(GL_no,'normalState');
idx_begin_train=find(date0>datenum(opt.date_begin_train),1);
idx_end_train=find(date0>datenum(opt.date_end_train),1);
idx_begin_test=find(date0>datenum(opt.date_begin_test),1);
idx_end_test=find(date0>datenum(opt.date_end_test),1);
range_fault=1:720;
data_train0=data0(idx_begin_train:idx_end_train,:);
date_train0=date0(idx_begin_train:idx_end_train,:);
data_test0=data0(idx_begin_test:idx_end_test,:);
date_test0=date0(idx_begin_test:idx_end_test,:);
data_fault0=data0(idx_end_test+range_fault,:);
date_fault0=date0(idx_end_test+range_fault,:);
clear data0 date0;
% 去掉换炉扰动、异常炉况
% ns_bool_train0=normalState(idx_begin_train:idx_end_train,:);
% hotwind_bool_train0=hotwind_bool(idx_begin_train:idx_end_train,:);
% data_train0=data_train0(hotwind_bool_train0&ns_bool_train0,:);
% date_train0=date_train0(hotwind_bool_train0&ns_bool_train0,:);

% ns_bool_test0=normalState(idx_begin_test:idx_end_test,:);
% hotwind_bool_test0=hotwind_bool(idx_begin_test:idx_end_test,:);
% data_test0=data_test0(hotwind_bool_test0,:);
% date_test0=date_test0(hotwind_bool_test0,:);
%% pca 
disp('begin to calculate PCA');
len_test=size(data_test0,1);%先对step个样本点进行预测，再将其放入训练集
loc=0:opt.step:len_test;
TS=zeros(len_test,1);
SPE=zeros(len_test,1);
TS_lim=zeros(len_test,1);
SPE_lim=zeros(len_test,1);
Abnormal=false(len_test,1);
% 初始化
L=9; % 主元个数
confidence=0.9999; % 置信度
recursive=false; %是否迭代模型
data_train1=data_train0;
tic;
for i1=1:length(loc)
    t1=min(1+loc(i1),len_test);
    t2=min(opt.step+loc(i1),len_test);
    data_test1=data_test0(t1:t2,:);
    % 标准化
    M_train=mean(data_train1);
    S_train=std(data_train1);
    data_train_sd=bsxfun(@rdivide,bsxfun(@minus,data_train1,M_train),S_train);
    data_test_sd=bsxfun(@rdivide,bsxfun(@minus,data_test1,M_train),S_train);

    if recursive || i1==1 % update model
        [P_train,E_train,spe_limit,ts_limit]=f_pca_model(data_train_sd,L,confidence);
    end
    [output_test,spe_test,ts_test]=f_pca_indicater(data_test_sd,P_train,E_train,L);
    normal1=(spe_test<spe_limit)&(ts_test<ts_limit);
    if recursive || i1==1 %update data of model
        n=sum(normal1);
        data_train1=[data_train1(n+1:end,:);data_test1(normal1,:)];
    end
    Abnormal(t1:t2,1)=~normal1;
    TS(t1:t2,1)=ts_test;
    SPE(t1:t2,1)=spe_test;
    TS_lim(t1:t2,1)=ts_limit;
    SPE_lim(t1:t2,1)=spe_limit;
end
toc;
%% 画统计量
% 限制画图时的大小
TS=min(TS,5*max(TS_lim)*ones(size(TS)));
SPE=min(SPE,5*max(SPE_lim)*ones(size(SPE)));
range1=(1:len_test);
figure;
subplot(211);
plot(range1,TS,range1,TS_lim,'--');
% plot(range1,T2,range1(abnormal),T2(abnormal),'.',range1,T2_lim,'--');
% plot(range1(ns&~sv1),T2(ns&~sv1),range1(ns&~sv1),T2_lim(ns&~sv1),'--');
title('t_2');
subplot(212);
plot(range1,SPE,range1,SPE_lim,'--');
% plot(range1(ns&~sv1),SPE(ns&~sv1),range1(ns&~sv1),SPE_lim(ns&~sv1),'--');
title('spe');
%}
%% original data
%
% data1=data_train0;
data1=data_test0;
data2=data_fault0;
figure;
T1=size(data1,1);
T2=size(data2,1);
for i1=1:6
    subplot(3,2,i1);
    plot(1:T1,data1(:,ipt(i1)),T1+1:T1+T2,data2(:,ipt(i1)));
    title(commenVar{ipt(i1)});
end
%}
