% 2017.09.11 에 DTW적요이 잘안되기도 하고, 새로운 Feat 조합을 찾기위한 코드
% 2017.11.11 0.1초 increase 적용, Fear 없애서 다시 최적의 조합 Feat 탐색
clc; close all; clear all;
parentdir=fileparts(fileparts(fileparts(pwd)));
addpath(genpath(fullfile(parentdir,'functions')));
%% Feature SET 가져오기
% F = load(fullfile(cd,'result','17_09_18_172929_Features_extracted'));
% F = rmfield(F,'params'); F_name = fieldnames(F);
load(fullfile(parentdir,'DB','ProcessedDB','FEATS_통합.mat'));

% feature indexing
idx_feat_CC = 1:24;
idx_feat_RMS = 25:30;
idx_feat_SampEN = 31:36;
idx_feat_WL = 37:42;

% feature 별로 추출
F.CC = Features(:,idx_feat_CC,:,:,:);
F.RMS = Features(:,idx_feat_RMS,:,:,:);
F.SampEN = Features(:,idx_feat_SampEN,:,:,:);
F.WL = Features(:,idx_feat_WL,:,:,:);

% sturct to cell and naming each feature
F_name = fieldnames(F);
F_cell = struct2cell(F);


clear idx_feat_CC idx_feat_RMS idx_feat_SampEN idx_feat_WL

% window segments, number of trials(repetition), number of subjects
[N_Seg, ~, ~, N_trial, N_sub] = size(F.WL);



% setting number of similar features to be used in datasets
N_Total_comp = 1;

% memory allocations for accurucies of classification algorithms
acc.svm = zeros(N_Seg,N_trial,N_sub,N_Total_comp+1);
acc.lda = zeros(N_Seg,N_trial,N_sub,N_Total_comp+1);
acc.knn = zeros(N_Seg,N_trial,N_sub,N_Total_comp+1);

