#!/bin/bash

set -ex

: ${os:=}
: ${release:=}
: ${arch:=}
: ${IMAGE_PREFIX:='netways/'}
: ${MIRROR_DEBIAN:=http://cdn-fastly.deb.debian.org/debian}
: ${MIRROR_UBUNTU:=http://archive.ubuntu.com/ubuntu}

if [ -z "$os" ]; then
  echo "env variable 'os' not set!" >&2
  exit 1
elif [ -z "$release" ]; then
  echo "env variable 'release' not set!" >&2
  exit 1
elif [ -z "$arch" ]; then
  echo "env variable 'arch' not set!" >&2
  exit 1
fi

image_name="${IMAGE_PREFIX}${os}-${release}-${arch}"

keyring=
keyring_arg=
debootstrap_cmd=debootstrap

if [ "$arch" = "x86" ] ; then
  link_arch="i386"
elif [ "$arch" = "x86_64" ] ; then
  link_arch="amd64"
else
  link_arch="$arch"
fi

case $os in
debian)
  mirror="${MIRROR_DEBIAN}/"
  components="main"
  keyring=debian-archive-keyring
  keyring_arg="--keyring /usr/share/keyrings/debian-archive-keyring.gpg"
  ;;
ubuntu)
  mirror="${MIRROR_UBUNTU}/"
  components="main,multiverse,universe"
  keyring=ubuntu-keyring
  ;;
raspbian)
  mirror="http://archive.raspbian.org/raspbian"
  components="main"

  wget -O - https://archive.raspbian.org/raspbian.public.key | gpg --import
  keyring_arg="--keyring $HOME/.gnupg/pubring.gpg"
  ;;
esac

apt-get update
apt-get install -y debootstrap ${keyring}

if [[ "$arch" == "arm*" ]] ; then
  # TODO: replace this
  echo "ARM disabled for now!" >&2
  exit 1

  debootstrap_cmd=qemu-debootstrap

  if [ "$release" = "squeeze" ]; then
    echo "armhf/armel is not supported for Debian squeeze"
    exit 0
  fi

  apt-get install -y qemu-user-static
fi

destdir=`mktemp -d`
mount -t tmpfs none $destdir
${debootstrap_cmd} ${keyring_arg} --verbose --components=$components --include=debhelper --arch=${link_arch} ${release} ${destdir} ${mirror}

if [ "$os" = "debian" ]; then
  cat > "$destdir"/etc/apt/sources.list <<APT
# ${release}
deb     ${MIRROR_DEBIAN}  ${release}  main contrib non-free
deb-src ${MIRROR_DEBIAN}  ${release}  main contrib non-free
APT

  if [ "$release" != "unstable" ]; then
    cat >> "$destdir"/etc/apt/sources.list <<APT
# ${release}-security
deb     http://security.debian.org/  ${release}/updates  main contrib non-free
deb-src http://security.debian.org/  ${release}/updates  main contrib non-free
APT
  fi
fi

if [ "$os" = "raspbian" ]; then
  cat > "$destdir"/etc/apt/sources.list <<APT
deb http://mirrordirector.raspbian.org/raspbian $release main firmware
deb http://archive.raspberrypi.org/debian $release main
APT

  chroot "$destdir" apt-key adv --keyserver keyserver.ubuntu.com --recv-key 82B129927FA3303E
fi

chroot ${destdir} apt-get update
chroot ${destdir} apt-get install \
  --no-install-recommends -y --force-yes \
  ccache build-essential:native bison ssh-client cmake flex g++ libboost-dev \
  libboost-program-options-dev libboost-regex-dev libboost-system-dev libboost-test-dev \
  libboost-thread-dev libssl-dev libyajl-dev fakeroot git \
  devscripts sudo curl python wget pkg-config ca-certificates libwww-perl libcrypt-ssleay-perl

if [ "$release" = "xenial" ]; then
  # TODO: why?
  chroot ${destdir} apt-get install -y libwxgtk3.0-dev
fi

# Add jenkins user
chroot $destdir groupadd -g 1000 jenkins
chroot $destdir useradd -u 1000 -g 1000 -m jenkins
echo 'jenkins ALL=(ALL:ALL) NOPASSWD: ALL' | chroot $destdir tee -a /etc/sudoers

tar c -C ${destdir} --one-file-system . | docker import - ${image_name}

umount -R ${destdir}

export image_name
./jenkins-scripts/docker/push_docker_image.sh
