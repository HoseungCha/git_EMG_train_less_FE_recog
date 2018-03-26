%----------------------------------------------------------------------
% by Won-Du Chang, ph.D,
% Research Professor @  Department of Biomedical Engineering, Hanyang University
% contact: 12cross@gmail.com
%---------------------------------------------------------------------
function Process_mem(  )
%PROCESS �� �Լ��� ��� ���� ��ġ
%   timer�� ���ؼ� �ֱ������� �����Ѵ�
%   �����͸� �ϳ� (���׸�Ʈ ����) �����ͼ� ó���Ѵ�.


%global data_all;
%global pos;
global info;
%global option;
global dataqueue;
% global pd;
%global EM_online;
global raw_signal_reserve;
global trg;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ������ �о���� �ڵ� - ����

%add to original data
try
    seg_from_bio = biosemix([info.nTotalChannel, 0]);
catch me
    if strfind(me.message,'BIOSEMI device')
        
        fprintf(strrep([me.message 'Recalling the BIOSEMI device again.'], sprintf('\n'),'. '));
        
        clear biosemix;
        seg_from_bio = biosemix([params.numEEG 0]);
    else
        rethrow(me);
    end
end

segment = 10^6*double(single(seg_from_bio(2:end,:)') * 0.262 / 2^31);
trg_sig = seg_from_bio(1,:);
segLength_dynamic = size(segment,1);


dataqueue.addArray(segment);
trg.addArray(trg_sig);

if dataqueue.datasize<length(info.notchfilter.b)+length(info.notchfilter.a)
    return;
end

% notch filtering ���� (60Hz)
if isempty(info.notchfilter.zf)
    tmp_d = dataqueue.getLastN(dataqueue.datasize);
    [notch_segment,info.notchfilter.zf]=filter(info.notchfilter.b,info.notchfilter.a,tmp_d,[],1);
else
    [notch_segment,info.notchfilter.zf]=filter(info.notchfilter.b,info.notchfilter.a,segment,info.notchfilter.zf,1);
end


% Raw Signal Reserve (������ �����)
raw_signal_reserve.mat(raw_signal_reserve.n_data+1:raw_signal_reserve.n_data+segLength_dynamic, :) = [segment,trg_sig];
raw_signal_reserve.notch_mat(raw_signal_reserve.n_data+1:raw_signal_reserve.n_data+segLength_dynamic, :) = [notch_segment,trg_sig];
raw_signal_reserve.n_data = raw_signal_reserve.n_data + segLength_dynamic;

%resampling
segment_resmapled = notch_segment(option.resamplingRate4EOG:option.resamplingRate4EOG:info.ExpectedSegmentLength,:);
veog = segment_resmapled(:,info.ch_u) - segment_resmapled(:,info.ch_d);
heog = segment_resmapled(:,info.ch_r) - segment_resmapled(:,info.ch_l);
    
    
% ������ �о���� �ڵ� - ��
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Process_EOG (heog,veog);

end



function Process_EOG(heog,veog)
global pd;
global info;
global EM_online;
global tstack_triple;
persistent time_cur

% time setting for triple Blink
t = datevec(now);
temp_time=time_cur - t(6);
if ~isempty(temp_time)
    tstack_triple=tstack_triple+ ((-1)*temp_time); % 2��° trial �ð��� ��� ����
end
time_cur = t(6);
if tstack_triple<0
    tstack_triple=0;
end
disp(tstack_triple);

pd.EOG.addArray([heog,veog]);
pd.EOG_ebRemoved.addArray([heog,veog]);
%     pd.EOG_2checkSaccade.addArray([heog,veog]);
%     pd.EOG_saccade.addArray([heog,veog]);



%Eyeblink Detection
len_veog = size(veog,1);
len_process_data = info.Fc4EOG; %�ֱ� 1�� �����͸� �����´�.
len_margin_4interpolation = 10; %�� ���̸�ŭ eyeblink �� �������� �ʴ� ���, ������ eyeblink �� �����ٰ� ������

for i=1:len_veog
    pd.queuelength_eb_check.addArray(0);
    EM_online.add(veog(i));
    if size(EM_online.cur_detected_range,1)>0  %���� ����� ���
        %        myStop();
        pd.EOG_ebRemoved.set(EM_online.cur_detected_range(1), EM_online.cur_detected_range(2), nan, 2);
        %pd.EOG_ebRemoved.set(EM_online.cur_detected_range(1), EM_online.cur_detected_range(2), nan);
    end
end

%Interpolation of Eyeblink Regions
len_dataQueue = pd.EOG_ebRemoved.datasize;
if len_dataQueue<len_process_data  %interpolation � �ʿ��� �����Ͱ� ������� ���� ���, �� �̻� �������� �ʴ´�.
    return;
end
tmp_d = pd.EOG_ebRemoved.getLastN(len_process_data);
bNan = isnan(tmp_d(:,2));
%eyeblink ������ �����ϸ�, �ش籸���� ����� ���
if  sum(bNan)>0 && sum(bNan(len_process_data-len_margin_4interpolation+1:len_process_data))==0
    tmp_d(:,2) = InterpolateNans(tmp_d(:,2),1);
    pd.EOG_ebRemoved.set(len_dataQueue-len_process_data+1,len_dataQueue,tmp_d(:,2),2);
    
    %Tripple blink check
    %         myStop;
    pd.queuelength_eb_check.addArray(1);
    
    nEB_inAShortTime = sum(pd.queuelength_eb_check.data);
    %         disp(nEB_inAShortTime);
    %         disp(info.EMG.time_stack4tripple);
    
    if nEB_inAShortTime > 2 && tstack_triple>3
        %         triple blink �߻��� 3�ʵ����� �߻����ϵ��� ����
        %         if randi(20)==1 && info.EMG.time_stack4tripple>3
        myStop;
        tstack_triple=0;
        
        bTripleBlink = 1;
        fprintf('Tripple Blink\n');
    end
    
end
end

