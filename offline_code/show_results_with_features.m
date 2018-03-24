clc; close all; clear all;
F_name = {'CC';'RMS';'SampEN';'WL'};

accs = [];
featnames = [];
count = 0;
for N_featpair = 4
idx_F = nchoosek(1:length(F_name),N_featpair);
for i_feat = 1 : size(idx_F,1)
    count = count + 1;
    temp_str =[];
    for i_featp = 1 : size(idx_F,2)
        feat_name  = F_name{idx_F(i_feat,i_featp)};
        temp_str = [temp_str sprintf('F.%s,',feat_name)];
    end
    temp_str(end) = []; 
    load(fullfile(cd,'result','0.1_increase_°á°ú',[temp_str,'._FearR.mat']))
    % plot RESULT

    lda_result = permute(mean(mean(acc.lda,2),3),[1 4 2 3])
    knn_result = permute(mean(mean(acc.knn,2),3),[1 4 2 3])
    svm_result = permute(mean(mean(acc.svm,2),3),[1 4 2 3])
    
    temp = [lda_result,knn_result,svm_result];
    
    %
    accs = [accs; temp(15,:)];
    featnames{count,1} = temp_str;
end
end
plot2result = permute(mean(acc.lda(15,:,:,:),2),[3 4 1 2]);
hf = figure;
bar(plot2result)
% h = bar(acc);
% Featname = {'SE','RMS','WL','CC','SE+RMS','SE+WL','SE+CC','RMS+WL',...
%     'RMS+CC','WL+CC','SE+RMS','SE+RMS+CC','SE+WL+CC','RMS+WL+CC',...
%     'SE+RMS+WL+CC'};
hf.Color = [1 1 1];
hf.Children.YLim = [0 100];
hf.Children.XTickLabelRotation = 0;
hf.Children.FontName = 'Times New Roman';
hf.Children.FontWeight = 'bold';
hf.Children.FontSize = 18;
hl = legend;
hl.String = {'Not using DB','Using DB'}