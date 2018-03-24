clc; close all; clear all;
addpath(genpath(fullfile(cd,'functions')));
%% Feature SET 가져오기
load(fullfile(cd,'result','17_08_16_154133_Features_extracted'));
% load(fullfile(cd,'result','17_08_23_164902_Features_extracted_channel4개'));
[N_Seg, N_Feat, N_FE, N_Trl, N_Sub] = size(Features);
Features= permute(Features,[3,1,4,5,2]); %[N_FE, N_Seg, N_trial, N_sub, N_Feat]
Features = reshape(Features,[N_FE*N_Seg*N_Trl*N_Sub,N_Feat]); %[N_FE*N_Seg*N_trial*N_sub, N_Feat]
%% idx 정리
idx_FE = repmat((1:N_FE)',[N_Seg*N_Trl*N_Sub,1]);
idx_Seg = repmat(1:N_Seg,[N_FE,1]);
idx_Seg = repmat(idx_Seg(:),[N_Trl*N_Sub,1]);
idx_Trl = repmat(1:N_Trl,[N_FE*N_Seg,1]);
idx_Trl = repmat(idx_Trl(:),[N_Sub,1]);
idx_Sub =  repmat(1:N_Sub,[N_FE*N_Seg*N_Trl,1]);
idx_Sub = idx_Sub(:);

% option
DTW_opt.nDivision_4Resampling = 10; DTW_opt.max_slope_length = 3; DTW_opt.speedup_mode = 1;

% memory allocation
N_comp = 1;
acc = zeros(N_Seg,N_comp, N_Sub, N_Trl);
n_pair = 1;
for i_comp = 1 : N_comp + 1
    i_comp = i_comp-1;
    
for i_sub = 1 : 1
    load(fullfile(cd,'dist',[num2str(i_sub),'_cand.mat']));
    for i_trl = 1 : N_Trl
        % Training Set
        Trset = zeros(N_FE*(i_comp+1)*60,36); count = 1;
        TrLabel = zeros(length(Trset),1);
        
        for i_FE = 1 : N_FE
        idx = logical((idx_Sub == i_sub).*(idx_Trl ==i_trl).*(idx_FE == i_FE));
        my_own_f = Features(idx,:);
        Trset(count:count+60-1,:) =  my_own_f;
        TrLabel(count:count+60-1,:) = i_FE*ones(60,1);
        count = count + 60;
        % Add similar featrues
            if(i_comp~=0)
            for i_comp = 1 : i_comp      
                idx = logical((idx_Sub == selected{i_trl,i_FE}(i_comp,1)).*...
                    (idx_Trl ==selected{i_trl,i_FE}(i_comp,2)).*(idx_FE == i_FE));
%                 Trset(count:count+60-1,:) = Features(idx,:); 
                % Transformation feature
                temp_f = Features(idx,:);
                my_own_f = my_own_f'; temp_f = temp_f';
                tic
                dataTransformed= transfromData_accRef_usingDTW...
                            (temp_f(:), my_own_f(:), DTW_opt);
                toc;
                dataTransformed = reshape(dataTransformed,[36,60]);
                Trset(count:count+60-1,:) = dataTransformed';
                TrLabel(count:count+60-1,:) = i_FE*ones(60,1);
                count  = count + 60;
            end
            end
        end
        model= svmtrain(TrLabel, Trset,'-s 1 -t 0 -q'); % SVM train
        
        % Test Set
        idx = logical((idx_Sub == i_sub).*(idx_Trl ~=i_trl));
        Teset = Features(idx,:); 
        TeLabel = repmat((1:N_FE)',[length(Teset)/N_FE,1]);

        % 1st operation: classify using SVM
        [temp_pred,~,~] = svmpredict(TeLabel,Teset, model);
        temp_pred = reshape(temp_pred,8,N_Seg,19);
        % final decision using majoriy voting
        for n_seg = 1 : N_Seg
            maxv = zeros(N_FE,20-n_pair); final_predict = zeros(N_FE,20-n_pair);
            for i = 1 : N_FE
                for j = 1 : 20-n_pair
                    [maxv(i,j),final_predict(i,j)] = max(countmember(1:N_FE,temp_pred(i,1:n_seg,j)));
                end
            end
            final_predict = final_predict(:);
            acc(n_seg,i_comp+1,i_sub,i_trl) = sum(repmat((1:N_FE)',[20-n_pair,1])==final_predict)/(length(final_predict))*100;
           
%             disp(acc(i_sub,i_trl,n_seg,N_comp));
        end
    end
end
    mean_acc  = mean(acc,4);
    plot(mean_acc(:,i_comp+1,i_sub)); drawnow; hold on;
end
