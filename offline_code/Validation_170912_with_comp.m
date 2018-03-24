% 2017.09.11 에 DTW적요이 잘안되기도 하고, 새로운 Feat 조합을 찾기위한 코드
clc; close all; clear all;
addpath(genpath(fullfile(cd,'functions')));
%% Feature SET 가져오기
F = load(fullfile(cd,'result','17_09_11_233036_Features_extracted'));
F_name = fieldnames(F);
N_feat_analyasis = 1;
N_Total_comp = 2;
acc = zeros(60,20,30,N_feat_analyasis,N_Total_comp+1);
feat_count = 0; 
i_featp = 2;
idx_F = nchoosek(1:length(F_name),i_featp);

for i_feat = 4
    feat_count = feat_count + 1;
    temp_str =[];
    for i_featp = 1 : size(idx_F,2)
        feat_name  = F_name{idx_F(i_feat,i_featp)};
        feat_size(i_featp) =  eval(sprintf('size(F.%s,2),',feat_name));
        temp_str = [temp_str sprintf('F.%s,',feat_name)];
    end
    temp_str(end) = []; 
    eval(sprintf('Features = cat(2,%s);',temp_str));
% else
%     eval(sprintf('Features = F.%s;',F_name{i_feat}));
% end
[N_Seg, N_Feat, N_FE, N_trial, N_sub] = size(Features);

load('pairset_new.mat'); % training 수를 줄여가면서 Validation
pair = pairset_new{1};
n_pair = 1; N_total_comp = 11;

IDX_trl = 1 : 20;
for N_comp = 0 : N_Total_comp
for i_sub = 1:30
    fprintf('%s i_sub: %d \n',temp_str,i_sub);
    for i_trl = 1:20        
        train = Features(:,:,:,IDX_trl==pair(i_trl,n_pair),i_sub);
        train = permute(train,[1 3 2]);
        train = reshape(train, [60*8, size(train,3)]);
        label = repmat(1:8,[60,1]); label = label(:);
        if (N_comp>0) %%%%%%%%%compensating%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            comp_d = cell(size(idx_F,2),1); labe_d = cell(size(idx_F,2),1); 
            for i_featp = 1 : size(idx_F,2)
                count = 1;
                comp_d{i_featp} = zeros(N_FE*N_Seg*N_comp,feat_size(i_featp)); 
                labe_d{i_featp} = zeros(length(comp_d{i_featp}),1);
                feat_name  = F_name{idx_F(i_feat,i_featp)};
                load(fullfile(cd,'dist','T',['T_',num2str(i_sub),'_',...
                num2str(i_trl),'_',feat_name]));
                for i_FE = 1 : N_FE
                    for i_seg = 1 : N_Seg    
                        for i_comp = 1 : N_comp
                            comp_d{i_featp}(count,:) = T{i_seg,i_FE,i_comp}'; 
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
        model= svmtrain(l , t,'-s 1 -t 0 -b 1 -q');
        
        test =  Features(:,:,:,IDX_trl~=pair(i_trl,n_pair),i_sub);
        test = permute(test,[1 4 3 2]);
        test = reshape(test, [60*19*8, size(test,4)]);
        label = repmat(1:N_FE,[60*(20-n_pair),1]); label = label(:);
        
        % test
        [temp_pred,~,~] = svmpredict(label,test, model,'-b 1 -q');
        temp_pred = reshape(temp_pred,[N_Seg,(20-n_pair),N_FE]);
        % final decision using majoriy voting
        for n_seg = 1 : N_Seg
            maxv = zeros(N_FE,20-n_pair); final_predict = zeros(N_FE,20-n_pair);
            for i = 1 : N_FE
                for j = 1 : 20-n_pair
                    [maxv(i,j),final_predict(i,j)] = max(countmember(1:N_FE,temp_pred(1:n_seg,j,i)));
                end
            end
            final_predict = final_predict(:);
            acc(n_seg,i_trl,i_sub,feat_count,N_comp+1) = sum(repmat((1:N_FE)',[20-n_pair,1])==final_predict)/(N_FE*N_trial-N_FE*n_pair)*100;
        end
    end
    figure(N_comp+1);plot(permute(mean(mean(acc(:,:,1:i_sub,feat_count,1:N_comp+1),3),2),[1 5 2 3 4]));drawnow;
end
end
save(fullfile(cd,'result',[datestr(now,'yyddmm_HHMM_'),temp_str,'.mat']),'acc');
end
% end
