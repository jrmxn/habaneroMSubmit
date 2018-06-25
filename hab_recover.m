function hab_recover(user,account,matresult,matname,varargin)
d.pw_ssh = [];
d.scratch_dir = '/rigel';%on remote host
d.remotehost = 'habanero.rcs.columbia.edu';
d.remote_subdir = 'Local';
%%
v = inputParser;
addParameter(v,'pw_ssh', d.pw_ssh);
addParameter(v,'scratch_dir', d.scratch_dir);
addParameter(v,'remotehost', d.remotehost);
addParameter(v,'remote_subdir', d.remote_subdir);
parse(v,varargin{:});
v = v.Results;clear d;
%%
filesep_unix = '/';
if ispc
    warning('Untested on Windows');
end
%%
remotePath = [v.scratch_dir, filesep_unix, account, filesep_unix, 'users'];
remotePath_user = [remotePath, filesep_unix, user];
remotePath_user_workdir = [remotePath_user, filesep_unix, v.remote_subdir];
%%
if isempty(v.pw_ssh)
    v.pw = get_password;
else
    v.pw = v.pw_ssh;
end
%%
tar_file = [matname '_' matresult '.tar'];
localPath = tempname;mkdir(localPath);
locaPath_subdir = fullfile(localPath,[matname '_' matresult]);mkdir(locaPath_subdir);
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
    positive_exist_string = 'yes';
    command = sprintf('[ -d "%s" ] && echo "%s"',...
        [remotePath_user_workdir, filesep_unix, matname], positive_exist_string);
    [ssh2_struct, command_result] = ssh2_command(ssh2_struct, command, false);
    target_exists = strcmpi(command_result{1}, positive_exist_string);
    if not(target_exists),ssh2_struct = ssh2_close(ssh2_struct);error('Folder does not exist remotely.');end
    %%
    fprintf('Creating archive remotely...\n');
    command = sprintf('tar -C %s -cvf %s %s',...
        [remotePath_user_workdir, filesep_unix, matname], tar_file, matresult);
    [ssh2_struct, command_result] = ssh2_command(ssh2_struct, command, false);
    %%
    fprintf('Transferring archive.\n');
    ssh2_struct = scp_get(ssh2_struct, tar_file, localPath, '');
    %% Get the matresult directory back and as [matresult '_x']
    f = untar(fullfile(localPath, tar_file), localPath);
    if not(exist(fullfile(pwd,[matresult '_x']),'dir')==7)
        mkdir(fullfile(pwd,[matresult '_x']));
    end
    copyfile(fullfile(localPath, matresult), fullfile(pwd, [matresult '_x']));
    %%
    fprintf('Deleting remote archive...\n');
    command = sprintf('rm %s', tar_file);
    [ssh2_struct, command_result] = ssh2_command(ssh2_struct, command, false);
    %%
    ssh2_struct = cleanup(ssh2_struct, localPath);
    %%
catch reerr
    ssh2_struct = cleanup(ssh2_struct, localPath);
    rethrow(reerr);
end
end

function ssh2_struct = cleanup(ssh2_struct,localPath)
fprintf('Closing SSH session...\n');
ssh2_struct = ssh2_close(ssh2_struct);

fprintf('Cleaning up temporary directory locally...\n');
rmdir(localPath,'s');
fprintf('Done.\n');
end