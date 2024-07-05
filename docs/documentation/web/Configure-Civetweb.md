| [Home](/trick) → [Documentation Home](../Documentation-Home) → [Web Server](Webserver) → Configuring Trick with Civetweb |
|------------------------------------------------------------------|

## Configuring Trick with Civetweb
To configure Trick to support the civetweb web server, you'll need to

1. Install Civetweb libs
   1. Download or clone Civetweb release (currently v1.16) from [Github](https://github.com/civetweb/civetweb). Where you put the Civetweb directory will be designated as $(CIVETWEB_HOME). Build the Civetweb library.
   2Use OS package manager
2. Configure Trick to use Civetweb.

### Package manager

Civetweb is available in both Enterprise Linux and Debian based distributions.
- [civetweb-devel in Enterprise Linux](https://pkgs.org/download/civetweb-devel)
- [libcivetweb-dev in Debian distributions](https://pkgs.org/search/?q=libcivetweb-dev)

#### Debian based distributions

```shell
sudo apt update && sudo apt install libcivetweb-dev
```

#### Enterprise Linux based distributions

```shell
sudo dnf -y install civetweb-devel
```

### Building the Civetweb Library

If you desire to compile from source instead

```bash
cd $(CIVETWEB_HOME)
mkdir lib
make install-lib PREFIX=. CAN_INSTALL=1 WITH_WEBSOCKET=1
```

### Configuring Trick with Civetweb
```bash
cd $(TRICK_HOME)
./configure --with-civetweb=$(CIVETWEB_HOME)
make clean
make
```

Continue to [Adding SSL Encryption](SSL)