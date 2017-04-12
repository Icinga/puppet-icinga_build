#!/bin/bash -xe

image_name=netways/$os-$release-$arch

apt-get update
apt-get install -y debootstrap gcc

keyring_arg=""

if [ "$arch" = "x86" ] ; then
  link_arch="i386"
else
  link_arch="$arch"
fi

if [[ "$arch" == "arm*" ]] ; then
  debootstrap_cmd=qemu-debootstrap

  if [ "$release" = "squeeze" ]; then
    echo "armhf/armel is not supported for Debian squeeze"
    exit 0
  fi

  apt-get install -y qemu-user-static
fi

case $os in
debian)
  mirror="http://mirror.noris.net/debian/"
  components="main"
  ;;
ubuntu)
  mirror="http://mirror.noris.net/ubuntu/"
  components="main,multiverse,universe"
  ;;
raspbian)
  mirror="http://archive.raspbian.org/raspbian"
  components="main"

  wget -O - https://archive.raspbian.org/raspbian.public.key | gpg --import
  keyring_arg="--keyring $HOME/.gnupg/pubring.gpg"
  ;;
esac

debootstrap_cmd=debootstrap

if [[ "$arch" == "arm*" ]] ; then
  debootstrap_cmd=qemu-debootstrap

  if [ "$release" = "squeeze" ]; then
    echo "armhf/armel is not supported for Debian squeeze"
    exit 0
  fi

  apt-get install -y qemu-user-static
fi

destdir=`mktemp -d`
mount -t tmpfs none $destdir
$debootstrap_cmd $keyring_arg --verbose --components=$components --include=debhelper --arch=$arch $release $destdir $mirror

if [ "$os" = "debian" ]; then
  cat > $destdir/etc/apt/sources.list <<APT
# $release
deb     http://mirror.noris.net/debian $release          main contrib non-free
deb-src http://mirror.noris.net/debian $release          main contrib non-free

APT

  if [ "$release" != "unstable" ]; then
    cat >> $destdir/etc/apt/sources.list <<APT
# $release-security
deb     http://security.debian.org/  $release/updates  main contrib non-free
deb-src http://security.debian.org/  $release/updates  main contrib non-free
APT
  fi
fi

if [ "$os" = "raspbian" ]; then
  cat > $destdir/etc/apt/sources.list <<APT
deb http://mirrordirector.raspbian.org/raspbian $release main firmware
deb http://archive.raspberrypi.org/debian $release main
APT

  chroot $destdir apt-key adv --keyserver keyserver.ubuntu.com --recv-key 82B129927FA3303E
fi

chroot $destdir apt-get update
chroot $destdir apt-get install --no-install-recommends -y --force-yes ccache build-essential:native bison ssh-client cmake flex g++ libboost-dev libboost-program-options-dev libboost-regex-dev libboost-system-dev libboost-test-dev libboost-thread-dev libmysqlclient-dev libpq-dev libssl-dev libyajl-dev fakeroot git devscripts sudo curl python wget pkg-config `cat jenkins-scripts/modules/extra-debian-packages`

if [ "$release" = "xenial" ]; then
  chroot $destdir apt-get install -y libwxgtk3.0-dev
fi

gcc --static -o $destdir/usr/bin/root_exec jenkins-scripts/modules/root_exec.c
chroot $destdir chmod ug+s /usr/bin/root_exec

chroot $destdir groupadd -g 1000 jenkins
chroot $destdir useradd -u 1000 -g 1000 -m jenkins
echo 'jenkins ALL=(ALL:ALL) NOPASSWD: ALL' | chroot $destdir tee -a /etc/sudoers

tar c -C $destdir --one-file-system . | docker import - $image_name

umount -R $destdir

source jenkins-scripts/docker/push_docker_image.sh
