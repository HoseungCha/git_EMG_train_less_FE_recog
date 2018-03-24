%----------------------------------------------------------------------
% developed by Ho-Seung Cha, Ph.D Student,
% CONE Lab, Biomedical Engineering Dept. Hanyang University
% under supervison of Prof. Chang-Hwan Im
% All rights are reserved to the author and the laboratory
% 2017. 05.14 작성, Research Diary 1.a.3번 참고
% contact: hoseungcha@gmail.com
% Trainless_EMG_FE_Reco..파일로 부터 저장된 결과를 가지고( feature)
% 분류하는 코드
%---------------------------------------------------------------------
clear all; close all; clc
addpath(genpath(fullfile(cd,'functions')));

% parameter 설정
formatOut = 'yy_mm_dd_HHMMSS_';
current_time=datestr(now,formatOut);
load('pairset_new.mat')
% load('recommd_indx_FV_170514.mat');
% load('selected_data_vari_cond.mat');
%% read file
% [FileName,PathName] = uigetfile('*mat','Select offline data');
File_name_feature = 'Features_통합_new.mat';
loaded = load(fullfile(cd,'result',...
    File_name_feature));
% loaded = load(fullfile(cd,'result',...
%     '17_03_29_170816_Features_extracted.mat'));
% loaded_name = fieldnames(loaded);
feature_list = loaded.Features  ;
params = loaded.params;
feature_name_list = fieldnames(feature_list);
N_features = length(feature_name_list);
N_channel = length(params.biplor_channel_nameList_2nd);
N_subject = length(params.Sname);

Feat_analaysis_index =7;
% Parameter setup
Idx_pair = 1:19;
Num_pair = length(Idx_pair);
DTW_opt.nDivision_4Resampling = 10;
% DTW를 계산 두 Feature 간의 거리 (유사도) 계산
DTW_opt.max_slope_length = 3;
DTW_opt.speedup_mode = 1;
%% Emotion selection
Idx_selected_emotion = 1 : params.N_FE;
% Idx_selected_emotion([1,4,7]) = [];
% Idx_selected_emotion(4) = [];
% Idx_selected_emotion(7) = [];
eval(sprintf('Features = feature_list.%s;',feature_name_list{Feat_analaysis_index}));
N_NEW_FE = length(Idx_selected_emotion);
%% Concatenate features from varirous features list
acc = cell(Num_pair,1);
total_results = cell(Num_pair,1);
Lcount = 1;
analysis_discrpt = sprintf('데이터 통합 자신의 결과');
h = timebar(analysis_discrpt,'Progress');
for i_pair = Idx_pair
% for i_pair = 19
    
        N_pair = size(pairset_new{i_pair},1);
        % 결과 저장 변수 설정
        CV.model = cell(N_pair,N_subject);
        CV.scaled_x = cell(N_pair,N_subject);
        CV.scaled_y = cell(N_pair,N_subject);
        CV.scaling_params = cell(N_pair,N_subject);
        CV.N_corrected = cell(N_pair,N_subject);
        CV.accuracy = cell(N_pair,N_subject);
        CV.C = cell(N_pair,N_subject);
        CV.order = cell(N_pair,N_subject);
        CV.outputs = cell(N_pair,N_subject);
        CV.targets = cell(N_pair,N_subject);

        for i_sub4valid = 1 : N_subject
%         for i_sub4valid = 28
            for i_data4valid = 1 : N_pair
                
                % preperation training set
                Tr_count = 1;
                TrSet = zeros((i_pair)*N_NEW_FE,21);
                TrLabel = zeros(size(TrSet,1),1);
                indx_Trset4valid = pairset_new{i_pair}(i_data4valid,:);
                
                for i_emotion = Idx_selected_emotion
                    % 자신의 데이터
