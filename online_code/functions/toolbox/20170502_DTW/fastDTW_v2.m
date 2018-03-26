% DTW �� fast version.
% division �߰�
% channel ���� 2 �̻��� ���� ���ؼ��� ���� �׽�Ʈ�� ���� �ʾ���. 2017.05.03
%
% slope mode ���� �Ķ���͸� ����Ʈ�� ��� ó���� �ɸ��� �ð��� �ּ�ȭ�Ѵ�.
% dimension: 1
% slope mode: normal (square jump)
% 
% speedup_mode: 1-> diamond, 2-> window, 3-> both
% designed & coded by Dr. Won-Du Chang
% last modified 2017.05.03
function [ dist ,table, match_pair] = fastDTW_v2( data_ref, data_test, max_slope_length, speedup_mode, window_width, bAllowDivision)
    
    %array ���� ���
    size_test = size(data_test,1);
    size_ref  = size(data_ref,1);
    nChannel = size(data_test,2); %�� �������� ä�μ��� ���ٰ� �����Ѵ�.
    
    %division�� ���� �ڵ�. �������� �����͸� �̸� ����� �д�.
    %���� ���, bDivData_ref{4,2} �� ref �������� 3��°�� 4��° ������ point ���̸� 3���������, ����
    %���� �� ���� ���� ������.
    if nargin<6
        bAllowDivision = 0;
    end
    if (bAllowDivision==1)
        dataDiv_ref    = cell(size_ref, max_slope_length-1);
        dataDiv_test   = cell(size_test, max_slope_length-1);
        for i=2:size_ref
            for j=1:max_slope_length-1
                dx = (data_ref(i,:) - data_ref(i-1,:))./(j+1);
                dataDiv_ref{i,j} = zeros(j,nChannel);
                for k=1:j
                    dataDiv_ref{i,j}(k,:) = data_ref(i-1,:) + dx * k;
                end
            end
            
            for j=1:max_slope_length-1
                dx = (data_test(i,:) - data_test(i-1,:))./(j+1);
                dataDiv_test{i,j} = zeros(j,nChannel);
                for k=1:j
                    dataDiv_test{i,j}(k,:) = data_test(i-1,:) + dx * k;
                end
            end
        end
    end
    %division�� ���� preCalculation�ڵ� ��.
    
    
    
    table = ones(size_ref, size_test);                          % DP Table ����
    table = table.*Inf;                                         % �ʱ�ȭ
    

    %DP Table ���
    %table(1,1) = abs(data_ref(1,1)-data_test(1,1));
    table(1,1) = sqrt(sum((data_ref(1,:)-data_test(1,:)).^2,2));
    ratio = size_ref/size_test;
    for j=2:size_test
        %speed-up window
        
        if speedup_mode ==1
            tmp = j-size_test;   
            r_start = max(ceil(0.5*j+0.5), size_ref + 2*tmp);  %���̾Ƹ�� ������ ����� ����
            r_end = min(2*j-1, 0.5*tmp+size_ref);
        elseif speedup_mode ==2
            r_start = max(round(ratio*j)-window_width,2);
            r_end = min(round(ratio*j)+window_width,size_ref);
        else       
            tmp = j-size_test;  
            r_start = max([round(ratio*j)-window_width,2,ceil(0.5*j+0.5), size_ref + 2*tmp]);
            r_end = min([round(ratio*j)+window_width,size_ref,2*j-1, 0.5*tmp+size_ref]);
        end

        for i=r_start:r_end
             %������ branch�� ���� �Ÿ��� ����Ͽ� �ּҰ� ����
            min_dist = table(i-1,j-1);

            for k = 2: max_slope_length
                if i-k>0 && j-1>0 %ref�� jump �ϴ� ���
                    dist1 = table(i-k,j-1);
                    
                    %division�� ���� �ڵ�
                    if (bAllowDivision==1)  %division�� �ϴ� ��� division �� �Ÿ����� ����� �־�� ��.
                        for m=1:k-1  %���⼭ k-1�� division�� ������ �� skip �ϰԵǴ� point�� ������. �� segement �� k ��еȴ�.
                            d_tmp_test = dataDiv_test{j,k-1}(m,:);
                            dist_tmp = sqrt(sum((d_tmp_test-data_ref(i-k+m,:)).^2,2));
                            dist1 = dist1 + dist_tmp;
                            
                        end
                    end
                    %division�� ���� �ڵ� ��
                    
                    if(dist1<min_dist)
                        min_dist =dist1;
                    end
                end
                if i-1>0 && j-k>0 %test �� jump�ϴ� ���
                    dist2 = table(i-1,j-k);
                    
                    %division�� ���� �ڵ�
                    if (bAllowDivision==1)  %division�� �ϴ� ��� division �� �Ÿ����� ����� �־�� ��.
                        for m=1:k-1  %���⼭ k-1�� division�� ������ �� skip �ϰԵǴ� point�� ������. �� segement �� k ��еȴ�.
                            d_tmp_ref = dataDiv_ref{j,k-1}(m,:);
                            dist_tmp = sqrt(sum((d_tmp_ref-data_test(j-k+m,:)).^2,2));
                            dist1 = dist1 + dist_tmp;
                            
                        end
                    end
                    %division�� ���� �ڵ� ��
                    if(dist2<min_dist)
                        min_dist =dist2;
                    end
                end
            end
            %table(i, j) = min_dist + abs(data_ref(i,1)-data_test(j,1)); %root;
            table(i, j) = min_dist + sqrt(sum((data_ref(i,:)-data_test(j,:)).^2,2));
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
        
        %matching pair ����
        match_pair(count,:) = [min_r min_t];
        count = count+1;
        
        %move to the next point
        i = min_r;
        j = min_t;
        
        %��������
        if(i==1 && j==1)
            break;
        end
    end
    
    match_pair(count:nMaxMatchPair,:) = [];
end