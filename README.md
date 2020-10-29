# container_quantum_espresso_gpu_openmpi_centos7_x86_64
Container recipes of Quantum Espresso for gpu, architecture x86_64 based on CentOS 7.  
In the specific:  
- CentOS 7 with cuda library (10.0-devel-centos7)  
- GNU compiler 4.8.5 
- Python 2.7 
- Python 3.6 
- Intel mkl 2019.4-070 
- PGI 19.10 (2019), C and fortran compilers developed by Nvidia 
- Openmpi 4.0.1 (compiled with support for cuda, psm2, pmix, verbs)  
- Quantum Espresso 6.4.1a1_mod ( compiled with --with-cuda-runtime=10.0 --with-cuda-cc=70 --enable-openmp --enable-openmp=yes --enable-parallel=yes)  

This recipe works in the Cineca cluster (arch x86_64):  

- Galileo
