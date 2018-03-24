clc; close all; clear all;
addpath(genpath(fullfile(cd,'functions')));

for k=4:4
%% Feature SET 가져오기
% % load(fullfile(cd,'result','Features_extracted17_08_30_120657_'));
load(fullfile(cd,'result',sprintf('Features_extrated_notch_CC4_%d', k)))

[N_Seg, N_Feat, N_FE, N_trial, N_sub] = size(Features);
Features= permute(Features,[3,1,4,5,2]); %[N_FE, N_Seg, N_trial, N_sub, N_Feat]
Features = reshape(Features,[N_FE*N_Seg*N_trial*N_sub,N_Feat]); %[N_FE*N_Seg*N_trial*N_sub, N_Feat]
Labels = repmat((1:N_FE)',[N_Seg*N_trial*N_sub,1]);
idx_sub = zeros(N_FE*N_Seg*N_trial*N_sub,1);
for i_sub = 1 : N_sub
    idx_sub(N_FE*N_Seg*N_trial*(i_sub-1)+1:N_FE*N_Seg*N_trial*(i_sub)) = i_sub*ones(N_FE*N_Seg*N_trial,1);
end

%% 피험자 별로 Validation (My Own Cross validation)
load('pairset_new.mat'); % training 수를 줄여가면서 Validation
acc = zeros(N_sub,N_trial);
mean_acc = zeros(N_Seg,N_trial-1);
for n_pair = 1 : N_trial-1;
    pair = pairset_new{n_pair};
for i_sub = 1 : N_sub

    temp_feat = Features(idx_sub==i_sub,:);
    temp_label = Labels(idx_sub==i_sub);
    
    idx_trial = zeros(N_FE*N_Seg*N_trial,1);
    for i_tral = 1 : N_trial
        idx_trial(N_FE*N_Seg*(i_tral-1)+1:N_FE*N_Seg*(i_tral)) = i_tral*ones(N_FE*N_Seg,1);
    end
    
    for i_tral = 1 : N_trial
        idx2train = zeros(N_FE*N_Seg*N_trial,1);
        for ii = 1 : n_pair
            idx2train = [idx2train + double(idx_trial==pair(i_tral,ii))];
        end
        idx2train = logical(idx2train);
        temp_f = temp_feat(idx2train,:);
        temp_l = temp_label(idx2train);       
           
        %% LDA
%         model_LDA = fitcdiscr(temp_f, temp_l);
        
        %% K-NN
%         model_KNN = fitcknn(temp_f, temp_l, 'NumNeighbors',5, 'Standardize',1);
        
        %% SVM
        model= svmtrain(temp_l, temp_f,'-s 1 -t 0 -q');
        
        temp_f = temp_feat(~idx2train,:);
        temp_l = temp_label(~idx2train);
        
        
        %% LDA predict
%         [temp_pred,~,~] = predict(model_LDA, temp_f);
        
        %% KNN predict
%         [temp_pred,~,~] = predict(model_KNN, temp_f);
        
        %% SVM predict        
        [temp_pred,~,~] = svmpredict(temp_l,temp_f, model);
        
        temp_pred = reshape(temp_pred,[N_FE,N_Seg,N_trial-n_pair]);
        
        % final decision using majoriy voting
        for n_seg = 1 : N_Seg
            maxv = zeros(N_FE,N_trial-n_pair); final_predict = zeros(N_FE,N_trial-n_pair);
            for i = 1 : N_FE
                for j = 1 : N_trial-n_pair
                    [maxv(i,j),final_predict(i,j)] = max(countmember(1:N_FE,temp_pred(i,1:n_seg,j)));
                end
            end
            final_predict = final_predict(:);
            acc(i_sub,i_tral,n_seg) = sum(repmat((1:N_FE)',[N_trial-n_pair,1])==final_predict)/(N_FE*N_trial-N_FE*n_pair)*100;
        end
        % Confurm 1차,2차 피험자 평균
%         temp = mat2cell(acc,[10,20],[20],[60]);
%         acc1st = temp{1};
%         acc2nd = temp{2};
%         for n_seg = 1 : N_Seg
%             mean_acc_1st(n_seg,1) = mean(mean(acc1st(:,:,n_seg)));
%             mean_acc_2nd(n_seg,1) = mean(mean(acc2nd(:,:,n_seg)));
%         end
    end
end

for n_seg = 1 : N_Seg
    mean_acc(n_seg,n_pair) = mean(mean(acc(:,:,n_seg)));
end
end

%% 결과 저장
% formatOut = 'yy_mm_dd_HHMMSS_';
% current_time=datestr(now,formatOut);
% 
% save(fullfile(cd,'final_result',...
%     ['Final_mean_acc',current_time]),'mean_acc');

save(fullfile(cd,'final_result',sprintf('CC4_Final_mean_acc_SVM_%d', k)),'mean_acc');
end


