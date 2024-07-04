# syntax=docker/dockerfile:1.7-labs
# This layer represents the bare minimum dependencies needed to run trick sims after they are compiled
FROM rockylinux:8 as minimal-base
RUN echo "max_parallel_downloads=20" >> /etc/dnf/dnf.conf

RUN dnf -y  install epel-release && \
  dnf -y update && \
  dnf install -y 'dnf-command(config-manager)' && \
  dnf config-manager --enable powertools && \
  dnf clean all

RUN dnf install -y \
python3-devel \
udunits2-devel \
zlib-devel \
libxml2-devel

FROM minimal-base as minimal-sim-compile-base

RUN dnf install -y \
clang \
llvm \
make \
cmake \
zip \
\
swig \
gcc-c++ \
libxml2-devel \
zlib-devel \
llvm-devel \
clang-devel \
udunits2-devel

FROM minimal-sim-compile-base as base

# trick minimum compile dependencies
RUN dnf install -y \
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
gcc \
gcc-c++ \
libxml2-devel \
openmotif \
openmotif-devel \
zlib-devel \
llvm-devel \
llvm-static \
clang-devel \
udunits2 \
udunits2-devel \
perl \
perl-Digest-MD5 \
which \
java-11-openjdk \
python3-devel && \
  dnf clean all

FROM base as trick-test

# add compile/unit tests only dependencies
RUN dnf install -y \
gtest-devel gmock-devel swig diffutils  bison  java-11-openjdk-devel ncurses-devel && \
  dnf clean all

ENV PYTHON_VERSION=3

COPY --link --exclude=infra --exclude=docs --exclude=*.Dockerfile . /opt/trick
RUN cd /opt/trick && ls -alh && ./configure && make -j $(nproc) && make install &&\
     trick-version --help &&\
     rm -rf /root/.m2 && \
     rm -rf /user/localshare/doc
#    && make clean

# todo  everything below could probably be done as user 1000
# setup test dependencies
RUN cd /opt/trick/share/trick/trickops/ && \
     python3 -m venv .venv && . .venv/bin/activate && pip3 install -r requirements.txt

COPY --link ./trick_sims /opt/trick/trick_sims

WORKDIR /opt/trick
CMD cd /opt/trick/share/trick/trickops && \
. .venv/bin/activate && \
cd /opt/trick && \
make test

FROM minimal-sim-compile-base as cli-runtime
COPY --link --from=trick-test /usr/local /usr/local

FROM minimal-base as gui-runtime

## Connection ports for controlling the UI:
# VNC port:5901
# noVNC webport, connect via http://IP:6901/?password=vncpassword
ENV DISPLAY=:1 \
    VGL_DISPLAY=:1 \
    VNC_PORT=5901 \
    NO_VNC_PORT=6901 \
    VNC_PW=vncpassword
EXPOSE $VNC_PORT $NO_VNC_PORT
### Envrionment config
ENV HOME=/home/trick \
    TERM=xterm \
    STARTUPDIR=/opt/dockerstartup \
    INST_SCRIPTS=/opt/install \
    NO_VNC_HOME=/opt/noVNC \
    VNC_COL_DEPTH=24 \
    VNC_RESOLUTION=1280x1024 \
    VNC_VIEW_ONLY=false \
    DEBUG=true
WORKDIR $HOME


RUN dnf -y install epel-release && \
  dnf -y update && \
  dnf -y install  \
       vim sudo wget which net-tools bzip2 findutils procps \
      python3-numpy \
      dbus-glib \
      psmisc \
      mailcap  \
    tigervnc-server  \
    dbus-tools  \
    nss_wrapper \
    gettext && \
  dnf clean all && \
  printf '\n# docker-headless-vnc-container:\nlocalhost=no\n' >>/etc/tigervnc/vncserver-config-defaults


RUN mkdir -p $NO_VNC_HOME/utils/websockify && \
  wget -qO- https://github.com/novnc/noVNC/archive/refs/tags/v1.3.0.tar.gz | tar xz --strip 1 -C $NO_VNC_HOME && \
  # use older version of websockify to prevent hanging connections on offline containers, see https://github.com/ConSol/docker-headless-vnc-container/issues/50
  wget -qO- https://github.com/novnc/websockify/archive/refs/tags/v0.10.0.tar.gz | tar xz --strip 1 -C $NO_VNC_HOME/utils/websockify  && \
  #chmod +x -v $NO_VNC_HOME/utils/*.sh
  ## for lighter interface try `vnc_lite.html` instead of `vnc.html`
  ln -s $NO_VNC_HOME/vnc.html $NO_VNC_HOME/index.html

