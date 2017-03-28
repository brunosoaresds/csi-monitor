function varargout = realtime_view(varargin)
% REALTIME_VIEW MATLAB code for realtime_view.fig
%      REALTIME_VIEW, by itself, creates a new REALTIME_VIEW or raises the existing
%      singleton*.
%
%      H = REALTIME_VIEW returns the handle to a new REALTIME_VIEW or the handle to
%      the existing singleton*.
%
%      REALTIME_VIEW('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in REALTIME_VIEW.M with the given input arguments.
%
%      REALTIME_VIEW('Property','Value',...) creates a new REALTIME_VIEW or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before realtime_view_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to realtime_view_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help realtime_view

% Last Modified by GUIDE v2.5 27-Mar-2017 18:04:30

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @realtime_view_OpeningFcn, ...
                   'gui_OutputFcn',  @realtime_view_OutputFcn, ...
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

% --- Executes just before realtime_view is made visible.
function realtime_view_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to realtime_view (see VARARGIN)

% Start update job
handles.timer = timer('ExecutionMode','fixedRate', ...
                      'Period', 2, ...
                      'TimerFcn', {@requestRealTimeData, handles});


% Choose default command line output for realtime_view
handles.output = hObject;
handles.filterNum = 0;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes realtime_view wait for user response (see UIRESUME)
% uiwait(handles.csi_realtime_frame);

        
% --- Outputs from this function are returned to the command line.
function varargout = realtime_view_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes during object deletion, before destroying properties.
function csi_realtime_frame_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to csi_realtime_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    disp('Closing application...');
    stop(handles.timer);
    
    if isfield(handles, 'csiManagerPid')
        pid = handles.csiManagerPid;
        command = ['kill -9 ', pid];
        system(command);
    end

% --- Executes during object creation, after setting all properties.
function csi_receiver_CreateFcn(hObject, eventdata, handles)
% hObject    handle to csi_receiver (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function csi_configure_Callback(hObject, eventdata, handles)
    if strcmp(get(hObject, 'Tag'), 'csi_receiver')
        globalSocket = 'csiReceiverSocket';
        statusObjTag = 'csi_receiver_status';
    else
        globalSocket = 'csiSenderSocket';
        statusObjTag = 'csi_sender_status';
    end
    
    inputData = strsplit(get(hObject, 'String'), ':');
    inputDataSize = size(inputData);
    if inputDataSize(1,2) ~= 2
        ip = '127.0.0.1';
        port = 3000;
    else
        ip = inputData{1,1};
        try
            port = str2double(inputData{1,2});
        catch ME
            port = 3000;
        end
    end
    
    try
        t = tcpip(ip, port);
        t.InputBufferSize = 1501000;
        t.Timeout = 1;
        fopen(t);
        connectionStatus = t.Status;
    catch ME
        disp('could not connect to the sender');
        connectionStatus = 'closed';
    end
    
    statusObj = getfield(handles, statusObjTag);
    if strcmp(connectionStatus, 'open') 
        set(statusObj, 'ForegroundColor', hex2rgb('266236'));
        set(statusObj, 'String', 'OK');
        
        % save status
        handles = setfield(handles, globalSocket, 1);
    else
        set(statusObj, 'ForegroundColor', 'red');
        set(statusObj, 'String', 'Not ok');
        
        % remove socket to the system, if exists.
        if isfield(handles, globalSocket)
            handles = rmfield(handles, globalSocket);
        end
    end
    
    fclose(t);
    guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function csi_sender_CreateFcn(hObject, eventdata, handles)
% hObject    handle to csi_sender (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function handles = configureCsiManager(hObject, eventdata, handles)
    handles = guidata(handles.csi_realtime_frame);
    
    if isfield(handles, 'csiData') == 0
        handles = setfield(handles, 'csiData', {});
        guidata(handles.csi_realtime_frame, handles);
    end
    
    % if is not connected to csi manager, start and connect
    if isfield(handles, 'serverConnection') == 0
        disp('starting CSI MANAGER...');
        csiManagerPort = randi([5000 6000], 1, 1);
        path = strrep(which(mfilename), [mfilename,'.m'], '');

        command = [path, 'CsiManager/Main.py --port=', num2str(csiManagerPort), ...
        ' --receiver=', get(handles.csi_receiver, 'String'), ...
        ' --sender=', get(handles.csi_sender, 'String'), ...
        ' & echo $!'];
        [~, pid] = system(command);

        % Save the pid of CSI MANAGER
        handles = setfield(handles, 'csiManagerPid', pid);
        guidata(handles.csi_realtime_frame, handles);

        pause(5);
        
        disp('Connecting to server...')
        try
            t = tcpip('localhost', csiManagerPort);
            t.InputBufferSize = 1024;
            t.Timeout = 1;
            fopen(t);
            connectionStatus = t.Status;
        catch ME
            disp(ME);
            disp('could not connect to csi manager');
            connectionStatus = 'closed';
        end
        
        if strcmp(connectionStatus, 'open')
            disp('sending START_SERVER');
            try
                fwrite(t, 'START_SERVER');
            catch ME
                disp(ME);
                disp('could not send START_SERVER command...');
                fclose(t);
            end
            handles = setfield(handles, 'serverConnection', t);
            guidata(handles.csi_realtime_frame, handles);
        else
            msgbox('Could not start real time collection, check sender and receiver configurations.', ...
                'Configuration Error', 'error');
        end
    end

function configureSender(hObject, eventdata, handles)
    handles = guidata(handles.csi_realtime_frame);
    connection = handles.serverConnection;
    
    secPackets = strcat(get(handles.sender_packets, 'String'), '/', ...
        get(handles.sender_seconds, 'String'));
    try
        fwrite(connection, 'SEND_PACKET');
        fwrite(connection, secPackets);
    catch ME
        disp(ME);
    end
    
function requestRealTimeData(hObject, eventdata, handles)
    handles = guidata(handles.csi_realtime_frame);
    
    connection = handles.serverConnection;
    fwrite(connection, 'REQUEST_FILES');
    files = fread(connection, 1024);
    try
        str = native2unicode(files).';
        files = strsplit(str, ',');
    catch ME
        files = [];
    end
    
    csiData = handles.csiData;    
    windowSize = str2num(get(handles.graph_window, 'String')) - 1;
    for i=1:numel(files)
        try
            csi = read_log_file(files{i});
            csi = get_csi_streams(csi, 1, 1);
        catch ME
            csi = zeros(56,1);
        end
        csiDataSize = size(csiData);
        csiDataSize = csiDataSize(1,2);
        if csiDataSize > windowSize
            csiData = csiData(:,[2:windowSize]);
        end
        csiData{1,end+1} = csi;
    end
    
    handles = setfield(handles, 'csiData', csiData);
    guidata(handles.csi_realtime_frame, handles);
    
    csiDataSize = size(csiData);
    csiDataSize = csiDataSize(1,2);
    
    if csiDataSize > 0
        updateGraph(handles)
    end
    
function updateGraph(handles)
    if isfield(handles, 'csiData') ~= 1 || isempty(handles.csiData)
        return;
    end
    
    % get real data
    csiData = translateCsiData(handles.csiData, handles);
    csiDataSize = size(csiData);
    csiDataSize = csiDataSize(1,2);
    windowSize = str2num(get(handles.graph_window, 'String'));
    remainingSize = windowSize - csiDataSize;
    
    plotData = filter_subcarriers_data(csiData, get(handles.subcarriers, 'Value'));
    if remainingSize > 0
        subCount = size(plotData);
        subCount = subCount(1,1);
        remainingData = zeros(subCount, remainingSize);
        plotData = cat(2, remainingData, plotData);
        x = linspace(1, remainingSize, remainingSize);
    else
        x = [];
    end
    
    windowPktCount = 0;
    filledSecsCount = 0;
    % Create X vector
    for i=1:csiDataSize
        timeSec = i + remainingSize - 1;
        secData = csiData{1,i};
        secDataSize = size(secData);
        secDataSize = secDataSize(1,2);
        secX = timeSec + ((1:secDataSize)/secDataSize);
        x = cat(2,x,secX);
        
        % Statistical data
        if secDataSize > 1
            windowPktCount = windowPktCount + secDataSize;
            filledSecsCount = filledSecsCount + 1;
        end
    end
   
    lastSecCount = size(csiData{1,csiDataSize});
    lastSecCount = lastSecCount(1,2);
    if lastSecCount == 1 && csiData{1,csiDataSize}(1,1) == 0
        lastSecCount = 0;
    end
    % Update statistic panel
    set(handles.window_pkt_count, 'String', windowPktCount);
    set(handles.pkt_count_averrage, 'String', sprintf('%0.2f', ...
        (windowPktCount/filledSecsCount)));
    set(handles.last_second_pkt_count, 'String', lastSecCount);
    
    % Update graph
    fnctHandler = get(handles.csi_monitoring, 'ButtonDownFcn');
    plot(handles.csi_monitoring, x, plotData.');
%     ylim(handles.csi_monitoring, [-120, 120]);
    xlim(handles.csi_monitoring, [1, windowSize]);
    xlabel(handles.csi_monitoring, 'Time window (s)');
    set(handles.csi_monitoring, 'ButtonDownFcn', fnctHandler);

function [data] = translateCsiData(csiData, handles)
    data = cellfun(@abs, csiData, 'UniformOutput', false);
    switch handles.filterNum
        case 1
            data = cellfun(@butter_filter, data, 'UniformOutput', false);
        case 2
            data = cellfun(@pca_filter, data, 'UniformOutput', false);
    end

% filter subcarriers plot data
function [filteredData] = filter_subcarriers_data(csiData, subcarriers)
    csiArray = cell2mat(csiData);
    filteredData = csiArray(subcarriers,:);
    
% --- Executes on button press in start_stop_btn.
function start_stop_btn_Callback(hObject, eventdata, handles)
% hObject    handle to start_stop_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if strcmp(get(hObject, 'String'), 'Start')
        if isfield(handles, 'csiReceiverSocket') == 0 || ...
            isfield(handles, 'csiSenderSocket') == 0
            msgbox('Could not start real time collection, check sender and receiver configurations.', ...
                'Configuration Error', 'error');
            return;
        end
        
        handles = configureCsiManager(hObject, eventdata, handles);
        configureSender(hObject, eventdata, handles);
        start(handles.timer);
        
        set(hObject, 'String', 'Stop');
        set(hObject, 'TooltipString', 'Stops CSI real time collection');
        set(handles.csi_sender, 'enable', 'off');
        set(handles.csi_receiver, 'enable', 'off');
        set(handles.sender_seconds, 'enable', 'off');
        set(handles.sender_packets, 'enable', 'off');
        set(handles.graph_window, 'enable', 'off');
        set(handles.rx, 'enable', 'off');
        set(handles.tx, 'enable', 'off');
        set(handles.export_btn, 'enable', 'off');
        clear_btn_Callback(hObject, eventdata, handles);
    else
        stop(handles.timer);
        set(hObject, 'String', 'Start');
        set(hObject, 'TooltipString', 'Starts CSI real time collection');
        set(handles.csi_sender, 'enable', 'on');
        set(handles.csi_receiver, 'enable', 'on');
        set(handles.sender_seconds, 'enable', 'on');
        set(handles.sender_packets, 'enable', 'on');
        set(handles.graph_window, 'enable', 'on');
        set(handles.rx, 'enable', 'on');
        set(handles.tx, 'enable', 'on');
        
        % SEND stop packets to the sender
        stop_sender(handles);
        
        % Enable export data button only if have data to export
        if isfield(handles, 'csiData') && isempty(handles.csiData) ~= 1
            set(handles.export_btn, 'enable', 'on');
        end
    end

% --- Executes on button press in clear_btn.
function clear_btn_Callback(hObject, eventdata, handles)
% hObject    handle to clear_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    handles.csiData = {};
    fnctHandler = get(handles.csi_monitoring, 'ButtonDownFcn');
    cla(handles.csi_monitoring);
    set(handles.csi_monitoring, 'ButtonDownFcn', fnctHandler);
    set(handles.window_pkt_count, 'String', 0);
    set(handles.pkt_count_averrage, 'String', 0);
    set(handles.last_second_pkt_count, 'String', 0);
    set(handles.export_btn, 'enable', 'off');
    guidata(hObject, handles);

% --- Sends the stop packet sending to the server
function stop_sender(handles)
    handles = guidata(handles.csi_realtime_frame);
    connection = handles.serverConnection;
    try
        fwrite(connection, 'STOP_SENDING');
    catch ME
        disp(ME);
    end

% --- Executes on selection change in subcarriers.
function subcarriers_Callback(hObject, eventdata, handles)
% hObject    handle to subcarriers (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns subcarriers contents as cell array
%        contents{get(hObject,'Value')} returns selected item from subcarriers
    if strcmp(get(handles.start_stop_btn, 'String'), 'Start')
        updateGraph(handles);
    end

% --- Executes during object creation, after setting all properties.
function subcarriers_CreateFcn(hObject, eventdata, handles)
% hObject    handle to subcarriers (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end 
    
    set(hObject, 'Max', 56, 'Min', 1);
    set(hObject, 'Value', linspace(1, 56, 56));

    
function rx_Callback(hObject, eventdata, handles)
% hObject    handle to rx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of rx as text
%        str2double(get(hObject,'String')) returns contents of rx as a double


% --- Executes during object creation, after setting all properties.
function rx_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function tx_Callback(hObject, eventdata, handles)
% hObject    handle to tx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tx as text
%        str2double(get(hObject,'String')) returns contents of tx as a double


% --- Executes during object creation, after setting all properties.
function tx_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function sender_seconds_Callback(hObject, eventdata, handles)
% hObject    handle to sender_seconds (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sender_seconds as text
%        str2double(get(hObject,'String')) returns contents of sender_seconds as a double


% --- Executes during object creation, after setting all properties.
function sender_seconds_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sender_seconds (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function sender_packets_Callback(hObject, eventdata, handles)
% hObject    handle to sender_packets (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sender_packets as text
%        str2double(get(hObject,'String')) returns contents of sender_packets as a double


% --- Executes during object creation, after setting all properties.
function sender_packets_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sender_packets (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function graph_window_Callback(hObject, eventdata, handles)
% hObject    handle to graph_window (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of graph_window as text
%        str2double(get(hObject,'String')) returns contents of graph_window as a double


% --- Executes during object creation, after setting all properties.
function graph_window_CreateFcn(hObject, eventdata, handles)
% hObject    handle to graph_window (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when selected object is changed in filters_painel.
function filters_painel_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in filters_painel 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
    filter = get(hObject, 'String');
    switch filter
        case 'Butterworth'
            filterNum = 1;
        case 'PCA'
            filterNum = 2;
        otherwise
            filterNum = 0;
    end
    
    handles.filterNum = filterNum;
    guidata(hObject, handles);
    
    if strcmp(get(handles.start_stop_btn, 'String'), 'Start')
        updateGraph(handles)
    end

% --- Executes on button press in export_btn.
function export_btn_Callback(hObject, eventdata, handles)
% hObject    handle to export_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if isfield(handles, 'csiData')
        data = handles.csiData;
        [~, n] = size(data);
        for i=1:n
            if data{1,i}(1,1) == 0
                data{1,i} = [];
            end
        end
        assignin('base', 'csi_data', cell2mat(data));
    end

% --- Executes on mouse press over axes background.
function csi_monitoring_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to csi_monitoring (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    persistent chk
    if isempty(handles) ~= 1
        if isempty(chk)
            chk = 1;
            pause(0.5);
            if chk == 1
                chk = [];
            end
        else
            chk = [];
            x = figure;
            copyobj(handles.csi_monitoring, x);
        end
    end
    
