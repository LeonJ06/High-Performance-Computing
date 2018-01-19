CS243 Final Project
Yuan Hung Lin 28321104
Yucheng Tang 21842798

This folder contains 2 version of the 3D human face modeling. kernelDis.cu is for distributed GPU and kernelP2P.cu is for peer to peer. They are designed to run on the HPC server. To run that file, you need to: 
1. Copy those files to the HPC server. 
2. Module load cuda/5.0
    Module load gcc/4.4.3
3. nvcc XXXX.cu timer.c -o XXXX

or you can use the shell file to execute the program.
Use qsub to submit the cuda.sh. You can use qstat to check the station of the task. If you want to change other core, you can varify the cuda.sh.

