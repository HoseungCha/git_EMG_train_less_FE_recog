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
Feat_analaysis_index = 3;

formatOut = 'yy_mm_dd_HHMMSS_';
current_time=datestr(now,formatOut);
load('pairset_new.mat')
Filename_recom_idx = [num2str(Feat_analaysis_index),'recommd_indx_FV_combined.mat'];
load(Filename_recom_idx); %recommd_indx_FV_170514, recommd_indx_FV_combined
% load('selected_data_vari_cond.mat');
% load('pairset.mat')
%% read file
% [FileName,PathName] = uigetfile('*mat','Select offline data');
File_name_feature = 'Features_통합_new.mat';
loaded = load(fullfile(cd,'result',...
    File_name_feature)); %17_03_29_170816_Features_extracted,Features_통합
% loaded_name = fieldnames(loaded);
feature_list = loaded.Features  ;
params = loaded.params;
feature_name_list = fieldnames(feature_list);
N_features = length(feature_name_list);
N_channel = length(params.biplor_channel_nameList_2nd);
N_subject = length(params.Sname);
% Parameter setup
s_idx_compenstated = sprintf('Idx_N_compensted = 60;');
eval(s_idx_compenstated);
% Idx_N_compensted(1) = 1;

N_compenstaed = length(Idx_N_compensted);
s_idx_pair = sprintf('Idx_pair = 1;');
eval(s_idx_pair);

Num_pair = length(Idx_pair);
Feat_anal_name = feature_name_list{Feat_analaysis_index};
eval(sprintf('Features = feature_list.%s;',Feat_anal_name));

DTW_opt.nDivision_4Resampling = 10;
% DTW를 계산 두 Feature 간의 거리 (유사도) 계산
DTW_opt.max_slope_length = 3;
DTW_opt.speedup_mode = 1;
%% Emotion selection
Idx_selected_emotion = 1 : params.N_FE;
% Idx_selected_emotion([1,4,7]) = [];
% Idx_selected_emotion(4) = [];
% Idx_selected_emotion(7) = [];


N_NEW_FE = length(Idx_selected_emotion);

%% Concatenate features from varirous features list
acc = cell(N_compenstaed, Num_pair);
total_results = cell(N_compenstaed, Num_pair);
Lcount = 1;
analysis_discrpt = sprintf('%s %s %s Method 1 - 최소값',...
    Feat_anal_name,s_idx_pair, s_idx_compenstated);
disp(analysis_discrpt);
h = timebar(analysis_discrpt,'Progress');
RE_count = 1;
for i_pair = Idx_pair
    for i_N_compenstaed = Idx_N_compensted
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
        fprintf('i_N_compenstaed:%d\n',i_N_compenstaed);
        for i_sub4valid = 1 : N_subject
            for i_data4valid = 1 : N_pair
                
                % preperation training set
                Tr_count = 1;
                TrSet = zeros((i_pair+i_N_compenstaed)*N_NEW_FE,21);
                TrLabel = zeros(size(TrSet,1),1);
                indx_Trset4valid = pairset_new{i_pair}(i_data4valid,:);
                
                for i_emotion = Idx_selected_emotion
                    % 자신의 데이터
%                     my_own_data = feature_list(i_emotion).RMS_mean(indx_Trset4valid,:,i_sub4valid);
                    my_own_data = Features(indx_Trset4valid,:,i_sub4valid,i_emotion);
                    
                    for i = 1 : size(my_own_data,1)
                        TrSet(Tr_count,:) = ...
                            my_own_data(i,:);
                        TrLabel(Tr_count,:) = i_emotion;
                        Tr_count = Tr_count + 1;
                    end
                    %loading data from other subjects
                    cand = candi_ver2{i_sub4valid,i_emotion,i_pair,...
                        i_data4valid};
                    % adding compenstaed data from other subjects
                    for i_dat = 1 : i_N_compenstaed
%                         dataFromOthers =...
%                             feature_list(i_emotion).RMS_mean...
%                             (cand(i_dat,2),:,cand(i_dat,1));
                        dataFromOthers = Features(cand(i_dat,2),:,...
                            cand(i_dat,1),i_emotion);
                        if(i_pair == 1)
                             dataTransformed= transfromData_accRef_usingDTW...
                            (dataFromOthers', my_own_data', DTW_opt);
                            TrLabel(Tr_count,:) = i_emotion;
                            
                            % method 1: Neutral제외하여 DTW 데이터 변환 수행
                            if (i_emotion ~= 6) % Neutral data는 Transform 안함
                                TrSet(Tr_count,:) = dataTransformed;
                            else
                                TrSet(Tr_count,:) = dataFromOthers;
                            end
                            
                            % method 2:  Confusion을 많이 일으키는 Angry, Sad, Fear 데이터만 DTW 데이터 변환 수행
%                             if (i_emotion ~= 2 ||i_emotion ~= 3||i_emotion ~= 5||i_emotion ~= 6||i_emotion ~= 8) % Neutral data는 Transform 안함
%                                 TrSet(Tr_count,:) = dataTransformed;
%                             else
%                                 TrSet(Tr_count,:) = dataFromOthers;
%                             end
                            % method 3: Normalization을 수행하지 않고 method1 수행
                            % method 4: Normalization 수행하지 않고 method2 수행
                            
                            
                            Tr_count = Tr_count + 1;
                        else
                            % Method 0 - 평균 값
