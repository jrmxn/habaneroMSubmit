clear;
addpath('..');
%% 
username = input('Please enter username usually something like (abc1234):','s');
account = input('Please enter account (e.g. free):','s');
% username = 'abc1234';
% account = 'free';
%%
matdir = pwd;%upload this directory
matname = 'project1';%project name
%%
d.n_par = 3;%number of cores
d.walltime = '00:15:00';
d.email_condition = 'END';
d.email = 'email@gmail.com';
%% the function that should run
% this line can be made more complex with sprintf()
% e.g. matfunc1 = sprintf("hab_testing(%s);",subject);

matfunc = "hab_testing;";
%% submit:
hab_submit(username,account, matfunc, matdir, matname,...
    'n_par', d.n_par,'walltime', d.walltime,...
    'email_condition', d.email_condition,'email', d.email);
%%
% matresult = 'result_directory';
% hab_recover(username,account,matresult,matname);
