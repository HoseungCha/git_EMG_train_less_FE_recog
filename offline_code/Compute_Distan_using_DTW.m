%----------------------------------------------------------------------
% developed by Ho-Seung Cha, Ph.D Student,
% CONE Lab, Biomedical Engineering Dept. Hanyang University
% under supervison of Prof. Chang-Hwan Im
% All rights are reserved to the author and the laboratory
% DTW, Eucldian, pattern matching 이용하여, 거리값 계산하는 코드
% contact: hoseungcha@gmail.com
%---------------------------------------------------------------------
clear all;clc; close all;
addpath(genpath(fullfile(cd,'functions')));
% parameters
FE_nameList = {'Angry','Contemptuous','Disgust','Fear','Happy','Neutral','Sad','Surprised'};
biplor_channel_nameList= {'Right Temporalis';'Left Temporalis';'Right Frontalis';...
    'Left Corrugator';'Left Zygomaticus';'Right Zygomaticus'};
N_FE = 8; % 표정 갯수
N_Repeat = 20; % 반복 횟수
% FileName = '17_03_29_170816_Features_extracted.mat';
FileName = 'Features_통합_new.mat';

PathName = fullfile(cd,'result');
str_data = 'dd-mmm-yyyyHHMMSS';
current_time = datestr(now,str_data);
% read file
% [FileName,PathName] = uigetfile('*mat','Select Features_extracted.mat');
loaded = load(fullfile(PathName,FileName));
feature_list = loaded.Features  ;
params = loaded.params;
feature_name_list = fieldnames(feature_list);
N_features = length(feature_name_list);
N_channel = length(params.biplor_channel_nameList_2nd);
N_subject = length(params.Sname);

% Training Examples 별 DTW 계산
window_width = 3;
max_slope_length = 2;
speedup_mode = 1;
C = cell(N_subject,1);
CM = cell(N_subject,1);
IND = cell(N_subject,1);
PER = cell(N_subject,1);
y_upper = 1; y_lower = -1;
dist_total_result = cell(N_features,1);
dist = cell(params.N_Repeat,params.N_Repeat);
trueLabels=zeros(N_FE,N_FE*(N_FE-1));
estLabels=zeros(N_FE,N_FE*(N_FE-1));

% for i_feat = 1 : N_features
for i_feat = 7
h = timebar('Loop counter','Progress');
count = 1;
dist_FULL = zeros(N_subject*(N_subject)*(params.N_Repeat^2)*(N_FE^2),9);
for i_sub_template = 1 : N_subject
    for i_sub_test = 1 : N_subject
%         if i_sub_template==i_sub_test
%             continue;
%         end
        for i_data_template = 1 : params.N_Repeat
            for i_data_test_template = 1 : params.N_Repeat
                for i_emotion_temp_plate = 1 : N_FE
                    for i_emotion_test = 1 : N_FE                        
%                         eval(sprintf('temp_a = feature_list(i_emotion_temp_plate).%s(i_data_template,:,i_sub_template)'';',...
%                             feature_name_list{i_feat}));
%                         eval(sprintf('temp_b = feature_list(i_emotion_test).%s(i_data_test_template,:,i_sub_test)'';',...
%                             feature_name_list{i_feat}));
                        eval(sprintf('temp_a = feature_list.%s(i_data_template,:,i_sub_template,i_emotion_temp_plate)'';',...
                            feature_name_list{i_feat}));
                        eval(sprintf('temp_b = feature_list.%s(i_data_test_template,:,i_sub_test,i_emotion_test)'';',...
                            feature_name_list{i_feat}));
                        [temp_dtw, ~, ~] = fastDTW(...
                            temp_a, temp_b, max_slope_length, speedup_mode, window_width );                        
                        temp_eucD  = sqrt(sum(temp_a - temp_b).^ 2);
                        [~,inda] = sort(temp_a); [~,indb] = sort(temp_b);
                        N_consistency = length(find(inda==indb));
                        dist_FULL(count,:) = [i_sub_template,i_sub_test,...
                            i_data_template,i_data_test_template,...
                            i_emotion_temp_plate,i_emotion_test,temp_dtw,temp_eucD,N_consistency];
                        count = count+1;
                        
                    end
                end                
            end            
        end
        timebar(h,count/(N_subject*(N_subject)*(params.N_Repeat^2)*(N_FE^2)));
    end
end
% dist_total_result{i_feat} = dist_FULL;
saving_name = num2str(i_feat);
save([saving_name,'_dist_FULL_combined.mat'],'dist_FULL');
end
% save('dist_FULL_combined.mat','dist_total_result');
%  data categorizaion with subject and emotion 
% ( 피험자-Task 와, 또 다른 모든피험자-Task간의 distance중 감정마다 가장 적은 Feature selection

% 
% save('recomanded_dataset.mat','recomanded_dataset');
% 
% %  data categorizaion with subject and emotion 
% % 피험자-Task 와, 또 다른 모든 피험자간(Task 평균)의 distance중 Feature selection
% recomanded_dataset = cell(N_subject,N_Repeat,N_FE);
% Top100 = 100;
% for i_sub = 1 : N_subject
%     for i_re = 1 : N_Repeat
%         for i_FE = 1 : N_FE
%             idx_subject = find(index2train(:,1)==i_sub);
%             idx_data = find(index2train(:,3)==i_re);
%             idx_emotion = find(index2train(:,5)==i_FE);
%             idx_recommanded_data = mintersect(idx_subject,idx_data,idx_emotion);            
%             temp_data = index2train(idx_recommanded_data,:);
%             [~,idex_sorted] = sort(temp_data(:,6),1,'ascend');
%             sorted_temp_data = temp_data(idex_sorted,:);
%             recomanded_dataset{i_sub,i_re,i_FE} = sorted_temp_data(1:Top100,[2,4,6]);         
%         end
%     end
% end

% % mean_dist_sub: ~Sub template X sub data template X Other Sub template 
% mean_dist_sub = cell(N_subject,params.N_Repeat,N_subject);
% for i_sub_template = 1 : N_subject
%     for i_sub_test = 1 : N_subject
%         if i_sub_template==i_sub_test
%             continue;
%         end        
%         for i_data_template = 1 : params.N_Repeat   
%             temp_dist = zeros(params.N_Repeat,N_FE);
%             for i_emotion = 1: N_FE
%                 for i_data_test_template = 1 : params.N_Repeat                
%                     temp_dist(i_data_test_template,i_emotion) = subj_dist...
%                         {i_sub_template, i_sub_test}...
%                         {i_data_template, i_data_test_template}...
%                         (i_emotion,i_emotion);                    
%                 end
%             end
%             % temp_dist: ...Test data_template X Emotion vector
%             mean_dist_sub{i_sub_template,i_data_template,i_sub_test}...
%                 = mean(temp_dist,1);
%         end
%     end
% end
% 
% for i_sub_template = 1 : N_subject
%     for i_sub_test = 1 : N_subject
%         if i_sub_template==i_sub_test
%             continue;
%         end    
%         for i_data_template = 1 : params.N_Repeat 
%             mean_dist_sub{i_sub_template,i_data_template,i_sub_test}...
%         end
%     end
% end
