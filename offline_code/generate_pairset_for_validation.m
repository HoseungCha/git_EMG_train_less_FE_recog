clc; clear all; close all;
N_Trl = 10;
new_pairset = cell(N_Trl-1,1);
for i_pair = 1 : N_Trl-1
    temp_paiset = nchoosek(1:N_Trl,i_pair);
    temp = randperm(length(temp_paiset));
    pairset_new{i_pair} = temp_paiset(temp(1:N_Trl),:);    
end
save('pairset_new','pairset_new');
% 2017.08.25 ���� 2�� �ݿ� pairset_new.m ������ ����