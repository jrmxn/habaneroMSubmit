************
Introduction
************

:Author:
:Contact: 
:Web site:
:Github:
:Mailing list:
:Copyright:
:License:
:Version: 0.0.1

Purpose
=======
Basic scripts to automatically submit multiple parallel jobs to Columbia's Habanero HPC.
Includes various temporary directory settings to try to make the parallelisation more stable.
(Each folder has submission scripts for a different project).

Quick Submit
=======
Archives the folder you specify, sends it to the cluster and runs the function you specify.

Makes use of `SSH/SFTP/SCP For Matlab (v2) <https://www.mathworks.com/matlabcentral/fileexchange/35409-ssh-sftp-scp-for-matlab--v2->`_ to connect to the cluster and `findobj <https://www.mathworks.com/matlabcentral/fileexchange/14317-findjobj-find-java-handles-of-matlab-graphic-objects>`_ so that the passwords that get used don't stay in Matlab history (definitely not guaranteed). These must be added to the Matlab path for anything to work.
It's also possible to load the password from a .mat file stored on disk (which would usually be stored encrypted).

Example use:

.. code-block:: matlab

   matdir = '/hdd/Cloud/project1';
   matname = 'project1';%project name
   d.n_par = 24;
   d.walltime = '03:00:00';
   matfunc = "function_name_to_run";%runs function_name_to_run.m
   hab_submit(columbia_id,account_type,matfunc,matdir,matname,'n_par',d.n_par,'walltime',d.walltime);
   
Will move matdir to the cluster after archiving into a folder on Habanero named project1. Will then run "function_name_to_run" from within project after starting the parallel pool.

If project1 results are being written (for example) to folder 'sim' in 'project1', then sim folder can be retrieved like so:

.. code-block:: matlab

   hab_recover(columbia_id,account_type,'sim','project1');
       
Full Submit
=======
This is much more involved, and requires the user to move files and folders manually (for running projects once fully tested).
Works something like this:
#. ) When the local python script is called it writes several bash scripts (by swapping out variables in the .shx template file) which are each submitted using slurm. Each bash script has settings for the HPC module environment, as well as to call a local matlab function (which sets up the matlab environment).
#. ) When the local matlab function is called, it adds other required directories to the path, points towards the project directory, starts the parallel pool and runs the required project specific matlab function with variables that were set by python in the bash script (e.g. subject name, number of runs etc.)

Currently paths everywehre are based on my setup, but should be easy to swap these out for env variables.
