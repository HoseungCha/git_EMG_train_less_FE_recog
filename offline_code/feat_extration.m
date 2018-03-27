%----------------------------------------------------------------------
% developed by Ho-Seung Cha, Ph.D Student,
% CONE Lab, Biomedical Engineering Dept. Hanyang University
% under supervison of Prof. Chang-Hwan Im
% All rights are reserved to the author and the laboratory
% contact: hoseungcha@gmail.com
%---------------------------------------------------------------------

clc; clear all; close all;
parentdir=(fileparts(fileparts(pwd)));
addpath(genpath(fullfile(parentdir,'functions')));
%% 실험정보
FE_name = {'Angry','Contemptuous','Disgust','Fear','Happy','Neutral','Sad','Surprised'};
N_FaExp = length(FE_name);  %facial expression
% MAX_N_Trl = 26; %trial
datapath = fullfile(parentdir,'DB','RawDB');

%% 표정 짓는 순서 정보
load(fullfile(datapath,'FE_LIST_BACKUP'));

%% filter parameters
SF2use = 2048;
fp.Fn = SF2use/2;
filter_order = 4; Fn = SF2use/2;
Notch_freq = [58 62];
BPF_cutoff_Freq = [20 450];
[nb,na] = butter(filter_order,Notch_freq/Fn,'stop');
[bb,ba] = butter(filter_order,BPF_cutoff_Freq/Fn,'bandpass');

%% subplot 그림 꽉 차게 출력 관련 
make_it_tight = true; subplot = @(m,n,p) subtightplot (m, n, p, [0.01 0.05], [0.1 0.01], [0.1 0.01]);
if ~make_it_tight,  clear subplot;  end

%% read file path of data
[Sname,Spath] = read_names_of_file_in_folder(fullfile(datapath,'1차'));
FE_list_DB = FE_list_DB(:,11:30);
N_subject = length(Sname);

%% experiments or feat extractions parameters
N_seg = 30;
N_feat = 42;
N_trl = 20;
Time_expression = 3; % 3-sec
wininc = floor((Time_expression/N_seg)*SF2use); 

%% 결과 memory alloation
Features = zeros(N_seg,N_feat,N_FaExp,20,N_subject);
% Features(:,:,event_s(i_emo,1),i_data,i_sub)
for i_sub= 1:N_subject
    
    sub_name = Sname{i_sub}(end-2:end);

    [fname,fpath] = read_names_of_file_in_folder(Spath{i_sub},'*bdf');
    
    %arrange order of facial expression in each trial
    FE_list_DB_sub = FE_list_DB(:,i_sub);
    N_Trl = length(find(~isnan(FE_list_DB_sub)));
    FE_list_DB_sub = FE_list_DB_sub(1:N_Trl);
    N_Trl  = N_Trl/N_FaExp;
    FE_list_DB_sub = reshape(FE_list_DB_sub,[N_FaExp,N_Trl]);
    
    % for saving feature Set (processed DB)
    count_i_data = 0;