# echo "Install Xfce4 UI components and disable xfce-polkit"
RUN dnf --enablerepo=epel -y -x gnome-keyring --skip-broken groups install "Xfce"  && \
  dnf -y groups install "Fonts"  && \
  dnf erase -y *power* *screensaver*  && \
  dnf -y install xfce4-whiskermenu-plugin && \
  dnf clean all  && \
  rm /etc/xdg/autostart/xfce-polkit*  && \
  /bin/dbus-uuidgen > /etc/machine-id

# Install trick GUI runtime dependencies
RUN dnf install -y \
    java-11-openjdk  \
    openmotif

ADD ./infra/xfce/ $HOME/

#echo "Install nss-wrapper to be able to execute image as non-root user"
RUN echo 'source $STARTUPDIR/generate_container_user' >> $HOME/.bashrc

ADD ./infra/scripts/ $STARTUPDIR/

# todo
RUN chmod +x $STARTUPDIR/*.sh
RUN chmod +x $HOME/*.sh
RUN chown 1000:1000 $HOME
RUN chown 1000:1000 $STARTUPDIR
#RUN $INST_SCRIPTS/set_user_permission.sh $STARTUPDIR $HOME
RUN adduser --home $HOME -u  1000 trick

USER 1000

COPY --link --from=trick-test /usr/local /usr/local
COPY --link --chown=1000:1000 ./trick_sims/  /home/trick/trick_sims

ENTRYPOINT ["/opt/dockerstartup/vnc_startup.sh"]

FROM gui-runtime as gl-runtime

USER 0

# TurboVNC + VirtualGL
RUN dnf install --enablerepo=epel -y  \
mesa-libGLU libXv mesa-libEGL libXtst xorg-x11-xauth glx-utils freeglut-devel
#libglu1-mesa libxv1 libegl1-mesa libxtst6 xauth mesa-utils

# should probably build from source in-line and/or pull from github artifacts for 3.1.1 tag
# note replace `x86_64` string below with `aarch64` for apple silicon or other arm runtimes
ADD https://github.com/VirtualGL/virtualgl/releases/download/3.1.1/VirtualGL-3.1.1.x86_64.rpm /tmp/virtualgl.rpm
RUN dnf install -y /tmp/virtualgl.rpm && \
    printf "1\nn\nn\nn\nx\n" | /opt/VirtualGL/bin/vglserver_config

COPY ./infra/gpu/xorg/99-virtualgl-dri.conf /etc/X11/xorg.conf.d/99-virtualgl-dri.conf
COPY ./infra/gpu/99-virtualgl-dri.rules /etc/udev/rules.d/99-virtualgl-dri.rules

RUN sed -i "s|Exec=startxfce4|Exec=vglrun -wm /usr/bin/startxfce4 --replace|" /usr/share/xsessions/xfce.desktop

USER 1000

####### Billiards sim example with only Virtual Desktop Image setup due to tight coupling with this sim and display
FROM trick-test as billiards-build

USER 0
# billiards deps
RUN dnf install -y \
eigen3-devel libXrandr-devel libXinerama-devel libXcursor-devel libXi-devel mesa-libGL-devel mesa-libEGL-devel
#    libeigen3-dev libxrandr-dev libxinerama-dev libxcursor-dev libxi-dev libglx-dev libegl-dev

USER 1000

RUN cd /opt/trick/trick_sims/SIM_billiards/models/graphics/cpp && \
  mkdir build && cd build && cmake .. && make -j $(nproc)

RUN cd /opt/trick/trick_sims/SIM_billiards && \
  trick-CP

FROM gl-runtime as billiards-gl-runtime
COPY --chown=1000:1000 --from=billiards-build /opt/trick/trick_sims/SIM_billiards/ /home/trick/trick_sims/SIM_billiards/
WORKDIR /home/trick/trick_sims/SIM_billiards

####### Sun sim example with both Minimal Headless Runtime image and Virtual Desktop Images both delivered
FROM trick-test as sun-build
COPY "./trick_sims/SIM_sun" /opt/sim
RUN cd /opt/sim/ && trick-CP

FROM trick-test as sun-gui-build
COPY "./trick_sims/SIM_sun/models/graphics" /opt/sim/models/graphics
RUN cd /opt/sim/models/graphics && make

FROM minimal-base as sun-sim-cli-runtime
COPY --chown=1000:1000 --from=sun-build /opt/sim /home/trick/sim
RUN adduser --home $HOME -u  1000 trick
USER 1000
WORKDIR /home/trick/sim
CMD ./S_main*.exe RUN_Summer/input.py

FROM gui-runtime as sun-sim-gui-runtime
COPY --chown=1000:1000 --from=sun-build /opt/sim /home/trick/sim
COPY --chown=1000:1000 --from=sun-gui-build /opt/sim/models/graphics /home/trick/sim/models/graphics
WORKDIR /home/trick/sim