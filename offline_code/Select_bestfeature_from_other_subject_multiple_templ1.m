%----------------------------------------------------------------------
% developed by Ho-Seung Cha, Ph.D Student,
% CONE Lab, Biomedical Engineering Dept. Hanyang University
% under supervison of Prof. Chang-Hwan Im
% All rights are reserved to the author and the laboratory
% Distance�� ������ �ڽ��� FV��� ������ FV �������� ù��° �ڵ�
% contact: hoseungcha@gmail.com
%---------------------------------------------------------------------
clear all; clc; close all
addpath(genpath(fullfile(cd,'functions')));

% load('dist_FULL_org_ver.mat')
featureType = 7;
load([num2str(featureType),'_dist_FULL_combined.mat']);
N_Repeat = 20;
N_subject = 30;
N_FE = 8;
comm_idx_emotion = find(dist_FULL(:,5)==dist_FULL(:,6));
% min_dist = cell(N_Repeat,N_subject);
recommanded_other_sub = cell(N_Repeat,N_subject);
tw_dist = cell(N_subject,N_Repeat,N_FE);
euc_dist = cell(N_subject,N_Repeat,N_FE);
pattn_sim = cell(N_subject,N_Repeat,N_FE);

h = timebar('Loop counter','Progress');
count = 1;
for i_templ_sub1 = 1 : N_subject
        for i_emotion = 1 : N_FE
            for i_templ_dat1 = 1 : N_Repeat
            
                idx_templ_sub1 = find(dist_FULL(:,1)==i_templ_sub1);
                idx_templ_dat1 = find(dist_FULL(:,3)==i_templ_dat1);
                
                idx_templ_sub2 = find(dist_FULL(:,2)~=i_templ_sub1);
                idx_templ_emo = find(dist_FULL(:,5)==i_emotion);
                
                
                idx_other_data = mintersect(comm_idx_emotion,...
                    idx_templ_sub1,idx_templ_dat1,...
                    idx_templ_sub2,...
                    idx_templ_emo);
                % DTW �� Sorting
                sorted = sortrows(dist_FULL(idx_other_data,:),7);
                tw_dist{i_templ_sub1,i_templ_dat1,i_emotion} = ...
                    sorted(:,[2,4,7,8,9]); 
%                 % Euclidian ���� Sorting
%                 sorted = sortrows(dist_FULL(idx_other_data,:),8);
%                 euc_dist{i_templ_sub1,i_templ_dat1,i_emotion}= ...
%                     sorted(1:N_compensated,[2,4,7,8,9]); 
%                 % Rank ���� Sorting
%                 sorted = sortrows(dist_FULL(idx_other_data,:),9);
%                 sorted = flipud(sorted);
%                 pattn_sim{i_templ_sub1,i_templ_dat1,i_emotion}= ...
%                       sorted(1:N_compensated,[2,4,7,8,9]); 
                count = count + 1;
                timebar(h,count/(N_subject*N_FE*N_Repeat));
            end
        end
        
end
% save('selected_data_vari_cond.mat','tw_dist');
save([num2str(featureType),'selected_data_index_using_DTW_combined'],'tw_dist');