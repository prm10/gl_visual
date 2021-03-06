function varargout = m_visual(varargin)
% M_VISUAL MATLAB code for m_visual.fig
%      M_VISUAL, by itself, creates a new M_VISUAL or raises the existing
%      singleton*.
%
%      H = M_VISUAL returns the handle to a new M_VISUAL or the handle to
%      the existing singleton*.
%
%      M_VISUAL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in M_VISUAL.M with the given input arguments.
%
%      M_VISUAL('Property','Value',...) creates a new M_VISUAL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before m_visual_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to m_visual_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help m_visual

% Last Modified by GUIDE v2.5 02-Jun-2016 15:44:16

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @m_visual_OpeningFcn, ...
                   'gui_OutputFcn',  @m_visual_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before m_visual is made visible.
function m_visual_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to m_visual (see VARARGIN)

global auto_plot_timer plot_handles;
auto_plot_timer=timer(...
    'Name','MyTimer',...
    'Period',0.2,...
    'ExecutionMode','fixedSpacing',...
    'UserData',handles,...
    'TimerFcn',{@update_timer});
figure;
plot_handles=gca;
update_data(handles)
update_model(handles);
update_plot(handles);

% Choose default command line output for m_visual
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes m_visual wait for user response (see UIRESUME)
% uiwait(handles.figure1);

function update_data(handles)
global ...
    data_train0 date_train0 ...
    data_test0 date_test0 ...
    data_fault0 date_fault0 ... 
    step len idx_now direction ...
    hotwind_bool_train0 hotwind_bool_test0 ...
    GL_no;
GL_no=str2double(get(handles.edit_GL_no,'string'));
[data0,date0]=f_get_raw_data(GL_no);
hotwind_bool=f_get_data(GL_no,'hotwind_bool');
normalState=f_get_data(GL_no,'normalState');
idx_begin_train=find(date0>datenum(get(handles.edit_date_begin_train,'string')),1);
idx_end_train=find(date0>datenum(get(handles.edit_date_end_train,'string')),1);
idx_begin_test=find(date0>datenum(get(handles.edit_date_begin_test,'string')),1);
idx_end_test=find(date0>datenum(get(handles.edit_date_end_test,'string')),1);
range_fault=1:720;
data_train0=data0(idx_begin_train:idx_end_train,:);
date_train0=date0(idx_begin_train:idx_end_train,:);
data_test0=data0(idx_begin_test:idx_end_test,:);
date_test0=date0(idx_begin_test:idx_end_test,:);
data_fault0=data0(idx_end_test+range_fault,:);
date_fault0=date0(idx_end_test+range_fault,:);
% 去掉换炉扰动、异常炉况
ns_bool_train0=normalState(idx_begin_train:idx_end_train,:);
hotwind_bool_train0=hotwind_bool(idx_begin_train:idx_end_train,:);
data_train0=data_train0(hotwind_bool_train0&ns_bool_train0,:);
date_train0=date_train0(hotwind_bool_train0&ns_bool_train0,:);
% ns_bool_test0=normalState(idx_begin_test:idx_end_test,:);
% hotwind_bool_test0=hotwind_bool(idx_begin_test:idx_end_test,:);
% data_test0=data_test0(hotwind_bool_test0,:);
% date_test0=date_test0(hotwind_bool_test0,:);

len=str2double(get(handles.edit_len,'string'));
step=str2double(get(handles.edit_step,'string'));
idx_now=1;
direction=1;

function update_model(handles)
global ...
    data_train0 date_train0 ...
    data_test0 date_test0 ...
    hotwind_bool_train0 hotwind_bool_test0 ...
    step len idx_now ...
    M_train S_train ...
    L confidence ...
    P_train E_train ts_limit spe_limit ...
    output_train spe_train ts_train ...
    output_test spe_test ts_test;
