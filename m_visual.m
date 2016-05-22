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

% Last Modified by GUIDE v2.5 21-May-2016 21:48:09

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
    step len idx_now direction;
No=[2,3,5];
GL=[7,1,5];
ipt=[7;8;13;17;20;24];
plotvariable;
gl_no=2;%高炉编号
filepath=strcat('..\GL_data\',num2str(No(gl_no)),'\');
hours=24*5;
minutes=30;
opt=struct(...
    'date_str_begin','2013-02-19 23:57', ... %开始时间
    'date_str_end','2013-02-25 16:45:14', ...   %结束时间
    'len',360*hours, ...%计算PCA所用时长范围
    'step',6*minutes ...
    );

load(strcat(filepath,'data.mat'));
data0=data0(:,commenDim{GL(gl_no)});% 选取共有变量

idx_begin_train=find(date0>datenum(get(handles.edit_date_begin_train,'string')),1);
idx_end_train=find(date0>datenum(get(handles.edit_date_end_train,'string')),1);
idx_begin_test=find(date0>datenum(get(handles.edit_date_begin_test,'string')),1);
idx_end_test=find(date0>datenum(get(handles.edit_date_end_test,'string')),1);
data_train0=data0(idx_begin_train:idx_end_train,:);
date_train0=date0(idx_begin_train:idx_end_train,:);
data_test0=data0(idx_begin_test:idx_end_test,:);
date_test0=date0(idx_begin_test:idx_end_test,:);
len=str2double(get(handles.edit_len,'string'));
step=str2double(get(handles.edit_step,'string'));
idx_now=1;
direction=1;

function update_model(handles)
global ...
    data_train0 date_train0 ...
    data_test0 date_test0 ...
    step len idx_now ...
    M_train S_train ...
    L confidence ...
    P_train E_train ts_limit spe_limit ...
    output_train spe_train ts_train ...
    output_test spe_test ts_test;
M_train=mean(data_train0);
S_train=std(data_train0);
data_train_sd=(data_train0-ones(size(data_train0,1),1)*M_train)./(ones(size(data_train0,1),1)*S_train);
data_test_sd=(data_test0-ones(size(data_test0,1),1)*M_train)./(ones(size(data_test0,1),1)*S_train);
L=str2double(get(handles.edit_L,'string'));
confidence=str2double(get(handles.edit_confidence,'string'));
[P_train,E_train,spe_limit,ts_limit]=f_pca_model(data_train_sd,L,confidence);
[output_train,spe_train,ts_train]=f_pca_indicater(data_train_sd,P_train,E_train,L);
[output_test,spe_test,ts_test]=f_pca_indicater(data_test_sd,P_train,E_train,L);

function update_plot(handles)
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
% scatter(handles.axes1,output_train(:,1),output_train(:,2),'.');
% scatter(handles.axes1,output_test(:,1),output_test(:,2),'.');
axes(plot_handles);
scatter(output_show(:,1),...
    output_show(:,2),...
    linspace(10,50,length(range)),...
    (linspace(0.7,0,length(range)).^0.3)'*ones(1,3),...
    'filled');

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
drawnow;

function update_timer(obj,eventdata)
global idx_now direction step;
handles=obj.UserData;
idx_now=idx_now+direction*step;
update_plot(handles);

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

