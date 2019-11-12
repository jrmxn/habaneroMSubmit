function hab_submit(user,account,matfunc,matdir,matname,varargin)
d.n_par = 24;
d.walltime = '12:00:00';
d.mem = 4;%gb
d.pw_ssh = [];
d.dosub = true;
d.scratch_dir = '/rigel';%on remote host
d.remotehost = 'habanero.rcs.columbia.edu';
d.force_overwrite = false;
d.email = '';
d.email_condition = 'NONE';%END
d.jobname = '';
d.remote_subdir = 'Local';%
d.excludeCell = {};
%%
v = inputParser;
addParameter(v,'n_par',d.n_par);
addParameter(v,'walltime',d.walltime);
addParameter(v,'mem',d.mem);
addParameter(v,'pw_ssh',d.pw_ssh);
addParameter(v,'dosub',d.dosub);
addParameter(v,'scratch_dir',d.scratch_dir);
addParameter(v,'remotehost',d.remotehost);
addParameter(v,'remote_subdir',d.remote_subdir);
addParameter(v,'force_overwrite',d.force_overwrite);
addParameter(v,'email',d.email);
addParameter(v,'email_condition',d.email_condition);
addParameter(v,'jobname',d.jobname);
addParameter(v,'excludeCell',d.excludeCell);

parse(v,varargin{:});
v = v.Results;clear d;
%%
auxf_dir = mfilename('fullpath');
auxf_dir = fullfile(fileparts(auxf_dir),'auxf');
addpath(genpath(auxf_dir));
%%
filesep_unix = '/';
remotePath = [v.scratch_dir, filesep_unix, account, filesep_unix, 'users'];
remotePath_user = [remotePath, filesep_unix, user];
remotePath_user_workdir = [remotePath_user, filesep_unix, v.remote_subdir];
%%
fprintf('Will try to send %s\nto HPC\n',matdir);
fprintf('and run \n %s\n',matfunc);
%%
if isempty(v.jobname)
    job_id = sprintf('Job%d',randi(100000));
else
    job_id = v.jobname;
end
%% Get password if not provided and setup SSH connection
if isempty(v.pw_ssh)
    %Function that asks user to type password
    %tries to clear it from Matlab command window and command history
    %but not guaranteed to work.
    v.pw = get_password;
else
    v.pw = v.pw_ssh;
end
if not(exist('ssh2_struct','var')==1)
    pw_clear = v.pw.ssh;
    if not(ischar(pw_clear)),error('Password should be a string here - maybe it is nested in a struc?');end
    fprintf('Setting up SSH connection...\n');
    ssh2_struct = ssh2_config(v.remotehost, user, pw_clear, 22);
    ssh2_struct = ssh2(ssh2_struct);
    clear pw;
