function varargout = ClassicalConditioning(varargin)
% CLASSICALCONDITIONING MATLAB code for ClassicalConditioning.fig
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ClassicalConditioning_OpeningFcn, ...
                   'gui_OutputFcn',  @ClassicalConditioning_OutputFcn, ...
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


function ClassicalConditioning_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;

% Set timer
handles.timer = timer(...
    'ExecutionMode', 'fixedSpacing', ...
    'BusyMode', 'drop', ...
    'Period', 0.1, ...
    'TimerFcn', {@ArduinoDataReader,hObject});

% Set serial
currentPort = setxor(getAvailableComPort, 'COM1');
if isempty(currentPort)
    set(handles.connectionText,'String','No available serial ports!');
    set(handles.connectionText,'BackgroundColor','r');
else
    a = instrfindall;
    if ~isempty(a);
        fclose(a);
        delete(a);
    end
    handles.arduino = serial(currentPort{end}, 'Baudrate', 115200, 'Timeout', 10);
    fopen(handles.arduino);
    
    set(handles.connectionText,'String',['Connected to ',currentPort{end}]);
    set(handles.connectionText,'BackgroundColor','g');
    set(handles.stopButton, 'Enable', 'off');
    set(handles.startButton, 'Enable', 'on');
end

% Graph
nCue = 4;
set(handles.aBar,'TickDir','out','FontSize',8, ...
    'XLim',[0.5 nCue+0.5],'XTick',1:4,'XTickLabel',{'A','B','C','D'}, ...
    'YLim',[0 1], 'YTick',[0 1]);
xlabel(handles.aBar,'Cue');
ylabel(handles.aBar,'Licking number');

hold(handles.aRaster,'on');
plot(handles.aRaster,[0.5 0.5],[0 1000],'LineWidth',1,'Color',[0.8 0.8 0.8]);
plot(handles.aRaster,[1.5 1.5],[0 1000],'LineWidth',1,'Color',[0.8 0.8 0.8]);
plot(handles.aRaster,[4 4],[0 1000],'LineWidth',1,'Color',[0.8 0.8 0.8]);
set(handles.aRaster,'TickDir','out','FontSize',8, ...
    'XLim',[0 10],'XTIck',[0 0.5 1.5 4 10],...
    'YLim',[0 10],'YTick',0:10,'YTickLabel',{0,[],[],[],[],[],[],[],[],[],10});
xlabel(handles.aRaster,'Time (s)');
ylabel(handles.aRaster,'Trial');

guidata(hObject, handles);


function varargout = ClassicalConditioning_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;


function startButton_Callback(hObject, eventdata, handles)
% Get Trial Information
trialType = get(handles.trialType, 'Value');
switch trialType
    case 1
        nCue = 1;
        StartCue = 0;
    case 2
        nCue = 2;
        StartCue = 0;
    case 3
        nCue = 2;
        StartCue = 0;
    case 4
        nCue = 4;
        StartCue = 0;
        set(handles.nTrial,'String','320');
end
nTrial = str2double(get(handles.nTrial, 'String'));
ITI = str2double(get(handles.ITI, 'String'));

% Reset figure
cla(handles.aRaster);
hold(handles.aRaster,'on');
handles.bar.s0 = bar(handles.aRaster,0.25,1000,'BarWidth',0.5,'LineStyle','none','FaceColor',[1 1 0.4],'Visible','off');
handles.bar.s1 = bar(handles.aRaster,1,1000,'BarWidth',1,'LineStyle','none','FaceColor',[1 1 0.4],'Visible','off');
handles.bar.s2 = bar(handles.aRaster,2.75,1000,'BarWidth',2.5,'LineStyle','none','FaceColor',[1 1 0.4],'Visible','off');
handles.bar.s3 = bar(handles.aRaster,4+(ITI+1)/2,1000,'BarWidth',ITI+1,'LineStyle','none','FaceColor',[1 1 0.4],'Visible','off');
plot(handles.aRaster,[0.5 0.5],[0 1000],'LineWidth',1,'Color',[0.8 0.8 0.8]);
plot(handles.aRaster,[1.5 1.5],[0 1000],'LineWidth',1,'Color',[0.8 0.8 0.8]);
plot(handles.aRaster,[4 4],[0 1000],'LineWidth',1,'Color',[0.8 0.8 0.8]);
set(handles.aRaster,'TickDir','out','FontSize',8, ...
    'XLim',[0 ITI+5],'XTIck',[0 0.5 1.5 4 ITI+5],...
    'YLim',[0 10],'YTick',0:10,'YTickLabel',{0,[],[],[],[],[],[],[],[],[],10});
