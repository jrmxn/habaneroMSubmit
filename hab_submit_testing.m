cclearvars -except ssh2_struct pw
if exist('pw','var')==1
else
    pw.ssh = input('pw ssh:\n','s');
    % Remove password from matlab command history
    fprintf(repmat('\b',1,1+length(pw)));%from screen
    % Get instance to the Command History
    cmdhist = com.mathworks.mde.cmdhist.AltHistory.getInstance;
    % Retrieve the Command History Table
    chtable = findjobj(cmdhist,'property',{'name', 'CommandHistoryTable'});
    % Select last row row
    nrows = chtable.getRowCount;
    chtable.setRowSelectionInterval(nrows-1, nrows-1)
    % Delete selected rows
    chtable.deleteSelectedCommands;
    
    pw.git = input('pw git:\n','s');
    % Remove password from matlab command history
    fprintf(repmat('\b',1,1+length(pw)));%from screen
    % Get instance to the Command History
    cmdhist = com.mathworks.mde.cmdhist.AltHistory.getInstance;
    % Retrieve the Command History Table
    chtable = findjobj(cmdhist,'property',{'name', 'CommandHistoryTable'});
    % Select last row row
    nrows = chtable.getRowCount;
    chtable.setRowSelectionInterval(nrows-1, nrows-1)
    % Delete selected rows
    chtable.deleteSelectedCommands;
end
%%
dirname_root = 'sz';
tar_file = [dirname_root '.tar'];
originalDir = '/hdd/Cloud/Research/matlab/exp/dm-sz2/analysis/v19';
localPath = tempname;mkdir(localPath);
locaPath_subdir = fullfile(localPath,dirname_root);mkdir(locaPath_subdir);
copyfile(originalDir,locaPath_subdir);
g = tar(fullfile(localPath,tar_file),locaPath_subdir);
%%
remotePath = '/rigel/dsi/users/jrm2263/Local';
%%
if not(exist('ssh2_struct','var')==1)
    ssh2_struct = ssh2_config('habanero.rcs.columbia.edu', 'jrm2263', pw.val, 22);
    ssh2_struct = ssh2(ssh2_struct);
end
ssh2_struct = scp_put(ssh2_struct, tar_file, remotePath, localPath, tar_file);
%%
command = sprintf('tar -xvf %s -C %s',fullfile(remotePath,tar_file), fullfile(remotePath));
[ssh2_struct, command_result] = ssh2_command(ssh2_struct, command, false);
%%

job_id = sprintf('Job%d',randi(100000));
Y = fileread('hab_basic_submit.shx');
X = Y;
hab.g_n_par_g = '1';
hab.g_walltime_g = '00:10:00';
hab.g_jobname_g = 'test';
hab.g_account_g = 'dsi';
hab.g_mem_g = '4gb';
hab.g_MATLAB_PREFDIR_g = sprintf('/rigel/dsi/users/jrm2263/matlab_prefs/%s/prefs',job_id);


c.m_command1 = sprintf('parpool(%s)',hab.g_n_par_g);
c.m_command2 = sprintf('cd %s',fullfile(remotePath,dirname_root));
c.m_command3 = sprintf('display(pwd)');
c.m_command4 = 'run_ddm_run_sz_eeg';

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
ssh2_struct = scp_put(ssh2_struct, sh_file, remotePath, localPath, sh_file);
command = sprintf('sbatch %s',fullfile(remotePath,sh_file));
[ssh2_struct, command_result] = ssh2_command(ssh2_struct, command, false);

% [ssh2_struct, command_result] = ssh2_command(ssh2_struct, 'pwd', false);

% ssh2_struct = ssh2_close(ssh2_struct);


clear pw ssh2_struct;%clear password from memory
rmdir(localTemp);