% NormalizeFeature_4DTW
%ref �� �������� d�� normalize �Ѵ�. ref, d�� ���� 1���� �迭�̴�.
% Designed & Coded by Dr. Won-Du Chang
% Last Modified at 2017.05.02
% 12cross@gmail.com
function [d_norm] = NormalizeFeature_4DTW(ref, d)
    factor = std(ref)/std(d);
    d_norm = d* factor;
%     d_norm = d_norm- mean(d_norm) + mean(ref);
    d_norm = d_norm- min(d_norm) + min(ref);
end
