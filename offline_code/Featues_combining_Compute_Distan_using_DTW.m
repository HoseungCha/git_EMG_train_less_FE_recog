for i_feat = 1 : 7
    load([num2str(i_feat),'_dist_FULL_combined.mat']);
    dist_total_result{i_feat} = dist_FULL;
end
save('dist_FULL_combined.mat','dist_total_result');