M_train=mean(data_train0);
S_train=std(data_train0);
data_train_sd=bsxfun(@rdivide,bsxfun(@minus,data_train0,M_train),S_train);
data_test_sd=bsxfun(@rdivide,bsxfun(@minus,data_test0,M_train),S_train);
% data_train_sd=(data_train0-ones(size(data_train0,1),1)*M_train)./(ones(size(data_train0,1),1)*S_train);
% data_test_sd=(data_test0-ones(size(data_test0,1),1)*M_train)./(ones(size(data_test0,1),1)*S_train);
L=str2double(get(handles.edit_L,'string'));
confidence=str2double(get(handles.edit_confidence,'string'));
[P_train,E_train,spe_limit,ts_limit]=f_pca_model(data_train_sd,L,confidence);
[output_train,spe_train,ts_train]=f_pca_indicater(data_train_sd,P_train,E_train,L);
[output_test,spe_test,ts_test]=f_pca_indicater(data_test_sd,P_train,E_train,L);

function update_timer(obj,eventdata)
global idx_now direction step;
handles=obj.UserData;
idx_now=idx_now+direction*step;
update_plot(handles);

function update_plot(handles)
global L;
if L==2
    update_plot_2d(handles);
else
    update_plot_3d(handles);
end

function update_plot_2d(handles)
global ...
    data_train0 date_train0 ...
    data_test0 date_test0 ...
    step len idx_now ...
    M_train S_train ...
    L confidence ...
    P_train E_train ts_limit spe_limit ...
    output_train spe_train ts_train ...
    output_test spe_test ts_test ...
    plot_handles;
idx_now=min(max(idx_now,len),size(data_test0,1));
range=idx_now-len+1:idx_now;
output_show=output_test(range,1:2);
time_str=datestr(date_test0(idx_now),'yyyy-mm-dd HH:MM:SS');
set(handles.edit_time_now,'string',time_str);
set(handles.slider1,'value',idx_now/size(data_test0,1));
% color_mat=(linspace(0.7,0,length(range)).^0.3)'*ones(1,3);
color_mat=parula(length(range));
axes(plot_handles);
scatter(output_show(:,1),...
    output_show(:,2),...
    linspace(10,50,length(range)),...
    color_mat,...
    'filled','MarkerEdgeColor',[.8,.8,.8]);
hold on;
expression=strcat('t1^2/',num2str(E_train(1)),'+t2^2/',num2str(E_train(2)),'=',num2str(ts_limit));
x1_range=5+sqrt(ts_limit*E_train(1));
x2_range=5+sqrt(ts_limit*E_train(2));
ezplot(expression,[-x1_range,x1_range,-x2_range,x2_range]);
hold off;
axis([-x1_range,x1_range,-x2_range,x2_range]);
axes(plot_handles);
axis equal;
grid;
title(time_str);
xlabel('t_1');
ylabel('t_2');
drawnow;

function update_plot_all(choice) %train or test
global L;
if L==2
    update_plot_all_2d(choice);
else
    update_plot_all_3d(choice);
end

function update_plot_all_2d(choice)
global ...
    data_train0 date_train0 ...
    data_test0 date_test0 ...
    step len idx_now ...
    M_train S_train ...
    L confidence ...
    P_train E_train ts_limit spe_limit ...
    output_train spe_train ts_train ...
    output_test spe_test ts_test ...
    plot_handles;
idx_now=min(max(idx_now,len),size(data_test0,1));
time_str=datestr(date_test0(idx_now),'yyyy-mm-dd HH:MM:SS');
axes(plot_handles);
switch choice
    case 1
        scatter(output_train(:,1),output_train(:,2),'.');
    case 2
        scatter(output_test(:,1),output_test(:,2),'.');
    case 3
        scatter(output_train(:,1),output_train(:,2),'.',output_test(:,1),output_test(:,2),'.');
end
hold on;
expression=strcat('t1^2/',num2str(E_train(1)),'+t2^2/',num2str(E_train(2)),'=',num2str(ts_limit));
x1_range=5+sqrt(ts_limit*E_train(1));
x2_range=5+sqrt(ts_limit*E_train(2));
ezplot(expression,[-x1_range,x1_range,-x2_range,x2_range]);
hold off;
axes(plot_handles);
axis equal;
axis([-x1_range,x1_range,-x2_range,x2_range]);
grid;
title(time_str);
xlabel('t_1');
ylabel('t_2');

