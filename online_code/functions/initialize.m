%--------------------------------------------------------------------------
% Variable Initialization of EMG GUI Online
%--------------------------------------------------------------------------
% by Ho-Seung Cha, Ph.D Student
% Ph.D candidate @ Department of Biomedical Engineering, Hanyang University
% hoseungcha@gmail.com
%--------------------------------------------------------------------------
function initialize(handles)
%% Define globale variables
global info; % info,  �Լ��� �������� �ʿ��� ������ ���
global pd; % pd, circlequq�� ���·� �������� �ʿ��� ������ ���
global initalize_button; % initialize button Ȯ�� ����(������ ��� -> 1)

%% GUI presentation
clc; % �۾�â �ʱ�ȭ
GUI_mode_presentation(handles) % Train/Test ��忡 ���� ��µǴ� ǥ��

%% saving relevant variables of GUI 
initalize_button = 1; % identifier if initialzie button was pushed
info.handles = handles; % saving GUI hanels
[info.beep, info.Beep_Fs] = audioread(fullfile(info.parentdir,...
    'rsc','beep.wav')); % loaded beep sound

%% timer �ʱ�ȭ
% ��� timer���� �Լ� �ʱ�ȭ
if ~isempty(timerfind)
    stop(timerfind);delete(timerfind);
end

%% ���� ����
info.FE_name = {'angry','contemptuous(right)','disgusted','fearfull','happy','neutral',...
    'sad','surprised'};
info.N_FE = length(info.FE_name); % ǥ�� ����
info.FE_order = randperm(info.N_FE); % Train�� �� ���, ǥ���� �������� ���õǵ��� ��(�����)
info.FE_order4GUI = info.FE_order; % info.FE_order4GUI (���)
info.ch_rawdata = 12; % num of channel of rawdata
info.ch = 6; % num channel of bipolar channel for EMG acquisition
info.Fc = 2048; % BIOSEMI sampling rate
info.time_FE = 3; % time for make facial expression in training sessoin

%% ǥ������ �� �ν�Ʈ���� ���� �ڵ�
info.timer.FE_train = timer('StartDelay', 5, 'TimerFcn','GUI_FE_inst',...
    'Period', 8,...
    'ExecutionMode', 'fixedRate'); % GUI Facial expression instruction timer
info.timer.RestInst = timer( 'TimerFcn','GUI_rest_inst',...
    'Period', 8, 'ExecutionMode', 'fixedRate'); % GUI rest instructaion timer

info.FE_end_sign = 0; 
info.FE_start_sign = 0;
%% timer vairable initialize
info.timer.sp = 0.1; % sampling peroriod for timer 
info.timer.Fc = floor(info.Fc*info.timer.sp); % timer sampling frequency
%% timer setup
period4timer = round(info.timer.Fc/info.Fc,3);
% period4timer = 0.01;

% info.timer.online_code = timer('TimerFcn','online_code','StartDelay',...
%     period4timer, 'Period',period4timer, 'ExecutionMode', 'fixedRate');
info.timer.online_code = timer('TimerFcn','online_code',...
    'Period',period4timer, 'ExecutionMode', 'fixedRate');
% info.timer.process_emg = timer('TimerFcn','Process_EMG',...
%     'Period', 0.1, 'ExecutionMode', 'fixedrate');
info.timer.onPaint = timer('TimerFcn','onPaint','StartDelay',...
    period4timer, 'Period', period4timer, 'ExecutionMode', 'fixedRate');

%% circlequeue variable initialzie setup
info.cq.time_buff = 10;  % set length as long as 10 sec
info.cq.length_buff = info.cq.time_buff*info.Fc; % set circlue buffer length
info.num_windows = info.time_FE/info.timer.sp; % num windows for train

