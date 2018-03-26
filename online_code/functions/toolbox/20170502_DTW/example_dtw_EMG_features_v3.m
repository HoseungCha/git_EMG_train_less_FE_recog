% DTW�� �̿��Ͽ�, �ڽ��� Feature�� ������ �ٸ� ������� ���� �����ͷ� ����
% Feature ã�� �ڵ� Example

load('FeatureSet.mat');

data = cell(3,1);
data_transformed = cell(3,1);
option.nDivision_4Resampling = 10;
% DTW�� ��� �� Feature ���� �Ÿ� (���絵) ���
option.max_slope_length = 3;
option.speedup_mode = 1;


% �ڽ��� Feature ('Angry')
data{1} = TrSet(1,:)';
data{2} = TrSet(2,:)';
data{3} = TrSet(30,:)';
ref = data{1};

d_trans{1} = ref;
d_trans{2} = transfromData_accRef_usingDTW(data{2}, ref, option);
d_trans{3} = transfromData_accRef_usingDTW(data{3}, ref, option);
  
% �׸� ���
figure;
subplot(2,1,1);
plot(data{1})
hold on
plot(data{2});
hold on;
plot(data{3})
legend('data 1', 'data 2', 'data 3');
subplot(2,1,2);
plot(d_trans{1})
hold on
plot(d_trans{2});
hold on;
plot(d_trans{3})
legend('data 1(ref)', 'data 2 (transformed)', 'data 3 (transformed)');