function update_plot_3d(handles)
global ...
    data_train0 date_train0 ...
    data_test0 date_test0 ...
    step len idx_now ...
    M_train S_train ...
    L confidence ...
    P_train E_train ts_limit spe_limit ...
    output_train spe_train ts_train ...
    output_test spe_test ts_test ...
    plot_handles;
%数据处理
idx_now=min(max(idx_now,len),size(data_test0,1));
range=idx_now-len+1:idx_now;
output_show=output_test(range,1:3);
time_str=datestr(date_test0(idx_now),'yyyy-mm-dd HH:MM:SS');
set(handles.edit_time_now,'string',time_str);
set(handles.slider1,'value',idx_now/size(data_test0,1));
% cm=(linspace(0.7,0,length(range)).^0.3)';
% color_mat=[cm,cm/2,cm/2];
color_mat=parula(length(range));
xr=sqrt(E_train(1)*ts_limit);
yr=sqrt(E_train(2)*ts_limit);
zr=sqrt(E_train(3)*ts_limit);
[x, y, z] = ellipsoid(0,0,0,xr,yr,zr,30);
x1_range=2+sqrt(ts_limit*E_train(1));
x2_range=2+sqrt(ts_limit*E_train(2));
x3_range=2+sqrt(ts_limit*E_train(3));
angle_view=plot_handles.View;
%开始画图
axes(plot_handles);
scatter3(output_show(:,1),...
    output_show(:,2),...
    output_show(:,3),...
    linspace(10,50,length(range)),...
    color_mat,...
    'filled',...
    'MarkerEdgeColor',[.8,.8,.8]);
hold on;
surf(x, y, z,'EdgeColor','none','FaceAlpha',0.5,'FaceColor',[0.9,0.9,0.9]);
hold off;
axis equal;
axis([-x1_range,x1_range,-x2_range,x2_range,-x3_range,x3_range]);
view(angle_view);
title(strcat(time_str));
xlabel('t_1');
ylabel('t_2');
zlabel('t_3');
set(gca,'color',[0.4,0.4,0.4]);
drawnow;

function update_plot_all_3d(choice)
global ...
    data_train0 date_train0 ...
    data_test0 date_test0 ...
    step len idx_now ...
    M_train S_train ...
    L confidence ...
    P_train E_train ts_limit spe_limit ...
    output_train spe_train ts_train ...
    output_test spe_test ts_test ...
    plot_handles;
idx_now=min(max(idx_now,len),size(data_test0,1));
time_str=datestr(date_test0(idx_now),'yyyy-mm-dd HH:MM:SS');
xr=sqrt(E_train(1)*ts_limit);
yr=sqrt(E_train(2)*ts_limit);
zr=sqrt(E_train(3)*ts_limit);
[x, y, z] = ellipsoid(0,0,0,xr,yr,zr,30);
x1_range=2+sqrt(ts_limit*E_train(1));
x2_range=2+sqrt(ts_limit*E_train(2));
x3_range=2+sqrt(ts_limit*E_train(3));
angle_view=plot_handles.View;
%开始画图
axes(plot_handles);
switch choice
    case 1
        color_mat=parula(size(output_train,1));
        scatter3(output_train(:,1),output_train(:,2),output_train(:,3)...
            ,10 ...
            ,color_mat ...
            ,'filled'...
            ,'MarkerEdgeColor',[.7,.7,.7]);
    case 2
        color_mat=parula(size(output_test,1));
        scatter3(output_test(:,1),output_test(:,2),output_test(:,3)...
            ,10 ...
            ,color_mat ...
            ,'filled'...
            ,'MarkerEdgeColor',[.7,.7,.7]);
    case 3
        color_mat=parula(size(output_train,1));
        scatter3(output_train(:,1),output_train(:,2),output_train(:,3)...
            ,10 ...
            ,color_mat ...
            ,'filled'...
            ,'MarkerEdgeColor',[.7,.7,.7]);
        hold on;
        color_mat=parula(size(output_test,1));
        scatter3(output_test(:,1),output_test(:,2),output_test(:,3)...
            ,10 ...
            ,color_mat ...
            ,'filled'...
            ,'MarkerEdgeColor',[.7,.7,.7]);
