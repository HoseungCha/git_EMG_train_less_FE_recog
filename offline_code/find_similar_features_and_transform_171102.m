%--------------------------------------------------------------------------
% developed by Ho-Seung Cha, Ph.D Student,
% CONE Lab, Biomedical Engineering Dept. Hanyang University
% under supervison of Prof. Chang-Hwan Im
% All rights are reserved to the author and the laboratory
% contact: hoseungcha@gmail.com
% 2017.09.13 DTW변환 100개 늘림(함수로 간략화시킴)
% 2017 11.02 0.1초 증가에따라 segment 갯수가 30개임
%--------------------------------------------------------------------------

clc; close all; clear all;
addpath(genpath(fullfile(cd,'functions')));
%% Feature SET 가져오기
load(fullfile(cd,'result','FEATS_통합.mat'));
L.CC = Features(:,1:24,:,:,:);
L.RMS = Features(:,25:30,:,:,:);
L.SampEN = Features(:,31:36,:,:,:);
L.WL = Features(:,37:42,:,:,:);
FeatNames = fieldnames(L);
for i_FeatName = 1

eval(sprintf('TEMP_FEAT = L.%s;',FeatNames{i_FeatName}));
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
for i_sub = 26 : 30
    for i_trial = 1 : N_trial
        
        tic;
        for i_seg = 1 : N_Seg
            fprintf('%s i_sub:%d i_trial:%d i_seg:%d\n',FeatNames{i_FeatName},i_sub,i_trial,i_seg);
            for i_FE = 1 : N_FE
                temp = TEMP_FEAT(:,i_seg,i_FE,i_trial,i_sub);
                temp_x = permute(TEMP_FEAT(:,i_seg,i_FE,:,i_sub),[1 4 2 3]);
                IDX_sub = find(Idx_N_sub~=i_sub);
                temp_y = TEMP_FEAT(:,i_seg,i_FE,:,IDX_sub);
                temp_y = reshape(temp_y,[N_Feat, N_trial*(N_sub-1)]);
                T{i_seg,i_FE} = dtw_search_n_transf(temp, temp_y, 2);
            end
        end
        toc
        save(fullfile(cd,'dist','T',['T_',num2str(i_sub),'_',...
            num2str(i_trial),'_',FeatNames{i_FeatName},'_2.mat']),'T');
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


