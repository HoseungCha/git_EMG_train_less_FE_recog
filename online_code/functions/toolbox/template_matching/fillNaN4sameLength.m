%----------------------------------------------------------------------
% [ a, b, oria_size, orib_size] = fillNaN4sameLength( a, b )
%
% ���� �ٸ� ���̸� ���� �� ���� vector�� �޾Ƽ� ���� ���̷� �����. 
% ���ڶ�� �κ��� NaN���� ä���.
% Make two different-length array into the same length
% by adding NaN values
%----------------------------------------------------------------------
% by Won-Du Chang, ph.D, 
% Post-Doc @  Department of Biomedical Engineering, Hanyang University
% 12cross@gmail.com
%---------------------------------------------------------------------
function [ a, b, oria_size, orib_size] = fillNaN4sameLength( a, b )
    size_a = size(a,1);
    size_b = size(b,1);
    if size_a>size_b
        size_big = size_a;
    else
        size_big = size_b;
    end
    

    %Fill NaN when sizes are different
    if size_a>size_b
        tmp = zeros(size_big - size_b,1)+ NaN;
        b = [b; tmp];
    else
        tmp = zeros(size_big - size_a,1)+ NaN;
        a = [a; tmp];
    end
    
    oria_size = size_a;
    orib_size = size_b;
end

