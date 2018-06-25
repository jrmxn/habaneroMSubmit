clear;
result_directory = 'result_directory';
mkdir(result_directory);
A = randn(100);
v = randn(100,1);
for ix_A = 1:300
    v = A*v;
end
save(fullfile(result_directory,'v.mat'),'v');