end
hold on;
surf(x, y, z,'EdgeColor','none','FaceAlpha',0.5,'FaceColor',[0.9,0.9,0.9]);
hold off;
axes(plot_handles);
axis equal;
axis([-x1_range,x1_range,-x2_range,x2_range,-x3_range,x3_range]);
view(angle_view);
title(time_str);
xlabel('t_1');
ylabel('t_2');
zlabel('t_3');
set(gca,'color',[0.4,0.4,0.4]);
drawnow;

function update_plot_raw_data()
global ...
    data_train0 date_train0 ...
    data_test0 date_test0 ...
    data_fault0 date_fault0 ... 
    step len idx_now direction ...
    hotwind_bool_train0 hotwind_bool_test0 ...
    GL_no;
plotvariable;
ipt=[7;8;13;17;20;24];
figure;
for i1=1:6
    subplot(3,2,i1);
    plot(date_train0-date_train0(1),data_train0(:,ipt(i1))...
    ,date_test0-date_train0(1),data_test0(:,ipt(i1))...
    ,date_fault0-date_train0(1),data_fault0(:,ipt(i1)));
    title(commenVar{ipt(i1)});
end

% --- Outputs from this function are returned to the command line.
function varargout = m_visual_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function edit_date_begin_train_Callback(hObject, eventdata, handles)
% hObject    handle to edit_date_begin_train (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_date_begin_train as text
%        str2double(get(hObject,'String')) returns contents of edit_date_begin_train as a double


% --- Executes during object creation, after setting all properties.
function edit_date_begin_train_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_date_begin_train (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_date_end_train_Callback(hObject, eventdata, handles)
% hObject    handle to edit_date_end_train (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_date_end_train as text
%        str2double(get(hObject,'String')) returns contents of edit_date_end_train as a double


% --- Executes during object creation, after setting all properties.
function edit_date_end_train_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_date_end_train (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_date_begin_test_Callback(hObject, eventdata, handles)
% hObject    handle to edit_date_begin_test (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_date_begin_test as text
%        str2double(get(hObject,'String')) returns contents of edit_date_begin_test as a double


% --- Executes during object creation, after setting all properties.
function edit_date_begin_test_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_date_begin_test (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_date_end_test_Callback(hObject, eventdata, handles)
% hObject    handle to edit_date_end_test (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_date_end_test as text
%        str2double(get(hObject,'String')) returns contents of edit_date_end_test as a double


% --- Executes during object creation, after setting all properties.
function edit_date_end_test_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_date_end_test (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_len_Callback(hObject, eventdata, handles)
% hObject    handle to edit_len (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global len;
len=str2double(get(hObject,'String'));
update_plot(handles);
% Hints: get(hObject,'String') returns contents of edit_len as text
%        str2double(get(hObject,'String')) returns contents of edit_len as a double


% --- Executes during object creation, after setting all properties.
function edit_len_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_len (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global ...
    data_train0 date_train0 ...
    data_test0 date_test0 ...
    step len idx_now ...
    M_train S_train ...
    L confidence ...
    P_train E_train ts_limit spe_limit ...
    output_train spe_train ts_train ...
    output_test spe_test ts_test;
idx_now=floor(get(hObject,'Value')*size(data_test0,1));
update_plot(handles);
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in pb_control.
function pb_control_Callback(hObject, eventdata, handles)
% hObject    handle to pb_control (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global auto_plot_timer;
str1=get(handles.pb_control,'string');
if strcmp(str1,'start')
    set(auto_plot_timer,'UserData',handles);
    start(auto_plot_timer);
    set(handles.pb_control,'string','stop');
else
    stop(auto_plot_timer);
    set(handles.pb_control,'string','start');
end

% --- Executes on button press in pb_right.
function pb_right_Callback(hObject, eventdata, handles)
% hObject    handle to pb_right (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global step idx_now direction data_test0;
direction=1;
idx_now=idx_now+direction*step;
update_plot(handles);

% --- Executes on button press in pb_left.
function pb_left_Callback(hObject, eventdata, handles)
% hObject    handle to pb_left (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global step idx_now direction data_test0;
direction=-1;
idx_now=idx_now+direction*step;
update_plot(handles);




function edit_step_Callback(hObject, eventdata, handles)
% hObject    handle to edit_step (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global step;
step=str2double(get(hObject,'String'));

% Hints: get(hObject,'String') returns contents of edit_step as text
%        str2double(get(hObject,'String')) returns contents of edit_step as a double


% --- Executes during object creation, after setting all properties.
function edit_step_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_step (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_L_Callback(hObject, eventdata, handles)
% hObject    handle to edit_L (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global L;
L=str2double(get(hObject,'String'));
update_model(handles);
update_plot(handles);
% Hints: get(hObject,'String') returns contents of edit_L as text
%        str2double(get(hObject,'String')) returns contents of edit_L as a double


% --- Executes during object creation, after setting all properties.
function edit_L_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_L (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_confidence_Callback(hObject, eventdata, handles)
% hObject    handle to edit_confidence (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global confidence;
confidence=str2double(get(hObject,'String'));
update_model(handles);
update_plot(handles);
% Hints: get(hObject,'String') returns contents of edit_confidence as text
%        str2double(get(hObject,'String')) returns contents of edit_confidence as a double


% --- Executes during object creation, after setting all properties.
function edit_confidence_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_confidence (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_time_now_Callback(hObject, eventdata, handles)
% hObject    handle to edit_time_now (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_time_now as text
%        str2double(get(hObject,'String')) returns contents of edit_time_now as a double


% --- Executes during object creation, after setting all properties.
function edit_time_now_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_time_now (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pb_import_data.
function pb_import_data_Callback(hObject, eventdata, handles)
% hObject    handle to pb_import_data (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
update_data(handles)
update_model(handles);
update_plot(handles);



% --- Executes on button press in pb_fault_time.
function pb_fault_time_Callback(hObject, eventdata, handles)
% hObject    handle to pb_fault_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global GL_no
[filename, pathname] = uigetfile('*.mat','选择故障时间',fullfile('fault_time',num2str(GL_no)));
if ~isequal(filename,0)
	load(fullfile(pathname, filename));
	set(handles.edit_date_begin_train,'String',begin_train_str);
    set(handles.edit_date_end_train,'String',end_train_str);
    set(handles.edit_date_begin_test,'String',begin_test_str);
    set(handles.edit_date_end_test,'String',end_test_str);
end
guidata(hObject, handles);




function edit_GL_no_Callback(hObject, eventdata, handles)
% hObject    handle to edit_GL_no (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global GL_no;
GL_no=str2double(get(hObject,'String'));
% Hints: get(hObject,'String') returns contents of edit_GL_no as text
%        str2double(get(hObject,'String')) returns contents of edit_GL_no as a double


% --- Executes during object creation, after setting all properties.
function edit_GL_no_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_GL_no (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pb_train_set.
function pb_train_set_Callback(hObject, eventdata, handles)
% hObject    handle to pb_train_set (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% update_plot_all(true);
update_plot_all(1);

% --- Executes on button press in pb_test_set.
function pb_test_set_Callback(hObject, eventdata, handles)
% hObject    handle to pb_test_set (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% update_plot_all(false);
update_plot_all(2);


% --- Executes on button press in pb_train_test.
function pb_train_test_Callback(hObject, eventdata, handles)
% hObject    handle to pb_train_test (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
update_plot_all(3);

% --- Executes on button press in pb_plot.
function pb_plot_Callback(hObject, eventdata, handles)
% hObject    handle to pb_plot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
update_plot_raw_data();
