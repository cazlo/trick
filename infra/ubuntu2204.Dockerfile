# syntax=docker/dockerfile:1.7-labs
# This layer represents the bare minimum dependencies needed to run trick sims after they are compiled
FROM ubuntu:22.04 as minimal-base
ENV DEBIAN_FRONTEND=noninteractive
RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
apt update && apt upgrade -y &&  apt install -y \
    python3-dev \
    libudunits2-dev \
    zlib1g-dev \
    libxml2-dev

FROM minimal-base as minimal-sim-compile-base
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
apt update && apt upgrade -y &&  apt install -y \
clang \
llvm \
make \
cmake \
zip \
\
swig \
g++ \
libxml2-dev \
zlib1g-dev \
llvm-dev \
libclang-dev \
libudunits2-dev

FROM minimal-sim-compile-base as base

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
apt update && apt upgrade -y &&  apt install -y \
clang \
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
python3-dev \
python3-pip \
python3-venv
# python2.7-dev

FROM base as trick-test

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
apt update && apt install -y \
 bison flex libgtest-dev libgmock-dev && \
cd /usr/src/gtest && \
cmake . && \
make -j $(nproc) && \
mv lib/libgtest* /usr/lib/ \
&& make -j $(nproc) clean

ENV PYTHON_VERSION=3

COPY --link --exclude=infra --exclude=docs --exclude=trick_sims --exclude=*.Dockerfile . /opt/trick
RUN cd /opt/trick && ls -alh && ./configure && make -j $(nproc) && make install &&\
     trick-version --help &&\
     rm -rf /root/.m2 &&\
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


RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
apt update && apt install -y \
       vim sudo wget debianutils net-tools bzip2 findutils procps \
      python3-numpy \
      libdbus-glib-1-dev \
      psmisc \
      mailcap  \
    tigervnc-standalone-server  \
    dbus  \
    libnss-wrapper \
    gettext && \
  printf '\n# docker-headless-vnc-container:\n$localhost="no";\n' >>/etc/tigervnc/vncserver-config-defaults


RUN mkdir -p $NO_VNC_HOME/utils/websockify && \
  wget -qO- https://github.com/novnc/noVNC/archive/refs/tags/v1.3.0.tar.gz | tar xz --strip 1 -C $NO_VNC_HOME && \
  # use older version of websockify to prevent hanging connections on offline containers, see https://github.com/ConSol/docker-headless-vnc-container/issues/50
  wget -qO- https://github.com/novnc/websockify/archive/refs/tags/v0.10.0.tar.gz | tar xz --strip 1 -C $NO_VNC_HOME/utils/websockify  && \
  #chmod +x -v $NO_VNC_HOME/utils/*.sh
  ## for lighter interface try `vnc_lite.html` instead of `vnc.html`
  ln -s $NO_VNC_HOME/vnc.html $NO_VNC_HOME/index.html

# Install Xfce4 UI components and disable screensaver and conflicting terminal
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
apt update && apt install -y \
    xfce4 xfce4-goodies \
    fonts-dejavu-core fonts-freefont-ttf \
    xfce4-terminal xfce4-whiskermenu-plugin && \
apt remove -y \
    xfce4-screensaver \
    xfce4-power-manager xfce4-power-manager-plugins \
    gnome-terminal && \
#  rm /etc/xdg/autostart/xfce-polkit*  && \
  /bin/dbus-uuidgen > /etc/machine-id

# Install trick GUI runtime dependencies
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
apt update && apt install -y \
    default-jre \
    libmotif-common

ADD ./infra/xfce/ $HOME/

#echo "Install nss-wrapper to be able to execute image as non-root user"
RUN echo 'source $STARTUPDIR/generate_container_user' >> $HOME/.bashrc

ADD ./infra/scripts/ $STARTUPDIR/

RUN chmod +x $STARTUPDIR/*.sh
RUN chmod +x $HOME/*.sh
RUN chown -R 1000:1000 $HOME
RUN chown 1000:1000 $STARTUPDIR
#RUN $INST_SCRIPTS/set_user_permission.sh $STARTUPDIR $HOME
RUN adduser --home $HOME -u  1000 trick

USER 1000

COPY --link --from=trick-test /usr/local /usr/local
COPY --link --chown=1000:1000 ./trick_sims/  /home/trick/trick_sims

ENTRYPOINT ["/opt/dockerstartup/vnc_startup.sh"]

FROM gui-runtime as gl-runtime

USER 0

# VirtualGL dependencies
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
apt update && apt install -y \
libglu1-mesa libxv1 libegl1-mesa libxtst6 xauth mesa-utils

# For production, should probably build VirtualGL from source in-line and/or pull from github src zip for 3.1.1 tag
# note replace `amd64` string below with `arm64` for apple silicon or other arm runtimes
ADD https://github.com/VirtualGL/virtualgl/releases/download/3.1.1/virtualgl_3.1.1_amd64.deb /tmp/virtualgl.deb
RUN apt install -y /tmp/virtualgl.deb && \
    printf "1\nn\nn\nn\nx\n" | /opt/VirtualGL/bin/vglserver_config

COPY ./infra/gpu/xorg/99-virtualgl-dri.conf /etc/X11/xorg.conf.d/99-virtualgl-dri.conf
COPY ./infra/gpu/99-virtualgl-dri.rules /etc/udev/rules.d/99-virtualgl-dri.rules

RUN sed -i "s|Exec=startxfce4|Exec=vglrun -wm /usr/bin/startxfce4 --replace|" /usr/share/xsessions/xfce.desktop

USER 1000

####### Billiards sim example with only Virtual Desktop Image setup due to tight coupling with this sim and display
FROM trick-test as billiards-build

USER 0
# billiards deps
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
apt update && apt install -y \
    libeigen3-dev libxrandr-dev libxinerama-dev libxcursor-dev libxi-dev libglx-dev libegl-dev

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