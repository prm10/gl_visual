function f_save_data(GL_no,file_name,data0)
file_path=strcat('..\GL_data\',num2str(GL_no),'\');
cmd=strcat(file_name,'=data0;');
eval(cmd);
save(strcat(file_path,file_name,'.mat'),file_name);