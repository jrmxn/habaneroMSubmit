function hab_recover(user,account,matresult,matname,varargin)
% d.n_par = 24;
% d.walltime = '12:00:00';
% d.mem = 4;%gb
d.pw_ssh = [];
% d.dosub = true;
d.remotehost = 'habanero.rcs.columbia.edu';
%%
v = inputParser;
% addParameter(v,'n_par',d.n_par);
% addParameter(v,'walltime',d.walltime);
% addParameter(v,'mem',d.mem);
addParameter(v,'pw_ssh',d.pw_ssh);
% addParameter(v,'dosub',d.dosub);
addParameter(v,'remotehost',d.remotehost);
parse(v,varargin{:});
v = v.Results;clear d;
%%
remotePath = fullfile('/rigel',account,'users');
remotePath_user = fullfile(remotePath,user);
remotePath_user_workdir = fullfile(remotePath_user,'Local');
%%
% matfunc = 'run_ddm_run_sz_eeg';%function to run within matdir
% matdir = '/hdd/Cloud/Research/matlab/exp/dm-sz2/analysis/v19';
% matname = 'sz';%project name
%
if isempty(v.pw_ssh)
    v.pw = get_password;
else
    v.pw = v.pw_ssh;
end
%%
tar_file = [matname '_' matresult '.tar'];
localPath = tempname;mkdir(localPath);
locaPath_subdir = fullfile(localPath,[matname '_' matresult]);mkdir(locaPath_subdir);
% fprintf('Copying directory to temp directory...\n');
% copyfile(matdir,locaPath_subdir);
% fprintf('Archiving it...\n');
% g = tar(fullfile(localPath,tar_file),locaPath_subdir);
%%
if not(exist('ssh2_struct','var')==1)
    pw_clear = v.pw.ssh;
    if not(ischar(pw_clear)),error('Password should be a string here - maybe it is nested in a struc?');end
    fprintf('Setting up SSH connection...\n');
    ssh2_struct = ssh2_config(v.remotehost, user, pw_clear, 22);
    ssh2_struct = ssh2(ssh2_struct);
    clear pw;
end
try
    %%
    doesex = 'doesex';
    command = sprintf('[ -d "%s" ] && echo "%s"',fullfile(remotePath_user_workdir,[matname]),doesex);
    [ssh2_struct, command_result] = ssh2_command(ssh2_struct, command, false);
    target_exists = strcmpi(command_result{1},doesex);
    if not(target_exists),ssh2_struct = ssh2_close(ssh2_struct);error('Folder does not exist remotely.');end
    %%
    fprintf('Creating archive remotely...\n');
    command = sprintf('tar -C %s -cvf %s %s',fullfile(remotePath_user_workdir,matname),tar_file,matresult);
    [ssh2_struct, command_result] = ssh2_command(ssh2_struct, command, false);
    %%
    fprintf('Transferring archive.\n');
    ssh2_struct = scp_get(ssh2_struct, tar_file, localPath, '');
    %%
    f = untar(fullfile(localPath,tar_file),localPath);
    if not(exist(fullfile(pwd,[matresult '_x']),'dir')==7),mkdir(fullfile(pwd,[matresult '_x']));end
    copyfile(fullfile(localPath,matresult),fullfile(pwd,[matresult '_x']));
    %%
    fprintf('Deleting remote archive...\n');
    command = sprintf('rm %s',tar_file);
    [ssh2_struct, command_result] = ssh2_command(ssh2_struct, command, false);
    %%
    fprintf('Closing SSH session...\n');
    ssh2_struct = ssh2_close(ssh2_struct);
    
    fprintf('Cleaning up temporary directory locally...\n');
    % clear pw ssh2_struct;%clear password from memory
    rmdir(localPath,'s');
    fprintf('Done.\n');
catch er
    fprintf('Rethrowing error...\n');
    ssh2_struct = ssh2_close(ssh2_struct);
    rethrow(er);
end
end