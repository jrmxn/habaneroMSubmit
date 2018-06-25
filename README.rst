************
Introduction
************

:Author: James McIntosh
:Version: 0.0.1
.. :Contact: 
   :Copyright:
   :License:


Purpose
=======
I was getting tired of writing custom submission scripts for every project I was working on.
These are basic scripts to automatically submit multiple parallel jobs to Columbia's Habanero HPC.
Includes various temporary directory settings to try to make the parallelisation more stable.
(Each folder has submission scripts for a different project).
Should work with other SLURM systems but paths may require tweaking.
Only tested on Ubuntu 18.04.

Other info
=======
https://wikis.cuit.columbia.edu/confluence/display/rcs/Habanero+-+Job+Examples
https://github.com/gaoyuanjun/hpc_tutorial

Quick Submit
=======
Archives the folder you specify, sends it to the cluster and runs the function you specify within that folder.

Makes use of `SSH/SFTP/SCP For Matlab (v2) <https://www.mathworks.com/matlabcentral/fileexchange/35409-ssh-sftp-scp-for-matlab--v2->`_ to connect to the cluster.
This should be downloaded and placed in the auxf directory.
Also uses (already in auxf) `findobj <https://www.mathworks.com/matlabcentral/fileexchange/14317-findjobj-find-java-handles-of-matlab-graphic-objects>`_ so that the passwords that get used don't stay in Matlab history (definitely not guaranteed).
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