%     if(N_Trl>20)
%         keyboard;
%     end
    for i_data = 1:N_trl
        count_i_data = count_i_data + 1;
        OUTEEG = pop_biosig(fpath{i_data});
        
        %% load trigger when subject put on a look of facial expressoins
        event_s = zeros(N_FaExp,2); event_e = zeros(N_FaExp,2);
        
        % Feat extraction using experiment infromation in 2nd DB set
        if contains(fileparts(Spath{1}),'1차')
        DB_set_type = '1st';
        for i_FE=1 : N_FaExp
            event_s(i_FE,1) = OUTEEG.event(i_FE+1).type;
            event_s(i_FE,2) = OUTEEG.event(i_FE+1).latency; 
        end
        end
        
        % Feat extraction using experiment infromation in 2nd DB set
        if contains(fileparts(Spath{1}),'2차')
        DB_set_type = '2nd';
        for i_FE=1 : N_FaExp
            event_s(i_FE,1) = OUTEEG.event(3*(i_FE-1)+2).type;
            event_s(i_FE,2) = OUTEEG.event(3*(i_FE-1)+2).latency;           
            event_e(i_FE,1) = OUTEEG.event(3*(i_FE-1)+3).type;
            event_e(i_FE,2) = OUTEEG.event(3*(i_FE-1)+3).latency;
        end
        end
        %% get raw data and bipolar configuration
        raw_data = double(OUTEEG.data');
              
         % channel configuration
        temp_chan = cell(1,6);
        temp_chan{1} = raw_data(:,1) - raw_data(:,2); %Right_Temporalis
        temp_chan{2} = raw_data(:,3) - raw_data(:,4);%Left_Temporalis
        temp_chan{3} = raw_data(:,5) - raw_data(:,6);%Right_Frontalis
        temp_chan{4} = raw_data(:,7) - raw_data(:,8);%Left_Corrugator
        temp_chan{5} = raw_data(:,9) - raw_data(:,10);%Left_Zygomaticus
        temp_chan{6} = raw_data(:,11) - raw_data(:,12);%Right_Zygomaticus
        bp_data = cell2mat(temp_chan);


        %% Filtering
        filtered_data = filter(nb, na, bp_data,[],1);
        filtered_data = filter(bb, ba, filtered_data, [],1);
        
        % for plot
%         figure;plot(filtered_data)

        %% Feat extration with windows 
        % increase size = 0.05;, win size = 0.1;
        winsize = floor(0.1*SF2use);
%         wininc = floor(0.05*SF2use); 
        % 0.1초 윈도우, 0.05초 씩 증가
        N_window = floor((length(filtered_data) - winsize)/wininc)+1;
        temp_feat = zeros(N_window,N_feat); Window_Endsamples = zeros(N_window,1);
        st = 1;
        en = winsize;
        for i = 1: N_window
            Window_Endsamples(i) = en;
            curr_win = filtered_data(st:en,:);
            temp_rms = sqrt(mean(curr_win.^2));
            temp_CC = featCC(curr_win,4);
            temp_WL = sum(abs(diff(curr_win,2)));
            temp_SampEN = SamplEN(curr_win,2);
            temp_feat(i,:) = [temp_CC,temp_rms,temp_SampEN,temp_WL];
            % moving widnow
            st = st + wininc;
            en = en + wininc;                 
        end

        %% cutting trigger 
        idx_TRG_Start = zeros(N_FaExp,1);
        for i_emo = 1 : N_FaExp
            idx_TRG_Start(i_emo,1) = find(Window_Endsamples >= event_s(i_emo,2),1);
        end
        
        %% To confirm the informaion of trrigers were collected right
%         hf =figure(i_sub);
%         hf.Position = [-1919 41 1920 962];
%         subplot(N_Trl,1,i_data);
%         plot(temp_feat(:,25:31));
%         hold on;
%         stem(idx_TRG_Start,repmat(100,[N_FaExp,1]));
%         ylim([1 150]);
% %         subplot(N_Trl,2,2*i_data);
% %         plot(temp_feat(:,1:6));
% %         hold on;
% %         stem(idx_TRG_Start,ones([N_FE,1]));
%         drawnow;
        
       %% Get Feature sets(preprocessed DB)
        for i_emo = 1 : N_FaExp
            Features(:,:,FE_list_DB_sub(i_emo,i_data),i_data,i_sub) = ...
                        temp_feat(idx_TRG_Start(i_emo):idx_TRG_Start(i_emo)+floor((3*SF2use)/wininc)-1 ,:); 
        end 
    end  
    %% plot the DB 
%     c = getframe(hf);
%     imwrite(c.cdata,fullfile(parentdir,'DB','DB_inspection',...
%         [sub_name(1:3),'.jpg']));
%     close(hf);
end
%% 결과 저장
save(fullfile(parentdir,'DB','ProcessedDB',sprintf('feat_set_%s_seg_%d',...
    DB_set_type,N_seg)),...
    'Features');
% save(fullfile(cd,'result',sprintf('FEATS_2ND.mat')),'Features');

% after extracting DB set of 1st and 2nd , we have to concatinate the both
% feature set.
% f1 = load(fullfile(parentdir,'DB','ProcessedDB',sprintf('feat_set_%s','1st')));
% f2 = load(fullfile(parentdir,'DB','ProcessedDB',sprintf('feat_set_%s','2nd')));
% feat_set_combined = cat(5,f1.Features,f2.Features);
% save(fullfile(parentdir,'DB','ProcessedDB',sprintf('feat_set_combined')),...
%     'feat_set_combined'); % saving concatinated feature set from DB1 and DB2

