%2017.09.11 새로운 Feature DTW 계산 및 변환
clc; close all; clear all;
addpath(genpath(fullfile(cd,'functions')));
%% Feature SET 가져오기
L=load(fullfile(cd,'result','17_09_11_160430_Features_extracted'));
FeatNames = fieldnames(L);
N_comp = 10;
for i_FeatName = 1

eval(sprintf('TEMP_FEAT = L.%s;',FeatNames{i_FeatName}));
[N_Seg, N_Feat, N_FE, N_trial, N_sub] = size(TEMP_FEAT);
TEMP_FEAT = permute(TEMP_FEAT,[2,1,3,4,5]);%[N_Feat, N_Seg,  N_FE, N_trial,N_sub]
Kfold = 10;
Idx_Seg = 1 : N_Seg;
Idx_FE = 1 : N_FE;
Idx_N_trial = 1 : N_trial;
Idx_N_sub = 1 : N_sub;

window_width = 3;
max_slope_length = 2;
speedup_mode = 1;
DTW_opt.nDivision_4Resampling = 10; DTW_opt.max_slope_length = 3; DTW_opt.speedup_mode = 1;

Idx_dist = 1 : N_trial*(N_sub-1);
Idx_dist = reshape(Idx_dist,[N_trial,(N_sub-1)]);

% eval(sprintf('%s = cell(30,20,63,8);',FeatNames{i_FeatName}));
T = cell(N_sub,N_trial,N_Seg,N_FE,N_comp);
for i_sub = 15 : N_sub
    for i_trial = 1 : N_trial
        
        tic;
        for i_seg = 1 : N_Seg
            fprintf('i_sub:%d i_trial:%d i_seg:%d\n',i_sub,i_trial,i_seg);
            for i_FE = 1 : N_FE
                temp = TEMP_FEAT(:,i_seg,i_FE,i_trial,i_sub);
                IDX_sub = find(Idx_N_sub~=i_sub);
                temp_y = TEMP_FEAT(:,i_seg,i_FE,:,IDX_sub);
                temp_y = reshape(temp_y,[N_Feat, N_trial*(N_sub-1)]);
                dist = zeros(N_trial*(N_sub-1),1);
                for i = 1 : N_trial*(N_sub-1)
                   dist(i) = fastDTW(temp, temp_y(:,i),...
                                max_slope_length, speedup_mode, window_width ); 
                end                

                % Sort 
                [sorted_dist, sorted_idx] = sort(dist);
                
                % Find features index of Segment, Trials, Subjects
                t1 = zeros(N_trial*(N_sub-1),1);s1 = zeros(N_trial*(N_sub-1),1);
                for i = 1 : N_trial*(N_sub-1)
                    [t1(i),s1(i)] = ind2sub(size(Idx_dist),find(Idx_dist == sorted_idx(i)));
                    s1(i) = IDX_sub(s1(i));
                end
                % Selected
%                 eval(sprintf('%s{i_sub,i_trial,i_seg,i_FE} = [t1,s1];',FeatNames{i_FeatName}));
                % Tramsformation
                for i_comp = 1 : N_comp
                    temp_t= transfromData_accRef_usingDTW...
                    (temp_y(:,sorted_idx(i_comp)), temp, DTW_opt);
                
                    T{i_sub,i_trial,i_seg,i_FE,i_comp} = temp_t;
                end
                
            end
        end
        toc
        save(fullfile(cd,'dist','T',['T_',num2str(i_sub),'_',...
            num2str(i_trial),'_',FeatNames{i_FeatName}]),'T');
    end
end
%     save(fullfile(cd,'test',['T_',FeatNames{i_FeatName}]),FeatNames{i_FeatName});
end           
%                 temp_y = Febp(:,:,i_FE,:,Idx_N_sub~=i_sub);
%                 temp_y = reshape(temp_y,[36, N_Seg*N_trial*(N_sub-1)]);
%                 
%                 dist = zeros(N_Seg*N_trial*(N_sub-1),1);
%                 for i = 1 : N_Seg*N_trial*(N_sub-1)
%                    dist(i) = fastDTW(temp, temp_y(:,i),...
%                                 max_slope_length, speedup_mode, window_width ); 
%                 end
TTT = T;
T = cell(N_Seg,N_FE,N_comp);
for i_sub = 1 : 30
    for i_trl = 1 : 20
        for i_seg = 1 : N_Seg
            for i_FE = 1 : N_FE
                for i_comp = 1 : N_comp
                    T{i_seg,i_FE,i_comp} = TTT{i_sub,i_trl,i_seg,i_FE,i_comp} ;
                end
            end
        end
        save(fullfile(cd,'dist','T',['T_',num2str(i_sub),'_',...
                        num2str(i_trl),'_',FeatNames{i_FeatName}]),'T');
    end
end

