function data0=f_get_data(GL_no,file_name)
file_path=strcat('..\GL_data\',num2str(GL_no),'\');
load(strcat(file_path,file_name,'.mat'));
cmd=strcat('data0=',file_name,';');
eval(cmd);
