FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
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
swig \
curl \
g++ \
libx11-dev \
libxml2-dev \
libxt-dev \
libmotif-common \
libmotif-dev \
zlib1g-dev \
llvm-dev \
libclang-dev \
libudunits2-dev \
libgtest-dev \
default-jdk \
python2.7-dev \
python3-dev \
python3-pip \
python3-venv

# todo maybe only needed if we are in non-slim sim runtime
RUN apt-get install -y libgtest-dev libgmock-dev && \
              cd /usr/src/gtest && \
              cmake . && \
              make && \
              mv lib/libgtest* /usr/lib/ \
              && make clean

ENV PYTHON_VERSION=3

WORKDIR /apps
COPY . trick
WORKDIR /apps/trick
RUN ./configure && make -j $(nproc)

# Add ${TRICK_HOME}/bin to the PATH variable.
ENV TRICK_HOME="/apps/trick"
RUN echo "export PATH=${PATH}:${TRICK_HOME}/bin" >> ~/.bashrc

CMD ["/bin/bash"]