%----------------------------------------------------------------------
%
% Ư�� path�� �ִ� ���� �� ��� ������ ������, ������ ���ڸ�ŭ�� �պκп��� 
% ö�ڸ� ���� �̸��� �ϰ������� �ٲ��ش�. 
%----------------------------------------------------------------------
% by Ho-Seung Cha,
% Ph.D Student @  Department of Biomedical Engineering, Hanyang University
% hoseungcha@gmail.com
%---------------------------------------------------------------------


function [name,FilepathFolder] = read_names_of_file_in_folder(filepath,extension)
path=pwd;
cd(filepath)
if nargin>1
    list=dir(extension);
else
list = dir;
end
count=1;
for i=1:length(list)
    if ( strcmp(list(i).name,'.')==1 || strcmp(list(i).name,'..')==1)
        continue;
    end
    name{count,1} = list(i).name;
    FilepathFolder{count,1} = fullfile(filepath,list(i).name);
    count = count +1;
end
cd(path);
end