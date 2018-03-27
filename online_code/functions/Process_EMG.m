% process EMG �Լ�

function Process_EMG()   
%     tic

    global pd;
    global info;
%     timeStart = toc(info.timer.process_emg.UserData)
%     if( pd.EMG.datasize<204) % 0.1�� ��ٸ�(������ size)
%         return;
%     end
        
    % feat extracion
%     myStop;
%     disp(pd.EMG.datasize);
%     disp(info.raw_pos-1);
%     myStop;
    curr_win =pd.EMG.getLastN(204);
    temp_rms = sqrt(mean(curr_win.^2));
%     pd.f.RMS.addArray(temp_rms);
    temp_CC = featCC(curr_win,4);
%     pd.f.CC.addArray(temp_CC);
    temp_WL = sum(abs(diff(curr_win,2)));
%     pd.f.WL.addArray(temp_WL);
    temp_SampEN = SamplEN(curr_win,2);
%     pd.f.SampEN.addArray(temp_SampEN);
%     disp(1);
    if info.handles.radiobutton_train.Value % train code
%         if(pd.featset.datasize<pd.featset.length && pd.featset.datasize>1) % ���������� �� ��ä���� ��� 
%             info.FE_start_sign=1;
%         end
        if(info.FE_start_sign==1)
%            myStop;
           pd.featset.addArray([temp_CC,temp_rms,temp_SampEN,temp_WL]);
           disp(pd.featset.datasize);
           
           if pd.featset.length == pd.featset.datasize
%                myStop;
               temp_FE_order = circshift(info.FE_order4GUI,1,2);
               i_trl = find(info.FE_order==temp_FE_order(1));
               info.FeatSet{i_trl} = pd.featset.data;
               
               pd.featset = circlequeue(info.num_windows,info.ch*3+info.ch*4);%�ʱ�ȭ
%                info.FE_end_sign = 0;
               info.FE_start_sign = 0;
           end
        end
    end
    
    if info.handles.radiobutton_test.Value % test code
        % feat construction
%         test = [pd.f.CC.getLast,pd.f.RMS.getLast,pd.f.SampEN.getLast];
        test = [temp_CC,temp_rms,temp_SampEN,temp_WL];
        % classify
%         myStop;
        pred_lda = predict(info.model.lda,test);
        pd.Predted.addArray(pred_lda);
        % majority voting
        if pd.Predted.datasize == pd.Predted.length
            temp_pd = pd.Predted.getLastN(pd.Predted.length);
            % ǥ���� ���� �������� ��� ����
            if(info.FE_start_sign)
               pd.test_result.addArray(pred_lda);
               pd.featset.addArray([temp_CC,temp_rms,temp_SampEN,temp_WL]);
               if pd.test_result.length == pd.test_result.datasize
                   % trl �����ľ�
                   temp_FE_order = circshift(info.FE_order4GUI,1);
                   i_trl = find(info.FE_order==temp_FE_order(1));
                   % ��� ����
                   info.test_result{i_trl} = pd.test_result.data;
                   pd.test_result = circlequeue(60,1);%�ʱ�ȭ
                   % Feat ����
                   info.FeatSet{i_trl} = pd.featset.data;
                   pd.featset = circlequeue(60,info.ch*3+info.ch*4);%�ʱ�ȭ
                   if isempty(info.test_result{i_trl})
                       myStop;
                       a=1;
                   end
               end
               
            end
            % majority voting
            [~,fp] = max(countmember(1:info.N_FE,temp_pd));
            % presentation of classfied facial expression
            info.handles.edit_classification.String = ...
                sprintf('Classfied: %s',info.FE_name{fp});
%             for i_FE=1:info.N_FE
%                 info.imt_h(i_FE).Visible='off';
%             end
%             info.imt_h(fp).Visible = 'on';
        end
    end
% toc;
end

function f = featCC(curwin,order)
   cur_xlpc = real(lpc(curwin,order)');
   cur_xlpc = cur_xlpc(2:(order+1),:);
   Nsignals = size(curwin,2);
   cur_CC = zeros(order,Nsignals);
   for i_sig = 1 : Nsignals
      cur_CC(:,i_sig)=a2c(cur_xlpc(:,i_sig),order,order)';
   end
   f = reshape(cur_CC,[1,order*Nsignals]);
end

function c=a2c(a,p,cp)
%Function A2C: Computation of cepstral coeficients from AR coeficients.
%
%Usage: c=a2c(a,p,cp);
%   a   - vector of AR coefficients ( without a[0] = 1 )
%   p   - order of AR  model ( number of coefficients without a[0] )
%   c   - vector of cepstral coefficients (without c[0] )
%   cp  - order of cepstral model ( number of coefficients without c[0] )

%                              Made by PP
%                             CVUT FEL K331
%                           Last change 11-02-99

for n=1:cp
  sum=0;
  if n<p+1
    for k=1:n-1
      sum=sum+(n-k)*c(n-k)*a(k);
    end
    c(n)=-a(n)-sum/n;
  else
    for k=1:p
      sum=sum+(n-k)*c(n-k)*a(k);
    end
    c(n)=-sum/n;
  end
end
end

function f = SamplEN(curwin,dim)
    N_sig = size(curwin,2);
    f = zeros(1,N_sig);
    R = 0.2*std(curwin);
    for i_sig = 1 : N_sig
       f(i_sig) = sampleEntropy(curwin(:,i_sig), dim, R(i_sig),1); %%   SampEn = sampleEntropy(INPUT, M, R, TAU)
    end
end

function yp = majority_vote(xp)
% final decision using majoriy voting
% yp has final prediction X segments(times)
[N_Seg,N_trl,N_label] = size(xp);
yp = zeros(N_label*N_trl,1);
for n_seg = 1 : N_Seg
    maxv = zeros(N_label,N_trl); final_predict = zeros(N_label,N_trl);
    for i = 1 : N_label
        for j = 1 : N_trl
            [maxv(i,j),final_predict(i,j)] = max(countmember(1:8,...
                xp(1:n_seg,j,i)));
        end
    end
    yp(:,n_seg) = final_predict(:);
%     acc(n_seg,N_comp+1) = sum(repmat((1:label)',[N_trl,1])==final_predict)/(label*N_trial-label*n_pair)*100;
end
end