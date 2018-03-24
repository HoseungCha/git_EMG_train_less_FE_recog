%----------------------------------------------------------------------
% developed by Ho-Seung Cha, Ph.D Student,
% CONE Lab, Biomedical Engineering Dept. Hanyang University
% under supervison of Prof. Chang-Hwan Im
% All rights are reserved to the author and the laboratory
% 새로운 Feature로 DTW 이용하여, 거리값 계산하는 코드
% contact: hoseungcha@gmail.com
%---------------------------------------------------------------------

clc; close all; clear all;
addpath(genpath(fullfile(cd,'functions')));
%% Feature SET 가져오기
load(fullfile(cd,'result','17_08_16_154133_Features_extracted'));
[N_Seg, N_Feat, N_FE, N_trial, N_sub] = size(Features);
Features= permute(Features,[1,3,4,5,2]);
Features = reshape(Features,[N_Seg*N_FE*N_trial*N_sub,N_Feat]);
% Labels = repmat((1:N_FE)',[N_Seg*N_trial*N_sub,1]);
idx_sub = zeros(N_FE*N_Seg*N_trial*N_sub,1);
for i = 1 : N_sub
    idx_sub(N_FE*N_Seg*N_trial*(i-1)+1:N_FE*N_Seg*N_trial*(i)) = i*ones(N_FE*N_Seg*N_trial,1);
end

% Training Examples 별 DTW 계산
window_width = 3;
max_slope_length = 2;
speedup_mode = 1;


count = 1;
% dist_FULL = zeros((N_trial^2)*(N_FE^2)*(N_Seg^2), 5);
idx_i_sub1 = 19:20
idx_i_sub2 = 1:30;
% saving 준비
N_results = (length(idx_i_sub2)-1)*(N_trial^2)*(N_FE);
dist = zeros(N_results, 1);
h = timebar('Loop counter','Progress');
        
for i_sub1 = idx_i_sub1
	count = 1;
    feat111 = Features(idx_sub==i_sub1,:); % Total -> filter(subject) -> data(N_Seg, N_Feat, N_FE, N_trial)
%     for i_sub2 = 1 : N_sub
    for i_sub2 = idx_i_sub2
        [i_sub1,i_sub2]
        if(i_sub2 ==i_sub1)
            continue;
        end
        feat222 = Features(idx_sub==i_sub2,:); % Total -> filter(subject)-> data(N_Seg, N_Feat, N_FE, N_trial)
        Idx_trial1 = zeros(N_Seg*N_FE*N_trial,1);idx_trial2 = zeros(N_Seg*N_FE*N_trial,1);
        
        
        for i_trial1 = 1 : N_trial
            Idx_trial1(N_Seg*N_FE*(i_trial1-1)+1:N_Seg*N_FE*(i_trial1)) = i_trial1*ones(N_Seg*N_FE,1);
            feat11 = feat111(Idx_trial1==i_trial1,:); % Total -> filter(subject,trial) -> data(N_Seg, N_Feat, N_FE)
            for i_trial2 = 1 : N_trial
                Idx_trial2(N_Seg*N_FE*(i_trial2-1)+1:N_Seg*N_FE*(i_trial2)) = i_trial2*ones(N_Seg*N_FE,1);
                feat22 = feat222(Idx_trial2==i_trial2,:); % Total -> filter(subject,trial) -> data(N_Seg, N_Feat, N_FE)
                Idx_FE1 = zeros(N_Seg*N_FE,1);Idx_FE2 = zeros(N_Seg*N_FE,1);
                for i_FE1 = 1 : N_FE
                    Idx_FE1(N_Seg*(i_FE1-1)+1:N_Seg*(i_FE1))= i_FE1*ones(N_Seg,1);
                    feat1 = feat11(Idx_FE1==i_FE1,:)'; % Total -> filter(subject,trial,FE) -> data(N_Seg, N_Feat)
                    feat2 = feat22(Idx_FE1==i_FE1,:)'; % Total -> filter(subject,trial,FE)-> data(N_Seg, N_Feat)
                    [dist(count,:), ~, ~] = fastDTW(feat1(:), feat2(:),...
                                max_slope_length, speedup_mode, window_width );
                    count = count + 1;
                end
                timebar(h,count/N_results);
            end
        end
    end
    save([num2str(i_sub1),'dist.mat'],'dist','-v7.3')
end
