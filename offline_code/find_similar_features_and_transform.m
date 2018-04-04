%--------------------------------------------------------------------------
% developed by Ho-Seung Cha, Ph.D Student,
% CONE Lab, Biomedical Engineering Dept. Hanyang University
% under supervison of Prof. Chang-Hwan Im
% All rights are reserved to the author and the laboratory
% contact: hoseungcha@gmail.com
% 2017.09.13 DTW��ȯ 100�� �ø�(�Լ��� ����ȭ��Ŵ)
%--------------------------------------------------------------------------

clc; close all; clear all;
parentdir=(fileparts(fileparts(pwd)));
addpath(genpath(fullfile(parentdir,'functions')));

%% Feature SET ��������
name_feat_file = 'feat_set_combined_of_tless_prac_seg_60_using_ch4';
load(fullfile(parentdir,'DB','ProcessedDB',name_feat_file));
Features = feat_set_combined; clear feat_set_combined;

%% feature indexing
% 6channel
idx_feat.CC = 1:24;
idx_feat.RMS = 25:30;
idx_feat.SampEN = 31:36;
idx_feat.WL = 37:42;

% when using DB of ch4 ver
if strfind(name_feat_file,'ch4')
    idx_feat.CC = 1:16;
    idx_feat.RMS = 17:20;
    idx_feat.SampEN = 21:24;
    idx_feat.WL = 25:28;
end

% feat names and indices
names_feat = fieldnames(idx_feat);
idx_feat = struct2cell(idx_feat);
N_ftype = length(names_feat);

% makeing folder for results ��� ���� ���� ����
folder_name2make = ['T5_',name_feat_file]; % ���� �̸�
path_made = make_path_n_retrun_the_path(fullfile(parentdir,...
    'DB','dist'),folder_name2make); % ��� ���� ���� ���

for i_FeatName = 4
disp(names_feat{i_FeatName});
TEMP_FEAT = Features(:,idx_feat{i_FeatName} ,:,:,:);

% eval(sprintf('TEMP_FEAT = L.%s;',FeatNames{i_FeatName}));

[N_Seg, N_Feat, N_FE, N_trial, N_sub] = size(TEMP_FEAT);
TEMP_FEAT = permute(TEMP_FEAT,[2,1,3,4,5]);%[N_Feat, N_Seg,  N_FE, N_trial,N_sub]
Kfold = 10;
Idx_Seg = 1 : N_Seg;
Idx_FE = 1 : N_FE;
Idx_N_trial = 1 : N_trial;
Idx_N_sub = 1 : N_sub;

% window_width = 3;
% max_slope_length = 2;
% speedup_mode = 1;
% DTW_opt.nDivision_4Resampling = 10; DTW_opt.max_slope_length = 3; DTW_opt.speedup_mode = 1;
N_rep = 10;
Idx_dist = 1 : N_trial*(N_sub-1);
Idx_dist = reshape(Idx_dist,[N_trial,(N_sub-1)]);

% eval(sprintf('%s = cell(30,20,63,8);',FeatNames{i_FeatName}));
T = cell(N_Seg,N_FE);
for i_sub = 23 : N_sub
    for i_trial = 1 : N_trial
        tic;
        for i_seg = 1 : N_Seg
            fprintf('%s i_sub:%d i_trial:%d i_seg:%d\n',names_feat{i_FeatName},i_sub,i_trial,i_seg);
            for i_FE = 1 : N_FE
                temp = TEMP_FEAT(:,i_seg,i_FE,i_trial,i_sub);
                temp_x = permute(TEMP_FEAT(:,i_seg,i_FE,:,i_sub),[1 4 2 3]);
                IDX_sub = find(Idx_N_sub~=i_sub);
                temp_y = TEMP_FEAT(:,i_seg,i_FE,:,IDX_sub);
                temp_y = reshape(temp_y,[N_Feat, N_trial*(N_sub-1)]);
                
                % just get 5 similar features
                T{i_seg,i_FE} = dtw_search_n_transf(temp, temp_y, 5);
            end
        end
        toc
        % save at directory of DB\dist 
        save(fullfile(path_made,['T_',num2str(i_sub),'_',...
            num2str(i_trial),'_',names_feat{i_FeatName},'_5.mat']),'T');
    end
end
%     save(fullfile(cd,'test',['T_',FeatNames{i_FeatName}]),FeatNames{i_FeatName});
end           


function [xt] = dtw_search_n_transf(x1, x2, N_s)
% parameters
window_width = 3;
max_slope_length = 2;
speedup_mode = 1;
DTW_opt.nDivision_4Resampling = 10;
DTW_opt.max_slope_length = 3;
DTW_opt.speedup_mode = 1;

[N_f, N]= size(x2); dist = zeros(N,1);
for i = 1 : N
    dist(i) = fastDTW(x1, x2(:,i),max_slope_length, ...
        speedup_mode, window_width );
end
% Sort
[~, sorted_idx] = sort(dist);
% xs= x2(:,sorted_idx(1:N_s));
xt = zeros(N_f,N_s);
for i = 1 : N_s
    xt(:,i)= transfromData_accRef_usingDTW(x2(:,sorted_idx(i)), x1, DTW_opt);
end
end


