clear;
addpath('..');
%%
if isempty(which('findjobj.m'))
    error('You need to add findobj.m to path - see readme.');
end
if isempty(which('ssh2.m'))
    error('You need to add ssh2 library to path - see readme.');
end
%%
username = input('Please enter username usually something like (abc1234):','s');
account = input('Please enter account (e.g. free):','s');
submit = true;
recover = not(submit);
% username = 'abc1234';
% account = 'free';
%%
matdir = pwd;%upload this directory
matname = 'project1';%project name
%%
d.n_par = 2;%number of cores (24 == 1 node on Habanero)
d.walltime = '00:03:00';
d.email_condition = 'NONE';%'END';
d.email = 'email@gmail.com';
%% the function that should run
% this line can be made more complex with sprintf()
% e.g. matfunc1 = sprintf("hab_testing(%s);",subject);

matfunc = "hab_testing;";
%% submit:
if submit
    hab_submit(username,account, matfunc, matdir, matname,...
        'n_par', d.n_par,'walltime', d.walltime,...
        'email_condition', d.email_condition,'email', d.email);
end
%%
if recover
    %has to be consistent with hab_testing.m actually does
    matresult = 'result_directory';
    hab_recover(username,account,matresult,matname);
end