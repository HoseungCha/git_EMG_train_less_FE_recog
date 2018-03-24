%----------------------------------------------------------------------
% developed by Ho-Seung Cha, Ph.D Student,
% CONE Lab, Biomedical Engineering Dept. Hanyang University
% under supervison of Prof. Chang-Hwan Im
% All rights are reserved to the author and the laboratory
% Distance�� ������ �ڽ��� FV��� ������ FV �������� �ι�° �ڵ�
% contact: hoseungcha@gmail.com
%---------------------------------------------------------------------
clc; close all; clear all;
addpath(genpath(fullfile(cd,'functions')));

featureType = 7;
load([num2str(featureType),'selected_data_index_using_DTW_combined']);
load('pairset_new.mat')
N_i_pair = 19;
N_sub = size(tw_dist,1);
N_emotion = size(tw_dist,3);
N_trials = size(tw_dist,2);
candi_ver2 = cell(N_sub,N_emotion,N_i_pair,N_trials);

h = timebar('Loop counter','Progress');
Lcount = 1;
for i_pair = 1 : N_i_pair
    indx_Trset4valid = pairset_new{i_pair};
    N_pair = size(indx_Trset4valid,1);
    % check equalty cadnidates feats from templs
    % comb = nchoosek(indx_Trset4valid(2,:),2);
    
    for i_sub4valid = 1 : N_sub;
        for i_emotion = 1 : N_emotion;
            for i_teplpair = 1 : N_pair
                ind_templts = indx_Trset4valid(i_teplpair,:);
                % �� FV���� �Ÿ������� ���ĵ� �ĺ� ��ǥ �ҷ�����
                str2eval=[]; str2o=[];
                tmpcell = cell(i_pair,1); tmp = cell(i_pair,1); 
                tmp_dtwV = cell(i_pair,1);
                for i = 1 : i_pair
                    temppp = tw_dist{i_sub4valid, ind_templts(i),...
                        i_emotion}(:,1:3);
                    tmp{i,1} = temppp(:,1:2);  % DTW �Ÿ� ���� �ҷ�����
                    tmp_dtwV{i,1} = temppp(:,3); 
                    tmpstr = num2str(tmp{i,1});
                    tmpcell{i,1} = mat2cell(tmpstr,ones([size(tmpstr,1),1]),size(tmpstr,2));
                    str2eval = [str2eval, sprintf('tmpcell{%d,1},',i)];
                    str2o = [str2o, sprintf('i%d,',i)];
                end
                str2eval(end)=[]; str2o(end)=[];
                % �ĺ� ��ǥ���� ���� ��ǥ�� ã��
                eval(sprintf('[C] = mintersect(%s);',str2eval));
                
                if i_pair ~= 1
                    % pair�� 2���� ���� �� ���ĵ� rank�� ���� �̿���,
                    % FV���� ���������� ������ FV������� ����
                    idx = zeros(length(C),i_pair);
                    for i = 1 : i_pair
                        [~,idx(:,i)] = intersect(tmpcell{i, 1},C);
                    end
                    % Rank ������ ����
                    sumidx = sum(idx,2); 
                    [~,new_idx] = sort(sumidx);
       
                    temp_new_c = C(new_idx,:);
                    temp_new_c = str2num(cell2mat(temp_new_c));
                    N_new_c = length(C);
                    
                    % DTW ��
                    dtwv_of_idx = zeros(length(C),i_pair);
                    for i = 1 : i_pair
                       dtwv_of_idx(:,i) = tmp_dtwV{i}(idx(:,i));
                    end
                    temp_new_c2 = dtwv_of_idx(new_idx,:);
                    
                else
                    
                    temp_new_c = str2num(cell2mat(C));
                    temp_new_c2 = [];
                    N_new_c = length(C);
                end

                candi_ver2{i_sub4valid,i_emotion,i_pair,i_teplpair}...
                = [temp_new_c,temp_new_c2];
                
                
            end
            Lcount = Lcount + 1;
        end
        timebar(h,Lcount/(N_i_pair*N_sub*N_emotion));
    end
end

save([num2str(featureType),'recommd_indx_FV_combined.mat'],'candi_ver2','-v7.3');
