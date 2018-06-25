function ssh2_struct = hab_cleanup(ssh2_struct,localPath,auxf_dir)
fprintf('Closing SSH session...\n');
ssh2_struct = ssh2_close(ssh2_struct);
if (exist(localPath,'dir')==7)
    fprintf('Cleaning up temporary directory locally...\n');
    rmdir(localPath,'s');
end
rmpath(genpath(auxf_dir));
end