xlabel(handles.aRaster,'Time (s)');
ylabel(handles.aRaster,'Trial');

set(handles.aBar,'XLim',[0.5+StartCue StartCue+nCue+0.5]);

% Reset variables
set(handles.iTrial, 'String', '0');
set(handles.nReward, 'String', '0');
set(handles.cue0, 'String', '0');
set(handles.cue0, 'BackgroundColor', 'w');
set(handles.cue1, 'String', '0');
set(handles.cue1, 'BackgroundColor', 'w');
set(handles.cue2, 'String', '0');
set(handles.cue2, 'BackgroundColor', 'w');
set(handles.cue3, 'String', '0');
set(handles.cue3, 'BackgroundColor', 'w');
set(handles.reward0, 'String', '0');
set(handles.reward0, 'BackgroundColor', 'w');
set(handles.reward1, 'String', '0');
set(handles.reward1, 'BackgroundColor', 'w');
set(handles.reward2, 'String', '0');
set(handles.reward2, 'BackgroundColor', 'w');
set(handles.reward3, 'String', '0');
set(handles.reward3, 'BackgroundColor', 'w');
set(handles.omit0, 'String', '0');
set(handles.omit0, 'BackgroundColor', 'w');
set(handles.omit1, 'String', '0');
set(handles.omit1, 'BackgroundColor', 'w');
set(handles.omit2, 'String', '0');
set(handles.omit2, 'BackgroundColor', 'w');
set(handles.omit3, 'String', '0');
set(handles.omit3, 'BackgroundColor', 'w');

% Data variables
handles.data.stateTime = zeros(nTrial, 5);
handles.data.cue = zeros(nTrial, 1);
handles.data.reward = zeros(nTrial, 1);
handles.data.lickNum = zeros(nTrial, 1);
handles.data.lickTime = [];

% Start reading serial
fprintf(handles.arduino, '%s', ['t', num2str(nTrial)]);
pause(0.25);
fprintf(handles.arduino, '%s', ['i', num2str(ITI)]);
pause(0.25);
fprintf(handles.arduino, '%s', ['s', num2str(trialType-1)]);
set(handles.mouseName, 'Enable', 'off');
set(handles.nTrial, 'Enable', 'off');
set(handles.ITI, 'Enable', 'off');
set(handles.trialType, 'Enable', 'off');
set(handles.startButton, 'Enable', 'off');
set(handles.stopButton, 'Enable', 'on');
set(handles.valve, 'Enable', 'off');

fileDir = 'D:\Data\Classical_conditioning\';
handles.fileName = [fileDir get(handles.mouseName,'String'), '_', num2str(clock, '%4d%02d%02d_%02d%02d%02.0f')];

pause(2);
tic;
start(handles.timer);

guidata(hObject,handles);


function stopButton_Callback(hObject, eventdata, handles)
fwrite(handles.arduino,'e');


function nTrial_Callback(hObject, eventdata, handles)

function nTrial_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function iTrial_Callback(hObject, eventdata, handles)

function iTrial_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function message_Callback(hObject, eventdata, handles)
str = get(handles.message,'String');
fprintf(handles.arduino, '%s', str);

function message_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function mouseName_Callback(hObject, eventdata, handles)

function mouseName_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function trialType_Callback(hObject, eventdata, handles)

function trialType_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function mainFigure_CloseRequestFcn(hObject, eventdata, handles)
t = timerfindall;
if ~isempty(t)
    stop(t);
    delete(t);
end

a = instrfindall;
if ~isempty(a)
    fclose(a);
    delete(a);
end

delete(hObject);

function valve_Callback(hObject, eventdata, handles)
fwrite(handles.arduino,'w');



function ITI_Callback(hObject, eventdata, handles)
% hObject    handle to ITI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ITI as text
%        str2double(get(hObject,'String')) returns contents of ITI as a double


% --- Executes during object creation, after setting all properties.
function ITI_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ITI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
