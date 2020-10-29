# 
# HPC Base image
# 
# Contents:
#   CUDA version 10.0
#   OpenMPI version 4.0.1
#   PGI compilers version 19.10
# 

FROM nvidia/cuda:10.0-devel-centos7 AS devel

# Python
RUN yum install -y \
        python2 \
        python3 && \
    rm -rf /var/cache/yum/*

# PGI compiler version 19.10
COPY pgilinux-2019-1910-x86-64.tar.gz /var/tmp/pgilinux-2019-1910-x86-64.tar.gz
RUN yum install -y \
        gcc \
        gcc-c++ \
        numactl-libs \
        perl && \
    rm -rf /var/cache/yum/*
RUN mkdir -p /var/tmp/pgi && tar -x -f /var/tmp/pgilinux-2019-1910-x86-64.tar.gz -C /var/tmp/pgi -z && \
    cd /var/tmp/pgi && PGI_ACCEPT_EULA=accept PGI_INSTALL_DIR=/opt/pgi PGI_INSTALL_MPI=false PGI_INSTALL_NVIDIA=false PGI_MPI_GPU_SUPPORT=false PGI_SILENT=true ./install && \
    echo "set CUDAROOT=/usr/local/cuda;" >> /opt/pgi/linux86-64/19.10/bin/siterc && \
    echo "variable LIBRARY_PATH is environment(LIBRARY_PATH);" >> /opt/pgi/linux86-64/19.10/bin/siterc && \
    echo "variable library_path is default(\$if(\$LIBRARY_PATH,\$foreach(ll,\$replace(\$LIBRARY_PATH,":",), -L\$ll)));" >> /opt/pgi/linux86-64/19.10/bin/siterc && \
    echo "append LDLIBARGS=\$library_path;" >> /opt/pgi/linux86-64/19.10/bin/siterc && \
    ln -sf /usr/lib64/libnuma.so.1 /opt/pgi/linux86-64/19.10/lib/libnuma.so && \
    ln -sf /usr/lib64/libnuma.so.1 /opt/pgi/linux86-64/19.10/lib/libnuma.so.1 && \
    rm -rf /var/tmp/pgilinux-2019-1910-x86-64.tar.gz /var/tmp/pgi
ENV LD_LIBRARY_PATH=/opt/pgi/linux86-64/19.10/lib:$LD_LIBRARY_PATH \
    PATH=/opt/pgi/linux86-64/19.10/bin:$PATH

# OFED
RUN yum install -y \
        dapl \
        dapl-devel \
        ibutils \
        libibcm \
        libibmad \
        libibmad-devel \
        libibumad \
        libibverbs \
        libibverbs-utils \
        libmlx5 \
        librdmacm \
        rdma-core \
        rdma-core-devel && \
    rm -rf /var/cache/yum/*

# OpenMPI version 4.0.1
RUN yum install -y \
        bzip2 \
        file \
        hwloc \
        make \
        numactl-devel \
        openssh-clients \
        perl \
        tar \
	less \
	vim \
	curl \
        wget && \
    rm -rf /var/cache/yum/*

RUN mkdir -p /var/tmp
COPY openmpi-4.0.1.tar.bz2 /var/tmp/openmpi-4.0.1.tar.bz2
RUN tar -x -f /var/tmp/openmpi-4.0.1.tar.bz2 -C /var/tmp -j && \
    cd /var/tmp/openmpi-4.0.1 &&  CC=pgcc CXX=pgc++ F77=pgfortran F90=pgfortran FC=pgfortran ./configure --prefix=/usr/local/openmpi --disable-getpwuid --enable-orterun-prefix-by-default --with-cuda --with-verbs && \
    make -j$(nproc) && \
    make -j$(nproc) install && \
    rm -rf /var/tmp/openmpi-4.0.1.tar.bz2 /var/tmp/openmpi-4.0.1
ENV LD_LIBRARY_PATH=/usr/local/openmpi/lib:$LD_LIBRARY_PATH \
    PATH=/usr/local/openmpi/bin:$PATH

# MKL version 2019.4-070
RUN rpm --import https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB && \
    yum install -y yum-utils && \
    yum-config-manager --add-repo https://yum.repos.intel.com/mkl/setup/intel-mkl.repo && \
    yum install -y \
        intel-mkl-64bit-2019.4-070 && \
    rm -rf /var/cache/yum/*
ENV LD_LIBRARY_PATH=/opt/intel/mkl/lib/intel64:$LD_LIBRARY_PATH \
    PATH=/opt/intel/mkl/bin:$PATH \
    MKL_HOME=/opt/intel/mkl \
    MKLROOT=/opt/intel/mkl \
    MKL_LIB=/opt/intel/mkl/lib/intel64 \
    MKL_INC=/opt/intel/mkl/include \
    MKL_INCLUDE=/opt/intel/mkl/include \
    LIBPATH=/opt/intel/mkl/lib/intel64 

RUN echo "source /opt/intel/mkl/bin/mklvars.sh intel64" >> /etc/bashrc

# Quantum Espresso develop version prep make.inc
COPY q-e-gpu-gpu-develop.tar.gz  /opt/q-e-gpu-gpu-develop.tar.gz

RUN cp /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/libcuda.so && \
    cp /usr/local/cuda/lib64/libcuda.so /usr/local/cuda/lib64/libcuda.so.1 && \
    cd /opt && \
    tar -xvf q-e-gpu-gpu-develop.tar.gz && \
    cd q-e-gpu-gpu-develop && \
    ./configure FC=pgf90 F90=pgf90 --with-cuda=/usr/local/cuda --with-cuda-runtime=10.0 --with-cuda-cc=70 --enable-openmp --with-scalapack=no &> log_configure_devel.txt

# Quantum Espresso installation for Volta 100
COPY q-e-gpu-qe-gpu-6.4.1a1_MOD.tar.gz /opt/q-e-gpu-qe-gpu-6.4.1a1_MOD.tar.gz

RUN cd /opt && \
    tar -xvf q-e-gpu-qe-gpu-6.4.1a1_MOD.tar.gz && \
    cd q-e-gpu-qe-gpu-6.4.1a1 && \
    ./configure FC=pgf90 F90=pgf90 --with-cuda=/usr/local/cuda  --with-cuda-runtime=10.0 --with-cuda-cc=70 --enable-openmp --with-scalapack=no &> log_configure_ufficial.txt && \
    rm make.inc && \
    cp /opt/q-e-gpu-gpu-develop/make.inc make.inc && \
    sed -i "s/DFLAGS         =  -D__PGI -D__CUDA -D__DFTI -D__MPI/DFLAGS         =  -D__PGI -D__CUDA -D__DFTI -D__MPI -D__GPU_MPI/g" make.inc && \
    make -j pw

ENV PATH=/opt/q-e-gpu-qe-gpu-6.4.1a1/bin:$PATH

FROM nvidia/cuda:10.0-runtime-centos7

#### Python
RUN yum install -y \
        python2 \
        python3 && \
    rm -rf /var/cache/yum/*

# PGI compiler
RUN yum install -y \
        numactl-libs && \
    rm -rf /var/cache/yum/*
COPY --from=devel /opt/pgi/linux86-64-llvm/19.10/REDIST/*.so* /opt/pgi/linux86-64/19.10/lib/
RUN ln -sf /usr/lib64/libnuma.so.1 /opt/pgi/linux86-64/19.10/lib/libnuma.so && \
    ln -sf /usr/lib64/libnuma.so.1 /opt/pgi/linux86-64/19.10/lib/libnuma.so.1
ENV LD_LIBRARY_PATH=/opt/pgi/linux86-64/19.10/lib:$LD_LIBRARY_PATH

# OFED
RUN yum install -y \
        dapl \
        dapl-devel \
        ibutils \
        libibcm \
        libibmad \
        libibmad-devel \
        libibumad \
        libibverbs \
        libibverbs-utils \
        libmlx5 \
        librdmacm \
        rdma-core \
        rdma-core-devel && \
    rm -rf /var/cache/yum/*

# OpenMPI
RUN yum install -y \
        hwloc \
        openssh-clients && \
    rm -rf /var/cache/yum/*
COPY --from=devel /usr/local/openmpi /usr/local/openmpi
ENV LD_LIBRARY_PATH=/usr/local/openmpi/lib:$LD_LIBRARY_PATH \
    PATH=/usr/local/openmpi/bin:$PATH


# MKL version 2019.4-070
COPY --from=devel /opt/intel/mkl /opt/intel/mkl 

ENV LD_LIBRARY_PATH=/opt/intel/mkl/lib/intel64:$LD_LIBRARY_PATH \
    PATH=/opt/intel/mkl/bin:$PATH \
    MKL_HOME=/opt/intel/mkl \
    MKLROOT=/opt/intel/mkl \
    MKL_LIB=/opt/intel/mkl/lib/intel64 \
    MKL_INC=/opt/intel/mkl/include \
    MKL_INCLUDE=/opt/intel/mkl/include \
    LIBPATH=/opt/intel/mkl/lib/intel64 
RUN echo "source /opt/intel/mkl/bin/mklvars.sh intel64" >> /etc/bashrc

# Quantum Espresso
COPY --from=devel /opt/q-e-gpu-qe-gpu-6.4.1a1 /opt/q-e-gpu-qe-gpu-6.4.1a1

ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH \
    PATH=/opt/q-e-gpu-qe-gpu-6.4.1a1/bin:$PATH