end
try
    %% Setup where we will locally deal with all the file processing etc.
    tar_file = [matname '.tar'];
    localPath = tempname;mkdir(localPath);
    locaPath_subdir = fullfile(localPath,matname);mkdir(locaPath_subdir);
    %% Look on the HPC to see if the target folder exists
    fprintf('Checking if target folder already exists...')
    positive_exist_string = 'yes';
    command = sprintf('[ -d "%s" ] && echo "%s"',...
        [remotePath_user_workdir, filesep_unix, matname], positive_exist_string);
    [ssh2_struct, command_result] = ssh2_command(ssh2_struct, command, false);
    target_exists = strcmpi(command_result{1},positive_exist_string);
    %% If it doesn't exist tar matdir and upload it
    if not(target_exists)||v.force_overwrite
        fprintf('Copying directory to temp directory...\n');
        copyfile(matdir,locaPath_subdir);
        %%
        fprintf('Excluding folders from excludeCell...\n');
        d_list = dir(locaPath_subdir);d_list = {d_list.name};
        rm_list = find(contains(d_list,v.excludeCell));
        for ix_rm_list = 1:length(rm_list)
            rm_name = d_list{rm_list(ix_rm_list)};
            rm_path = fullfile(locaPath_subdir, rm_name);
            if exist(rm_path,'file')==2
                delete(rm_path);
            elseif exist(rm_path,'dir') == 7
                rmdir(rm_path,'s');
            else
                fprintf('Failed to exclude %s.\n', rm_name)
            end
        end
        %%
        fprintf('Archiving it...\n');
        tar(fullfile(localPath,tar_file),locaPath_subdir);
        %% check that the parent directory exists
        % that is remote_subdir, which is called 'Local' by default and should
        % be in user dir, e.g. /rigel/users/abc1234/Local
        command = sprintf('[ -d "%s" ] && echo "%s"',...
            remotePath_user_workdir,positive_exist_string);
        [ssh2_struct, command_result] = ssh2_command(ssh2_struct, command, false);
        target_exists = strcmpi(command_result{1},positive_exist_string);
        if not(target_exists)
            fprintf('This directory did not exist, so making it:\n%s\n',remotePath_user_workdir);
            command = sprintf('mkdir %s',remotePath_user_workdir);
            [ssh2_struct, command_result] = ssh2_command(ssh2_struct, command, false);
        end
        %%
        fprintf('Transferring archive.\n');
        ssh2_struct = scp_put(ssh2_struct, tar_file, remotePath_user_workdir, localPath, tar_file);
        %%
        fprintf('Extracting archive remotely...\n');
        command = sprintf('tar -xvf %s -C %s',[remotePath_user_workdir, filesep_unix, tar_file], remotePath_user_workdir);
        [ssh2_struct, command_result] = ssh2_command(ssh2_struct, command, false);
        %%
        fprintf('Deleting tar file remotely...\n');
        command = sprintf('rm %s',[remotePath_user_workdir, filesep_unix, tar_file]);
        [ssh2_struct, command_result] = ssh2_command(ssh2_struct, command, false);
    else
        fprintf('Folder already present. Not overwriting.\n');
    end
    %% Now write the bash script by replacing strings in hab_basic_submit.shx
    fprintf('Writing bash script...\n');
    Y = fileread(fullfile(fileparts(mfilename('fullpath')),'hab_basic_submit.shx'));
    X = Y;
    hab.g_n_par_g = num2str(v.n_par);
    hab.g_walltime_g = v.walltime;
    hab.g_jobname_g = sprintf('%s_%s',matname,job_id);
    hab.g_account_g = account;
    hab.g_mem_g = sprintf('%dgb',v.mem);
    hab.g_MATLAB_PREFDIR_g = [remotePath_user, filesep_unix, 'matlab_prefs',...
        filesep_unix, job_id, filesep_unix, 'prefs'];
    hab.g_mail_user_g = v.email;
    hab.g_mail_type_g = v.email_condition;
    
    c.m_command1 = sprintf('parpool(%s)',hab.g_n_par_g);
    c.m_command2 = sprintf('cd %s',[remotePath_user_workdir, filesep_unix, matname]);
    c.m_command3 = sprintf('display(pwd)');
    c.m_command4 = matfunc;
    
    fn_c = fieldnames(c);
    command = '';
    for ix_fn_c = 1:length(fn_c)
        command = sprintf('%s%s;',command,c.(fn_c{ix_fn_c}));
    end
    hab.g_matlabFunc_g = command;
    
    fn_hab = fieldnames(hab);
    for ix_fn_hab = 1:length(fn_hab)
        X = strrep(X,fn_hab{ix_fn_hab},hab.(fn_hab{ix_fn_hab}));
    end
    sh_file = sprintf('%s.sh',job_id);
    fid = fopen(fullfile(localPath,sh_file),'wt');
    fprintf(fid, '%s',X);
    fclose(fid);
    %%
    submit_command = sprintf('sbatch %s', [remotePath_user_workdir, filesep_unix, sh_file]);
    %% replace line breaks if making this in windows...
    if ispc
        %         command = sprintf('sed -i.bak ''s/\\r$//'' %s', [remotePath_user_workdir, filesep_unix, sh_file]);
        %         error(['Not fully implemented for windows machine.\n',...
        %             'Run this manually on HPC:\n%s\n',...
        %             'Followed by:\n%s\n',...
        %             'This is because of DOS/UNIX line breaks - and sed command is',...
        %             ' escaping incorrectly when submitted over ssh2',...
        %             '(is not too hard to fix I guess).\n An alternative would be to',...
        %             'do remove the carriage return in the file before sending.',...
        %             ],command,submit_command)
        
        % Try to strip out the carriage returns by working with the binary file:
        fid = fopen(fullfile(localPath,sh_file),'rb');
        binarytext = fread(fid);
        fclose(fid);
        pause(1e-3);
        ascii_cr = 13;% 13 is carriage return
        binarytext(binarytext==ascii_cr) = [];
        fid = fopen(fullfile(localPath,sh_file),'wb');
        fwrite(fid,binarytext);
        fclose(fid);
    end
    %% upload script and submit it (sbatch command)
    fprintf('Transmitting and submitting bash script...\n');
    ssh2_struct = scp_put(ssh2_struct, sh_file, remotePath_user_workdir, localPath, sh_file);
    if v.dosub
        fprintf('%s\n',submit_command);
        [ssh2_struct, command_result] = ssh2_command(ssh2_struct, submit_command, true);
    else
        %for testing
        fprintf('Skipping actual sbatch command.\n');
    end
    %%
    ssh2_struct = hab_cleanup(ssh2_struct,localPath,auxf_dir);
    %%
catch rerr
    ssh2_struct = hab_cleanup(ssh2_struct,localPath,auxf_dir);
    rethrow(rerr);
end
end