% feat_count = 0;
% for N_featpair = 1 : length(F_name)
for N_featpair = 4  % choose numbe of feature pairs. % 참고: feature 4개 사용했을 때 결과 좋음
    idx_F = nchoosek(1:length(F_name),N_featpair);
    
    % search similar features (transformed features) from Dataset by using DTW
    for i_feat = 1 : size(idx_F,1)
        % get each feat size
        feat_size = cellfun(@(x) size(x,2),F_cell);
        % concatinating dataset by features
        temp_feat = cat(2,F_cell{:});
        
        % reject an expression which evoke confusion
        idx2reject = 4; % 참고: 4: Fear, 3: Disgusted, 2개 표정이 confusion 많이 일으킴
        temp_feat(:,:,idx2reject,:,:) = [];
        [~, N_Feat, N_FE, ~, ~] = size(temp_feat);
        
        % training 수를 줄여가면서 Validation
        % train DB를 20가지중에 선택할 때, 랜덤하게 선택 총 반복횟수 정하기
        load('pairset_new.mat'); 
        pair = pairset_new{1};
        n_pair = 1;
        
        % get indices of trials
        Idx_trial = 1 : N_trial;
        
        % IDX_comp = 10 : 10 : 100; IDX_comp = [1, IDX_comp];
        % IDX_comp = 1 : 100;
        % N_Total_comp = length(IDX_comp);
        
        % get result
        pred.svm = cell(N_sub,N_trial,N_Total_comp+1);
        pred.lda = cell(N_sub,N_trial,N_Total_comp+1);
        pred.knn = cell(N_sub,N_trial,N_Total_comp+1);
        pred.label = cell(N_sub,N_trial,N_Total_comp+1);
        fin_pred.svm = cell(N_sub,N_trial,N_Total_comp+1);
        fin_pred.lda = cell(N_sub,N_trial,N_Total_comp+1);
        fin_pred.knn = cell(N_sub,N_trial,N_Total_comp+1);
        
        for N_comp = 0 : N_Total_comp
            for i_sub = 1 : N_sub
                fprintf('%s i_sub: %d \n',temp_str,i_sub);
                for i_trl = 1:N_trial
                    train = temp_feat(:,:,:,Idx_trial==pair(i_trl,n_pair),i_sub);
                    train = permute(train,[1 3 2]);
                    train = reshape(train, [N_Seg*N_FE, size(train,3)]);
                    label = repmat(1:N_FE,[N_Seg,1]); label = label(:);
                    if (N_comp>0) %%%%%%%%%compensating%%%%%%%%%%%%%%%%%%%%%%%%%%
                        comp_d = cell(size(idx_F,2),1); labe_d = cell(size(idx_F,2),1);
                        for i_featp = 1 : size(idx_F,2)
                            count = 1;
                            comp_d{i_featp} = zeros(N_FE*N_Seg,feat_size(i_featp));
                            labe_d{i_featp} = zeros(length(comp_d{i_featp}),1);
                            feat_name  = F_name{idx_F(i_feat,i_featp)};
                            load(fullfile(cd,'dist','T',['T_',num2str(i_sub),'_',...
                                num2str(i_trl),'_',feat_name,'_2.mat']));
                            T(:,idx2reject) = [];
                            for i_FE = 1 : N_FE
                                for i_seg = 1 : N_Seg
                                    for i_comp = 1 : N_comp
                                        comp_d{i_featp}(count,:) = T{i_seg,i_FE}(:,i_comp)';
                                        labe_d{i_featp}(count) = i_FE;
                                        count = count + 1 ;
                                    end
                                end
                            end
                            comp_d{i_featp} = comp_d{i_featp}';
                        end
                        
                        t = [train;cell2mat(comp_d)']; l = [label;labe_d{1}];
                    else%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        t = train;  l = label;
                    end
                    % train machine lerning model
                    model.svm= svmtrain(l , t,'-s 1 -t 0 -b 1 -q');
                    model.lda = fitcdiscr(t,l);
                    model.knn = fitcknn(t,l,'NumNeighbors',5);
                    % test data
                    test =  temp_feat(:,:,:,~logical(countmember(Idx_trial,pair(i_trl,:))),i_sub);
                    test = permute(test,[1 4 3 2]);
                    test = reshape(test, [N_Seg*(N_trial-n_pair)*N_FE, size(test,4)]);
                    label = repmat(1:N_FE,[N_Seg*(N_trial-n_pair),1]); label = label(:);
                    % test
                    
                    pred.svm{i_sub,i_trl,N_comp+1} = svmpredict(label,test, model.svm,'-b 1 -q');
                    pred.lda{i_sub,i_trl,N_comp+1} = predict(model.lda,test);
                    pred.knn{i_sub,i_trl,N_comp+1} = predict(model.knn,test);
                    pred.label{i_sub,i_trl,N_comp+1} = label;
                    
                    pred_svm = reshape(pred.svm{i_sub,i_trl,N_comp+1},[N_Seg,((N_trial-n_pair)),N_FE]);
                    pred_lda = reshape(pred.lda{i_sub,i_trl,N_comp+1},[N_Seg,((N_trial-n_pair)),N_FE]);
                    pred_knn = reshape(pred.knn{i_sub,i_trl,N_comp+1},[N_Seg,((N_trial-n_pair)),N_FE]);
                    
                    fin_pred.svm{i_sub,i_trl,N_comp+1} = majority_vote(pred_svm);
                    fin_pred.lda{i_sub,i_trl,N_comp+1} = majority_vote(pred_lda);
                    fin_pred.knn{i_sub,i_trl,N_comp+1} = majority_vote(pred_knn);
                    
                    for n_seg = 1 : N_Seg
                        acc.svm(n_seg,i_trl,i_sub,N_comp+1) = sum(repmat((1:N_FE)',...
                            [(N_trial-n_pair),1]) == fin_pred.svm{i_sub,i_trl,N_comp+1}(:,n_seg))...
                            /((N_trial-n_pair)*N_FE)*100;
                        acc.lda(n_seg,i_trl,i_sub,N_comp+1) = sum(repmat((1:N_FE)',...
                            [(N_trial-n_pair),1]) == fin_pred.lda{i_sub,i_trl,N_comp+1}(:,n_seg))...
                            /((N_trial-n_pair)*N_FE)*100;
                        acc.knn(n_seg,i_trl,i_sub,N_comp+1) = sum(repmat((1:N_FE)',...
                            [(N_trial-n_pair),1]) == fin_pred.knn{i_sub,i_trl,N_comp+1}(:,n_seg))...
                            /((N_trial-n_pair)*N_FE)*100;
                    end
                end
                figure(N_comp+1);plot(permute(mean(mean(acc.lda(:,:,1:i_sub,1:(N_comp+1)),3),2),[1 4 2 3]));drawnow;
            end
        end
        save(fullfile(cd,'result',[temp_str,'._FearR_mat']),'acc','pred','fin_pred');
    end
end