%% set circlequeue
pd.TCP_buffer = circlequeue(info.cq.length_buff,info.ch_rawdata); %10*64, 2ä��+Trigger
pd.EMG = circlequeue(info.cq.length_buff,info.ch); %10*64, 2ä��+Trigger
pd.trg = circlequeue(info.cq.length_buff,1); % for GUI trigger buffer
% buffer for features of EMG
pd.f.RMS = circlequeue(info.cq.length_buff,info.ch);
pd.f.CC = circlequeue(info.cq.length_buff,info.ch*4);
pd.f.WL = circlequeue(info.cq.length_buff,info.ch);
pd.f.SampEN = circlequeue(info.cq.length_buff,info.ch);

pd.Predted = circlequeue(info.num_windows,1); %
pd.featset = circlequeue(info.num_windows,info.ch*3+info.ch*4);
pd.test_result = circlequeue(info.num_windows,1);%�ʱ�ȭ

%% RAWDATA (�����) �ʱ�ȭ
time_for_experiment = 10 * 60; % 10 minutes
% set up 10 minutes for raw data backup
info.rawdata = zeros(info.Fc*time_for_experiment,info.ch_rawdata+1);
info.raw_pos = 1;
% % offline data
info.curr_pos=1;
%% EMG preprocessing variable init
filter_order = 4; Fn = info.Fc/2;
Notch_freq = [58 62];
BPF_cutoff_Freq = [20 450];
[info.f.bB,info.f.bA] = butter(filter_order,BPF_cutoff_Freq/Fn,'bandpass');
[info.f.nB,info.f.nA] = butter(filter_order,Notch_freq/Fn,'stop');
info.f.bZn = []; info.f.nZn = [];

%% Processed DB �� ��� ���� ����
info.FeatSet = cell(info.N_FE,1);
info.test_result = cell(info.N_FE,1);

%% GUI image setup
% image handles�� �׸����� �̸� ������, �ʿ� �� ���� GUI���� �����ֱ⸸ ��
info.im_h = gobjects(info.N_FE,1); % graphics init

for i_FE=1:info.N_FE
    im_path = fullfile(info.parentdir,'rsc','img','train',[num2str(i_FE),'.jpg']);
    temp_img= imread(im_path);
    eval(sprintf('info.im_h(i_FE) = imshow(temp_img,''Parent'',handles.axes_img%d);',...
        i_FE));
end
for i_FE=1:info.N_FE
    info.im_h(i_FE).Visible='off';
end
info.im_h(6).Visible = 'on'; % defualt image

%% ��ķ ����
% if ~iinfo.Fcield(info,'cam')
%     info.cam = webcam(1);
% end
% h1 = preview(info.cam);
% CData = h1.CData;
% closePreview(info.cam);
% info.hcam = image(zeros(size(CData)),'Parent', handles.axes_timg1); 
% info.currp = preview(info.cam,info.hcam);

%% TCP ����
%configure% the folowing 4 values should match with your setings in Actiview and your network settings 
% port = 8888;                %the port that is configured in Actiview , delault = 8888
% ipadress = 'localhost';     %the ip adress of the pc that is info.TCP_running Actiview
% info.tcp.Channels = 16;             %set to the same value as in Actiview "info.tcp.Channels sent by TCP"
% info.tcp.Samples = 16;               %set to the same value as in Actiview "TCP info.tcp.Samples/channel"
% %!configure%
% 
% %variable%
% words = info.tcp.Channels*info.tcp.Samples;
% % loop = 1000;
% %open tcp connection%
% 
% info.tcpipClient = tcpip(ipadress,port,'NetworkRole','Client');
% set(info.tcpipClient,'InputBufferSize',words*9); %input buffersize is 3 times the tcp block size %1 word = 3 bytes
% set(info.tcpipClient,'Timeout',5);
% % TCP 
% period4TCP = round(info.tcp.Samples/info.Fc,3);
% info.timer.TCP = timer('TimerFcn','TcpIpClientMatlabV1', 'Period',0.055, 'ExecutionMode', 'fixedRate');
end