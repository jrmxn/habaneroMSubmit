clear;
%%
addpath(fullfile(libgit,'habanero-scripts','quick_submit'));
matdir = '/hdd/Cloud/projectX';
matname = 'project1';%project name
%%
d.n_par = 24;
d.walltime = '12:00:00';
%%
matfunc1 = "clear;p_ex = {'st'};ddm_run('nlrt',p_ex);";
d.email_condition = 'END';
d.email = 'email@gmail.com';

hab_submit('abc1111','free',matfunc,matdir,matname,'n_par',d.n_par,'walltime',d.walltime,...
    'email_condition',d.email_condition,'email',d.email);
%%
% matresult = 'sim';
% hab_recover('abc1111','free',matresult,matname);
