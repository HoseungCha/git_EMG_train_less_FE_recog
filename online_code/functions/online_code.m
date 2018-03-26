%--------------------------------------------------------------------------
% developed by Ho-Seung Cha, Ph.D Student,
% CONE Lab, Biomedical Engineering Dept. Hanyang University
% under supervison of Prof. Chang-Hwan Im
% All rights are reserved to the author and the laboratory
% contact: hoseungcha@gmail.com
% 2017.09.20 main timer function �����͸� �ǽð����� queue�� �ִ� �ڵ�.
%--------------------------------------------------------------------------
function online_code(  )
global info;
global pd;
% timeStart = toc(info.timer.online_code.UserData)
try
    %data input
    if info.prog_mode ==0
        if info.curr_pos+info.timer.SF-1 > size(info.bdf.data,2)
            myStop();
            return;
        end
        segment = info.bdf.data(:,info.curr_pos:info.curr_pos+info.timer.SF-1);
        segment = double(segment)';
        trg_segment = info.bdf.trg(info.curr_pos:info.curr_pos+info.timer.SF-1);
        info.curr_pos = info.curr_pos+ info.timer.SF;
    elseif info.prog_mode ==1
        if (info.use_biosmix ==1)
            try
                segment = biosemi_signal_recieve(info.total_ch);
            catch me
                if strfind(me.message,'biosemix')
                    errordlg('Please check you are using matlab 32bit version. and please Stop now');
                end
            end
        elseif (info.use_biosmix ==0)
%             if pd.TCP_buffer.datasize<info.timer.SF % TCP ���۰� ���� �Ƚ׿����� return ��Ŵ
%                 segment = pd.TCP_buffer.getLastN(pd.TCP_buffer.datasize);
%             else
%                 segment = pd.TCP_buffer.getLastN(info.timer.SF);
%             end
% myStop;
            segment = TcpIpClientMatlabV1();
%             clc;
%             segment = segment(:,1:12);
        end
    end
    
    % raw data �� ǥ�� �ν�Ʈ���� ���� ����
%     if ~exist('segment','var')
%         return;
%     end
%     myStop;
    seg_size = size(segment,1);
%     disp(seg_size);
    if seg_size == 0
%         myStop;
        return;
    end
    info.rawdata(info.raw_pos:info.raw_pos+seg_size-1,1:info.total_ch) = segment;
    if(info.FE_start_sign)        
        info.rawdata(info.raw_pos:info.raw_pos+seg_size-1,info.total_ch+1) = ones(seg_size,1);
    else
        info.rawdata(info.raw_pos:info.raw_pos+seg_size-1,info.total_ch+1) = zeros(seg_size,1);
    end
    info.raw_pos = info.raw_pos + seg_size;
    
    % channel configuration
    temp_chan = cell(1,6);
    temp_chan{1} = segment(:,1) - segment(:,2); %Right_Temporalis
    temp_chan{2} = segment(:,3) - segment(:,4);%Left_Temporalis
    temp_chan{3} = segment(:,5) - segment(:,6);%Right_Frontalis
    temp_chan{4} = segment(:,7) - segment(:,8);%Left_Corrugator
    temp_chan{5} = segment(:,9) - segment(:,10);%Left_Zygomaticus
    temp_chan{6} = segment(:,11) - segment(:,12);%Right_Zygomaticus
    segments = cell2mat(temp_chan);

    
    % filtering notch, BPF
    if isempty(info.f.nZn)
        [segments,info.f.nZn] = filter(info.f.nB,info.f.nA,...
           segments,[],1);
    else
        [segments,info.f.nZn] = filter(info.f.nB,info.f.nA,segments,info.f.nZn,1);
    end    
    if isempty(info.f.bZn)
        [segments,info.f.bZn] = filter(info.f.bB,info.f.bA,...
            segments,[],1);
    else
        [segments,info.f.bZn] = filter(info.f.bB,info.f.bA,segments,info.f.bZn,1);
    end
    pd.EMG.addArray(segments); % �׸� ��� ������
    
    Process_EMG(); % EMG ��ȣ ó�� �� �з�
catch ex
    myStop;
    keyboard;
end
% timeEnd = toc(info.timer.online_code.UserData)
end