%                     my_own_data = feature_list(i_emotion).RMS_V(indx_Trset4valid,:,i_sub4valid);
                    my_own_data = Features(indx_Trset4valid,:,i_sub4valid,i_emotion);
                    for i = 1 : size(my_own_data,1)
                        TrSet(Tr_count,:) = ...
                            my_own_data(i,:);
                        TrLabel(Tr_count,:) = i_emotion;
                        Tr_count = Tr_count + 1;
                    end
                    %loading data from other subjects
%                     cand = candi_ver2{i_sub4valid,i_emotion,i_pair,...
%                         i_data4valid};
                    % adding compenstaed data from other subjects
                end
                
                % preperation test set
                Te_count = 1;
                TeSet = zeros(N_NEW_FE*(params.N_Repeat-i_pair),N_channel);
                TeLabel = zeros(size(TeSet,1),1);
                for i_emotion = Idx_selected_emotion
                    seq_trial_data = 1 : params.N_Repeat;
                    [~,i2exclude,~] = intersect(seq_trial_data,indx_Trset4valid);
                    seq_trial_data(i2exclude)=[];
                    for i_data4test = seq_trial_data
%                         TeSet(Te_count,:) = ...
%                             feature_list(i_emotion).RMS_V(i_data4test,:,i_sub4valid)';
                        
                        TeSet(Te_count,:) = Features(i_data4test,:,i_sub4valid,i_emotion);
                        TeLabel(Te_count,1) = i_emotion;
                        Te_count = Te_count +1;
                    end
                end
                
                % Training
%                 tic
                CV.model{i_data4valid,i_sub4valid} = svmtrain(TrLabel, TrSet,...
                    '-s 0 -t 1 -q');
%                 toc
                % Test
                [CV.outputs{i_data4valid,i_sub4valid}, CV.accuracy{i_data4valid,i_sub4valid}, ~] =...
                    svmpredict(TeLabel,TeSet, CV.model{i_data4valid,i_sub4valid}...
                    ,'-q');
                CV.targets{i_data4valid,i_sub4valid} = TeLabel;
                
            end
            timebar(h,Lcount/(N_subject*Num_pair))
            Lcount = Lcount + 1;
            
        end
        for i_data4valid = 1 : N_pair
            for i_sub4valid = 1 : N_subject
                acc{i_pair}(i_data4valid,i_sub4valid) = CV.accuracy{i_data4valid,i_sub4valid}(1);
            end
        end
        disp(mean(mean(acc{i_pair})));
        total_results{i_pair} = CV;
end

mean_accr = zeros(Num_pair,1);
for i_pair = 1:Num_pair
    mean_accr(i_pair) = mean(mean(acc{i_pair}));
end

figure;plot(mean_accr')

%% 결과 정리 (1차, 2차)
sub_list_1st = 1 : 10;
N_1st = length(sub_list_1st);

% sub_list_2nd = 25;

sub_list_2nd = 11 : N_subject;
N_2nd = length(sub_list_2nd);


acc_1st = zeros(Num_pair,1);
acc_temp_1st = zeros(N_pair,N_1st);
acc_2nd = zeros(Num_pair,1);
acc_temp_2nd = zeros(N_pair,N_2nd);
for i_pair = Idx_pair
    for i_data4valid = 1 : N_pair
        Sub_count = 1;
        for i_sub4valid = sub_list_1st
            acc_temp_1st(i_data4valid,Sub_count) =...
                total_results{ i_pair}.accuracy...
                {i_data4valid,i_sub4valid}(1);
            Sub_count = Sub_count+1;
        end
        acc_1st(i_pair) = mean(mean(acc_temp_1st));
        
        Sub_count = 1;
        for i_sub4valid = sub_list_2nd
            acc_temp_2nd(i_data4valid,Sub_count) =...
                total_results{ i_pair}.accuracy...
                {i_data4valid,i_sub4valid}(1);
            Sub_count = Sub_count+1;
        end
        acc_2nd(i_pair) = mean(mean(acc_temp_2nd));
    end
end

mean_acc_1st = mean(mean(acc_1st,4),3);
mean_acc_2nd = mean(mean(acc_2nd,4),3);