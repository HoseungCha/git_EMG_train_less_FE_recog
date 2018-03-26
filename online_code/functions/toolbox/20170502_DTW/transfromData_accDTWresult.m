%data�� DTW ����� ���� transform�ϴ� �Լ�
%data_resampled�� �� �����Ϳ��� resampling �� ������, 
%match_pair_ref_test�� ref, test ���� DTW ���,
%nDivision_4Resampling�� Resampling �� ���� division�� ũ���̴�.
%
% designed & coded by Dr. Won-Du Chang
% last modified 2017.05.03
function [d_trans,pos_ref_exact_,pos_test_estimated_] = transfromData_accDTWresult(data_resampled_test, data_resampled_ref, match_pair_ref_test, nDivision_4Resampling)
    lenResampled = size(data_resampled_test,1);
    lenOriginal = (lenResampled -1)/nDivision_4Resampling +1;
    d_trans = zeros(lenOriginal,1);
    pos_test_estimated_ = zeros(lenOriginal,1);
    pos_ref_exact_ = zeros(lenOriginal,1);
    idx_start2search = 1;
    for i=1:lenOriginal
        pos_ref_exact = (i -1) *nDivision_4Resampling +1;
        [pos_test_estimated, idx_start2search] = findNearestPoint_InMatchPairRef(match_pair_ref_test,pos_ref_exact, data_resampled_ref,idx_start2search);
        d_trans(i) = data_resampled_test(pos_test_estimated);
        pos_test_estimated_(i) = pos_test_estimated;
        pos_ref_exact_(i) = pos_ref_exact;
    end
end

%match pair�� �����ϴ� ref ������ �� ���� ����� �����͸� ã�´�.
function [pos_test_estimated, idx_start2search] = findNearestPoint_InMatchPairRef(match_pair_ref_test,pos_ref_exact, data_resampled_ref, idx_start2search)
    idx_matchPair = -1;
    len_match_pair = size(match_pair_ref_test,1);
    for i=idx_start2search:len_match_pair
        cur = len_match_pair - i - 1;
        if pos_ref_exact== match_pair_ref_test(cur,1) %�ش� ������ skip ���� ���� ���.
            idx_matchPair = cur;
            idx_start2search = i +1;
            break;
        elseif pos_ref_exact< match_pair_ref_test(cur,1)
            d_ref_before = data_resampled_ref(match_pair_ref_test(cur+1,1));
            d_ref_after = data_resampled_ref(match_pair_ref_test(cur,1));
            d_center= data_resampled_ref(pos_ref_exact);
            
            if abs(d_ref_before - d_center) < abs(d_ref_after - d_center) % ���� �����Ͱ� �� ������,
                idx_matchPair = cur +1;
                idx_start2search = i;
                break;
            else                                                          % �׷��� �ʴٸ�, ���� �����͸� ���
                idx_matchPair = cur;
                idx_start2search = i+1;
                break;
            end
        end
    end
    
    if idx_matchPair<0
        fprintf('findNearestPoint_InMatchPairRef: ����ġ ���� ���� �߻�\n');
    end
    
    pos_test_estimated = match_pair_ref_test(idx_matchPair,2);
end