function varargout = project_mb(varargin)
% PROJECT_MB MATLAB code for project_mb.fig
%      PROJECT_MB, by itself, creates a new PROJECT_MB or raises the existing
%      singleton*.
%
%      H = PROJECT_MB returns the handle to a new PROJECT_MB or the handle to
%      the existing singleton*.
%
%      PROJECT_MB('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PROJECT_MB.M with the given input arguments.
%
%      PROJECT_MB('Property','Value',...) creates a new PROJECT_MB or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before project_mb_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to project_mb_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help project_mb

% Last Modified by GUIDE v2.5 29-Sep-2017 16:48:52

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @project_mb_OpeningFcn, ...
                   'gui_OutputFcn',  @project_mb_OutputFcn, ...
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


% --- Executes just before project_mb is made visible.
function project_mb_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to project_mb (see VARARGIN)

% Choose default command line output for project_mb
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
set(handles.axes_get,'visible','off');
set(handles.axes_get2,'visible','off');
set(handles.axes5,'visible','off');
set(handles.pushbutton_filtering,'enable','off');
% UIWAIT makes project_mb wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = project_mb_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton_start.
function pushbutton_start_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
BDaq = NET.addAssembly('Automation.BDaq4');
tm_axis =str2num(get(handles.multi_time,'string'));
global data_matrix;
data_matrix=zeros(2,128*tm_axis);
global count;
count=0;
% Configure the following three parameters before running the demo.
% The default device of project is demo device, users can choose other 
% devices according to their needs. 
deviceDescription = 'DemoDevice,BID#0'; 
startChannel = int32(0);
channelCount = int32(2);

% Step 1: Create a 'InstantAiCtrl' for Instant AI function.
instantAiCtrl = Automation.BDaq.InstantAiCtrl();

try
    % Step 2: Select a device by device number or device description and 
    % specify the access mode. In this example we use 
    % AccessWriteWithReset(default) mode so that we can fully control the 
    % device, including configuring, sampling, etc.
    instantAiCtrl.SelectedDevice = Automation.BDaq.DeviceInformation(...
        deviceDescription);
    data = NET.createArray('System.Double', channelCount);
    
    % Step 3: Read samples and do post-process, we show data here.
    errorCode = Automation.BDaq.ErrorCode();
    %s=getappdata(0,'sample_rate'); %获得采样率
    global T;
    s =str2num(get(handles.samplerate,'string'));
    T=double(1/s);
    global t;
    t = timer('TimerFcn', {@TimerCallback, instantAiCtrl, startChannel, ...
        channelCount, data,handles}, 'period', T, 'executionmode', 'fixedrate', ...
        'StartDelay', 1);  %间隔为T   
    start(t);
    %input('1');
    input('InstantAI is in progress...Press Enter key to quit!');
    %stop(t);
    %delete(t);
catch e
    % Something is wrong.
    if BioFailed(errorCode)    
        errStr = 'Some error occurred. And the last error code is ' ... 
            + errorCode.ToString();
    else
        errStr = e.message;
    end
    disp(errStr); 
end

% Step 4: Close device and release any allocated resource.
instantAiCtrl.Dispose();


function result = BioFailed(errorCode)

result =  errorCode < Automation.BDaq.ErrorCode.Success && ...
    errorCode >= Automation.BDaq.ErrorCode.ErrorHandleNotValid;


function TimerCallback(obj, event, instantAiCtrl, startChannel, ...
    channelCount, data,handles)
global tm_axis;
tm_axis =str2num(get(handles.multi_time,'string'));
global count;
if count <= 128*tm_axis   %一张图中显示的点数为128个
    count=count+1;
end
errorCode = instantAiCtrl.Read(startChannel, channelCount, data); 
if BioFailed(errorCode)
    throw Exception();
end
%fprintf('\n');

data0=data.Get(0); %channel 0数据
data1=data.Get(1); %channel 1
%fprintf('%10f',data0);
%数据保存在data_matrix中
global data_matrix;
if count <= 128*tm_axis
    data_matrix(1,count)=data0;
    data_matrix(2,count)=data1;
else 
    data_matrix(1,1:128*tm_axis-1)=data_matrix(1,2:128*tm_axis);
    data_matrix(2,1:128*tm_axis-1)=data_matrix(2,2:128*tm_axis);
    data_matrix(1,128*tm_axis)=data0;
    data_matrix(2,128*tm_axis)=data1;
end
%动态地画出图形,先获取坐标轴的倍数值
v_axis =str2num(get(handles.multi_volt,'string'));
global T;
if count <= 128*tm_axis
    if get(handles.rb_chnl0,'value')
        axes(handles.axes_get);
        plot(handles.axes_get,1*T:1*T:count*T,data_matrix(1,1:1:count)); 
        axis([1*tm_axis*T 128*tm_axis*T -1*v_axis 1*v_axis]);  
        set(gca,'XTick',[tm_axis*T:T*50:128*tm_axis*T]) ;
    end
    if get(handles.rb_chnl1,'value')
        axes(handles.axes_get2);
        plot(handles.axes_get2,1*T:1*T:count*T,data_matrix(2,1:1:count));
        axis([1*tm_axis*T 128*tm_axis*T -1*v_axis 1*v_axis]);  
        set(gca,'XTick',[tm_axis*T:T*50:128*tm_axis*T]) ;
    end
else
    if get(handles.rb_chnl0,'value')
        axes(handles.axes_get);
        plot(handles.axes_get,1*T:1*T:128*tm_axis*T,data_matrix(1,1:1:128*tm_axis));
        axis([1*tm_axis*T 128*tm_axis*T -1*v_axis 1*v_axis]);  
        set(gca,'XTick',[tm_axis*T:T*50:128*tm_axis*T]) ;
    end
    if get(handles.rb_chnl1,'value')
        axes(handles.axes_get2);
        plot(handles.axes_get2,1*T:1*T:128*tm_axis*T,data_matrix(2,1:1:128*tm_axis));
        axis([1*tm_axis*T 128*tm_axis*T -1*v_axis 1*v_axis]);  
        set(gca,'XTick',[tm_axis*T:T*50:128*tm_axis*T]) ;
    end
end

% --- Executes on button press in pushbutton_sdata.
function pushbutton_sdata_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_sdata (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global data_matrix;
csvwrite('data0.mat',data_matrix(1,1:end));
csvwrite('data1.mat',data_matrix(2,1:end));


function samplerate_Callback(hObject, eventdata, handles)
% hObject    handle to samplerate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of samplerate as text
%        str2double(get(hObject,'String')) returns contents of samplerate as a double


% --- Executes during object creation, after setting all properties.
function samplerate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to samplerate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function multi_time_Callback(hObject, eventdata, handles)
% hObject    handle to multi_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of multi_time as text
%        str2double(get(hObject,'String')) returns contents of multi_time as a double


% --- Executes during object creation, after setting all properties.
function multi_time_CreateFcn(hObject, eventdata, handles)
% hObject    handle to multi_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function multi_volt_Callback(hObject, eventdata, handles)
% hObject    handle to multi_volt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of multi_volt as text
%        str2double(get(hObject,'String')) returns contents of multi_volt as a double


% --- Executes during object creation, after setting all properties.
function multi_volt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to multi_volt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_stop.
function pushbutton_clear_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
axes(handles.axes_get) ;
cla reset
axes(handles.axes_get2);
cla reset
set(handles.axes_get,'Visible','off');
set(handles.axes_get2,'Visible','off');

% --- Executes on key press with focus on pushbutton_start and none of its controls.
function pushbutton_start_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton_start (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
global t;
stop(t);
delete(t);


% --- Executes on button press in rb_chnl0.
function rb_chnl0_Callback(hObject, eventdata, handles)
% hObject    handle to rb_chnl0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rb_chnl0


% --- Executes on button press in rb_chnl1.
function rb_chnl1_Callback(hObject, eventdata, handles)
% hObject    handle to rb_chnl1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rb_chnl1


% --- Executes on button press in pushbutton_stop.
function pushbutton_stop_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global t;
stop(t);
delete(t);


% --- Executes on button press in pushbutton_PickPoints.
function pushbutton_PickPoints_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_PickPoints (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[x,y] = ginput(1);
global data_matrix;
global T;
rx=round(x/T);
ry0=data_matrix(1,rx);
ry1=data_matrix(2,rx);
set(handles.edit5,'string',num2str(rx*T));
if get(handles.rb_chnl0,'value')
    set(handles.edit6,'string',num2str(ry0));
end
if get(handles.rb_chnl1,'value')
    set(handles.edit9,'string',num2str(ry1));
end


function edit5_Callback(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit5 as text
%        str2double(get(hObject,'String')) returns contents of edit5 as a double


% --- Executes during object creation, after setting all properties.
function edit5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit6_Callback(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit6 as text
%        str2double(get(hObject,'String')) returns contents of edit6 as a double


% --- Executes during object creation, after setting all properties.
function edit6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_fft.
function pushbutton_fft_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_fft (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global d;
global T;
global tm_axis;
fs=1/T;
xfft = fft(d);
y=xfft/(128*tm_axis)*2;
f = fs/2*linspace(0,1,128*tm_axis/2);
plot(handles.axes5,f,abs(y(128*tm_axis/2+1:128*tm_axis)));

% --- Executes on button press in pushbutton_amplify.
function pushbutton_amplify_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_amplify (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global n;
global d;
global T;
global tm_axis;
global v_axis;
y=n*d;
axes(handles.axes5);
plot(handles.axes5,1*T:1*T:128*tm_axis*T,y(1:1:128*tm_axis));
% plot(handles.axes5,1*T:1*T:128*tm_axis*T,y(1:1:128*tm_axis),'*-');
%axis([1*tm_axis*T 128*tm_axis*T  -n*v_axis  n*v_axis]);  
set(gca,'XTick',[tm_axis*T:T*50:128*tm_axis*T]) ;




function edit_amplifytime_Callback(amptime, eventdata, handles)
% hObject    handle to edit_amplifytime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_amplifytime as text
%        str2double(get(hObject,'String')) returns contents of edit_amplifytime as a double
global n;
n=str2double(get(amptime,'string'));


% --- Executes during object creation, after setting all properties.
function edit_amplifytime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_amplifytime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_filtertype.
function popupmenu_filtertype_Callback(filterType, eventdata, handles)
% hObject    handle to popupmenu_filtertype (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_filtertype contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_filtertype
global FILTER;
handles.FilterType=filterType;
Lisst=get(filterType,'String');
Val=get(filterType,'Value');
FILTER=Lisst{Val};
set(handles.pushbutton_filtering,'enable','on');

% --- Executes during object creation, after setting all properties.
function popupmenu_filtertype_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_filtertype (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_cutfrequency_Callback(freqz, eventdata, handles)
% hObject    handle to edit_cutfrequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_cutfrequency as text
%        str2double(get(hObject,'String')) returns contents of edit_cutfrequency as a double
global Fc;
Fc=str2double(get(freqz,'string'));


% --- Executes during object creation, after setting all properties.
function edit_cutfrequency_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_cutfrequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_filtering.
function pushbutton_filtering_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_filtering (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global ftd;
global T;
global tm_axis;
global FILTER;
global Fc;
global d;
fm=1/(T*2);
switch FILTER
    case 'lowpass'
        Fp = Fc/fm; Fst = Fp+0.01; Ap = 1; Ast = 60;
        D = fdesign.lowpass('Fp,Fst,Ap,Ast',Fp,Fst,Ap,Ast);%lowpass
        fi = design(D);
        ftd = filter(fi,d);
    case 'highpass'
        Fst = Fc/fm; Fp = Fst+0.01; Ast = 1e-3; Ap = 1e-2;
        D = fdesign.highpass('Fst,Fp,Ast,Ap',Fst,Fp,Ast,Ap);%highpass
        fi = design(D);
        ftd = filter(fi,d);
    otherwise
        ftd = d;
end
axes(handles.axes5);
plot(handles.axes5,1*T:1*T:128*tm_axis*T,ftd(1:1:128*tm_axis));
%axis([1*tm_axis*T 128*tm_axis*T  -n*v_axis  n*v_axis]);  
set(gca,'XTick',[tm_axis*T:T*50:128*tm_axis*T]) ;


% --- Executes on button press in pushbutton_Openfile.
function pushbutton_Openfile_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_Openfile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global d;
global T;
global tm_axis;
[fn,pn,fi]= uigetfile('*.mat', 'Choose File');
path=[pn fn];
d=load (path, '-ascii');
axes(handles.axes5);
plot(handles.axes5,1*T:1*T:128*tm_axis*T,d);
%axis([1*tm_axis*T 128*tm_axis*T  -n*v_axis  n*v_axis]);  
set(gca,'XTick',[tm_axis*T:T*50:128*tm_axis*T]) ;



function edit9_Callback(hObject, eventdata, handles)
% hObject    handle to edit9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit9 as text
%        str2double(get(hObject,'String')) returns contents of edit9 as a double


% --- Executes during object creation, after setting all properties.
function edit9_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