%                             dataTransformed= transfromData_accRef_usingDTW...
%                                 (dataFromOthers', mean(my_own_data,1)', DTW_opt);

                            % Method 1 - 최소값
                            [~,idx2use] = min(cand(i_dat,3:end));

                            % Method 2 - 최대값
%                             [~,idx2use] = max(cand(i_dat,3:end));
% 
% 
                            dataTransformed= transfromData_accRef_usingDTW...
                                (dataFromOthers', my_own_data(idx2use,:)', DTW_opt);

                            % Method 3 - 모두 포함


                            if (i_emotion ~= 6) % Neutral data는 Transform 안함
                                TrSet(Tr_count,:) = dataTransformed;
                            else
                                TrSet(Tr_count,:) = dataFromOthers;
                            end

    %                         TrSet(Tr_count,:) = dataFromOthers;                            
                            TrLabel(Tr_count,:) = i_emotion;
                            Tr_count = Tr_count + 1;
                        end
                    end
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
%                             feature_list(i_emotion).RMS_mean(i_data4test,:,i_sub4valid)';
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
                
                Mdl.city = fitcknn(TrSet,TrLabel,'Distance','cityblock');
                Mdl.chebychev = fitcknn(TrSet,TrLabel,'Distance','chebychev');
                Mdl.corr = fitcknn(TrSet,TrLabel,'Distance','correlation');
                Mdl.euc = fitcknn(TrSet,TrLabel,'Distance','euclidean');
                Mdl.maha = fitcknn(TrSet,TrLabel,'Distance','mahalanobis');
                Mdl.min = fitcknn(TrSet,TrLabel,'Distance','minkowski');
                
                Mdl_names = fieldnames(Mdl);
                for i = 1 : length(Mdl_names)
                eval(sprintf('[Output_%d, Score, cost] =  predict(Mdl.%s,TeSet);',...
                    i,Mdl_names{i}));
                eval(sprintf('temp_acc(i,1) =  length(find((Output_%d==TeLabel) ==1))/152*100;',...
                    i));
                end
                
                CV.accuracy{i_data4valid,i_sub4valid}(1)                    
                CV.kmean_acc{i_data4valid,i_sub4valid} = temp_acc;
                temp_acc
            end
            
            Lcount = Lcount + 1;
            timebar(h,Lcount/(N_subject*N_compenstaed*Num_pair))
            
        end
        for i_data4valid = 1 : N_pair
            for i_sub4valid = 1 : N_subject
                acc{RE_count}(i_data4valid,i_sub4valid) = CV.accuracy{i_data4valid,i_sub4valid}(1);
            end
        end
        disp(mean(mean(acc{RE_count})));
        total_results{RE_count} = CV;
        RE_count = RE_count + 1;
    end
end

mean_accr = zeros(N_compenstaed, Num_pair);
for i_N_compenstaed = 1 : N_compenstaed
    for i_pair = 1:Num_pair
        mean_accr(i_N_compenstaed,i_pair) = mean(mean(acc{i_N_compenstaed,i_pair}));
    end
end
mean_accr = mean_accr';
figure;plot(mean_accr')

disp(analysis_discrpt);
Num_pair = 1;
sub_list_1st = 1 : 10;
N_1st = length(sub_list_1st);
sub_list_2nd = 11 : 30;
N_2nd = length(sub_list_2nd);
sub_list_total = 1 : 30;
N_3rd = length(sub_list_total);
% mean_acc_1st = zeros(Num_pair, N_compenstaed);
acc_1st = zeros(Num_pair,N_compenstaed);
acc_temp_1st = zeros(N_pair,N_1st);
acc_2nd = zeros(Num_pair,N_compenstaed);
acc_temp_2nd = zeros(N_pair,N_2nd);
acc_total = zeros(Num_pair,N_compenstaed);
acc_temp_3rd = zeros(N_pair,N_3rd);
for i_pair = 1 : Num_pair
    for i_N_compenstaed = 1: N_compenstaed    
        for i_data4valid = 1 : 20
            Sub_count = 1;
            for i_sub4valid = sub_list_1st
                acc_temp_1st(i_data4valid,Sub_count) =...
                    total_results{i_N_compenstaed, i_pair}.accuracy...
                    {i_data4valid,i_sub4valid}(1);
                Sub_count = Sub_count+1;
            end
            acc_1st(i_pair,i_N_compenstaed) = mean(mean(acc_temp_1st));
            
            Sub_count = 1;
            for i_sub4valid = sub_list_2nd
                acc_temp_2nd(i_data4valid,Sub_count) =...
                    total_results{i_N_compenstaed, i_pair}.accuracy...
                    {i_data4valid,i_sub4valid}(1);
                Sub_count = Sub_count+1;
            end
            acc_2nd(i_pair,i_N_compenstaed) = mean(mean(acc_temp_2nd));
            
            Sub_count = 1;
            for i_sub4valid = sub_list_total
                acc_temp_3rd(i_data4valid,Sub_count) =...
                    total_results{i_N_compenstaed, i_pair}.accuracy...
                    {i_data4valid,i_sub4valid}(1);
                Sub_count = Sub_count+1;
            end
            acc_total(i_pair,i_N_compenstaed) = mean(mean(acc_temp_3rd));
            
        end
    end
end

mean_acc_1st = mean(mean(acc_1st,4),3);
mean_acc_2nd = mean(mean(acc_2nd,4),3);
mean_acc_total = mean(mean(acc_total,4),3);

N_sub = 30;N_trial=20;N_FE=8;N_Seg=30;
dist_FULL = zeros((N_sub^2)*(N_trial^2)*(N_FE^2)*(N_Seg^2), 1);
