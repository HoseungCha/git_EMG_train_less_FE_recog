% DPW 의 fast version.
% slope mode 등의 파라메터를 디폴트로 잡아 처리에 걸리는 시간을 최소화한다.
% division 추가
% channel 수가 2 이상일 때에 대해서는 아직 테스트해 보지 않았음. 2017.05.03
%
% dimension: 1
% slope mode: normal (square jump)
% 
% speedup_mode: 1-> diamond, 2-> window, 3-> both
function [ dist ,table, match_pair] = fastDPW_v2( data_ref, data_test, max_slope_length, speedup_mode, window_width, bAllowDivision)
    %array 길이 계산
    size_test = size(data_test,1);
    size_ref  = size(data_ref,1);
    nChannel = size(data_test,2); %두 데이터의 채널수는 같다고 가정한다.
    
    %division을 위한 코드. 나누어질 데이터를 미리 계산해 둔다.
    %DPW 의 경우 미리 계산해 두는 것이 매우 복잡함
    
    table = ones(size_ref, size_test);                          % DP Table 생성
    table = table.*Inf;                                         % 초기화
    
    %DPW 모드인 경우 vector값을 단계별로 계산해야 한다.
    v_ref = dpw_preprocessing( data_ref, max_slope_length );
    v_test = dpw_preprocessing( data_test, max_slope_length );
    

    %DP Table 계산
    %table(1,1) = abs(data_ref(1,:)-data_test(1,:));
    table(1,1) = sqrt(sum((data_ref(1,:)-data_test(1,:)).^2,2));
    %table(1,1) = 0;
    
    ratio = size_ref/size_test;
    for j=2:size_test
        %speed-up window
        
        if speedup_mode ==1
            tmp = j-size_test;   
            %r_start = max(ceil(0.5*j+0.5), size_ref + 2*tmp);  %다이아몬드 형태인 경우의 수식
            %r_end = min(2*j-1, 0.5*tmp+size_ref);
            r_start = max(floor((j-1)/max_slope_length), size_ref + max_slope_length*tmp)+1;  %다이아몬드 형태인 경우의 수식
            if r_start<=1
                r_start =2;
            elseif r_start>size_ref
                r_start=size_ref;
            end
            r_end = min(max_slope_length*(j-1), tmp/max_slope_length+size_ref)+1;
            if r_end<=1
                r_end =2;
            elseif r_end>size_ref
                r_end = size_ref;
            end
        elseif speedup_mode ==2
            r_start = max(round(ratio*j)-window_width,2);
            r_end = min(round(ratio*j)+window_width,size_ref);
        else       
            tmp = j-size_test;  
            r_start = max([round(ratio*j)-window_width,2,ceil(0.5*j+0.5), size_ref + 2*tmp]);
            r_end = min([round(ratio*j)+window_width,size_ref,2*j-1, 0.5*tmp+size_ref]);
        end

        for i=r_start:r_end
             %각각의 branch에 대해 거리값 계산하여 최소값 저장
            min_dist = table(i-1,j-1);
            min_id_ref = 1; %min_dist 값을 가지는 이전 point의 상대적 위치값을 저장한다.
            min_id_test = 1;

            for k = 2: max_slope_length
                if i-k>0 && j-1>0
                    dist1 = table(i-k,j-1);
                    if(dist1<min_dist)
                        min_dist =dist1;
                        min_id_ref = k;
                    end
                end
                if i-1>0 && j-k>0
                    dist2 = table(i-1,j-k);
                    if(dist2<min_dist)
                        min_dist =dist2;
                        min_id_test = k;
                    end
                end
            end
            table(i, j) = min_dist + sqrt(sum((v_ref(min_id_ref,i,:)-v_test(min_id_test,j,:)).^2,3)); %root;
        end
    end
    dist = table(size_ref, size_test);
    if dist~=Inf
        match_pair = dtwfast_backtracking(table,max_slope_length);
    else 
        match_pair = [];
    end
end


function [match_pair] = dtwfast_backtracking(table, max_slope_length)
    size_ref = size(table,1);
    size_test = size(table,2);

    i = size_ref;
    j = size_test;
    
    nMaxMatchPair = size_ref+size_test;
    
    match_pair = ones(nMaxMatchPair,2);
    match_pair = match_pair.*Inf;
    
    
    match_pair(1,:) =[i j]; % input starting position
    count = 2;
    while 1
        min_dist = table(i-1,j-1);
        min_r = i-1;
        min_t = j-1;
        %find matching point having minimum distance
        for k = 2:max_slope_length
           if i-k>0 && j-1>0 && table(i-k,j-1)< min_dist
                min_dist = table(i-k,j-1);
                min_r = i-k;
                min_t = j-1;
           end
           if i-1>0 && j-k>0 &&  table(i-1,j-k)< min_dist
                min_dist = table(i-1,j-k);
                min_r = i-1;
                min_t = j-k;
           end
        end
        
        %matching pair 저장
        match_pair(count,:) = [min_r min_t];
        count = count+1;
        
        %move to the next point
        i = min_r;
        j = min_t;
        
        %종료조건
        if(i==1 && j==1)
            break;
        end
    end
    
    match_pair(count:nMaxMatchPair,:) = [];
end