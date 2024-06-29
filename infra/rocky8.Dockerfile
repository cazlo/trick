FROM rockylinux:8

RUN echo "max_parallel_downloads=20" >> /etc/dnf/dnf.conf

RUN dnf -y install epel-release && \
  dnf -y update && \
  dnf install -y 'dnf-command(config-manager)' && \
  dnf config-manager --enable powertools && \
  dnf install -y gtest-devel gmock-devel && \
    dnf install -y swig diffutils

RUN dnf install -y \
bison \
clang \
flex \
git \
llvm \
make \
maven \
cmake \
zip \
gdb \
\
clang-devel \
gcc \
gcc-c++ \
java-11-openjdk-devel \
libxml2-devel \
llvm-devel \
llvm-static \
ncurses-devel \
openmotif \
openmotif-devel \
perl \
perl-Digest-MD5 \
udunits2 \
udunits2-devel \
which \
zlib-devel \
python2-devel \
python3-devel


ENV PYTHON_VERSION=3

WORKDIR /apps
COPY . trick
WORKDIR /apps/trick
RUN ./configure && make -j $(nproc)

# Add ${TRICK_HOME}/bin to the PATH variable.
ENV TRICK_HOME="/apps/trick"
RUN echo "export PATH=${PATH}:${TRICK_HOME}/bin" >> ~/.bashrc

CMD ["/bin/bash"]