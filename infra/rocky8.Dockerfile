# syntax=docker/dockerfile:1.7-labs
FROM rockylinux:8 as base

RUN echo "max_parallel_downloads=20" >> /etc/dnf/dnf.conf

RUN dnf -y  install epel-release && \
  dnf -y update && \
  dnf install -y 'dnf-command(config-manager)' && \
  dnf config-manager --enable powertools && \
  dnf clean all

# trick runtime dependencies
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
clang-devel \
gcc \
gcc-c++ \
java-11-openjdk \
libxml2-devel \
llvm-devel \
llvm-static \
openmotif \
openmotif-devel \
perl \
perl-Digest-MD5 \
udunits2 \
udunits2-devel \
which \
zlib-devel \
python3-devel \
swig && \
  dnf clean all

FROM base as trick-test

# add compile/unit tests only dependencies
RUN dnf install -y \
gtest-devel gmock-devel swig diffutils  bison  java-11-openjdk-devel ncurses-devel && \
  dnf clean all

ENV PYTHON_VERSION=3

COPY --link --exclude=infra --exclude=docs --exclude=*.Dockerfile . /opt/trick
RUN cd /opt/trick && ls -alh && ./configure && make -j $(nproc) && make install && rm -rf /root/.m2

RUN trick-version --help || true

WORKDIR /opt/trick
CMD cd share/trick/trickops/ && \
 python3 -m venv .venv && . .venv/bin/activate && pip3 install -r requirements.txt && \
 cd ../../../; make test

FROM base as trick
COPY --link --from=trick-test /usr/local /usr/local

FROM base as runtime

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

COPY --link --from=trick /usr/local /usr/local
COPY --link --chown=1000:1000 ./trick_sims/  /home/trick/trick_sims

ENTRYPOINT ["/opt/dockerstartup/vnc_startup.sh"]

FROM runtime as gl-runtime

USER 0

# TurboVNC + VirtualGL
RUN dnf install --enablerepo=epel -y \
mesa-libGLU libXv mesa-libEGL libXtst xorg-x11-xauth glx-utils
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

FROM runtime as billiards-build

USER 0
# billiards deps
RUN dnf install -y \
eigen3-devel libXrandr-devel libXinerama-devel libXcursor-devel libXi-devel mesa-libGL-devel mesa-libEGL-devel
#    libeigen3-dev libxrandr-dev libxinerama-dev libxcursor-dev libxi-dev libglx-dev libegl-dev

USER 1000

RUN cd /home/trick/trick_sims/SIM_billiards/models/graphics/cpp && \
  mkdir build && cd build && cmake .. && make -j $(nproc)

RUN cd /home/trick/trick_sims/SIM_billiards && \
  trick-CP

FROM gl-runtime as billiards-sim
COPY --from=billiards-build /home/trick/trick_sims/SIM_billiards/ /home/trick/trick_sims/SIM_billiards/
WORKDIR /home/trick/trick_sims/SIM_billiards