function [data0,date0,commenVar]=f_get_raw_data(GL_no)
GL=zeros(7,1);
GL(2)=7;
GL(3)=1;
GL(5)=5;
plotvariable;
filepath=strcat('..\GL_data\',num2str(GL_no),'\');
load(strcat(filepath,'data.mat'));
data0=data0(:,commenDim{GL(GL_no)});% 选取共有变量