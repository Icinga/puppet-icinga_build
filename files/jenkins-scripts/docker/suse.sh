#!/bin/bash -xe

image_name=netways/$os-$release-$arch

if [ "$arch" = "x86" ] ; then
  link_arch="i386"
  if [[ "$release" == "12-*" ]] ; then
    echo "No x86 builds for sles 12"
	false
  fi
else
  link_arch="$arch"
fi

apt-get update
apt-get install -y zypper db-util gcc

mkdir -p /tmp/scripts/
cat >/tmp/scripts/rpm << PYTHON
#!/usr/bin/env python
import os, sys
args = ['/usr/bin/rpm']
for arg in sys.argv[1:]:
  if arg != '--noposttrans':
      args.append(arg)
os.execv(args[0], args)
PYTHON

chmod +x /tmp/scripts/rpm
export PATH="/tmp/scripts/:$PATH"

destdir=`mktemp -d`
mount -t tmpfs none $destdir

case $os in
opensuse)
  release_package=openSUSE-release
  case $release in
  13.2)
    zypper --root $destdir ar http://ftp.uni-erlangen.de/pub/mirrors/opensuse/distribution/13.2/repo/oss/ repo-oss
    zypper --root $destdir ar http://ftp.uni-erlangen.de/pub/mirrors/opensuse/distribution/13.2/repo/non-oss/ repo-non-oss
    ;;
  42.1)
    zypper --root $destdir ar http://ftp.uni-erlangen.de/pub/mirrors/opensuse/distribution/leap/42.1/repo/oss/ repo-oss
    zypper --root $destdir ar http://ftp.uni-erlangen.de/pub/mirrors/opensuse/distribution/leap/42.1/repo/non-oss/ repo-non-oss
    ;;
  *)
    echo "Unknown release $release"
    exit 1
    ;;
  esac
  ;;
sles)
  release_package=sles-release
  mkdir -p $destdir/etc/zypp/repos.d/
  case $release in
  11-sp4)
    cat >$destdir/etc/zypp/repos.d/$link_arch-dvd1.repo <<REPO
[$link_arch-dvd1]
name=SLES 11 SP4 (DVD1)
enabled=1
autorefresh=0
baseurl=http://`cat jenkins-scripts/modules/mirror_passwd`@dvd-images.icinga.com/sles_dvds/11-$arch-dvd1
type=yast2
REPO
    cat >$destdir/etc/zypp/repos.d/sdk-$link_arch-dvd1.repo <<REPO
[sdk-$link_arch-dvd1]
name=SLES 11 SP4 SDK (DVD1)
enabled=1
autorefresh=0
baseurl=http://`cat jenkins-scripts/modules/mirror_passwd`@dvd-images.icinga.com/sles_dvds/11-sdk-$arch-dvd1
type=yast2
REPO
    zypper --no-gpg-checks --non-interactive --root $destdir ref
    ;;
  12-sp1 | 12-sp2)
    cat >$destdir/etc/zypp/repos.d/$link_arch-dvd1.repo <<REPO
[$link_arch-dvd1]
name=SLES 12 (DVD1)
enabled=1
autorefresh=0
baseurl=http://`cat jenkins-scripts/modules/mirror_passwd`@dvd-images.icinga.com/sles_dvds/$os-$release-$arch-dvd1
type=yast2
REPO
    cat >$destdir/etc/zypp/repos.d/sdk-$link_arch-dvd1.repo <<REPO
[sdk-$link_arch-dvd1]
name=SLES 12 SDK (DVD1)
enabled=1
autorefresh=0
baseurl=http://`cat jenkins-scripts/modules/mirror_passwd`@dvd-images.icinga.com/sles_dvds/$os-$release-sdk-$arch-dvd1
type=yast2
REPO
    zypper --no-gpg-checks --non-interactive --root $destdir ref
    ;;
  *)
    echo "Unknown release $release"
    exit 1
    ;;
  esac
  ;;
*)
  echo "Unknown os $os"
  exit 1
  ;;
esac


mkdir $destdir/dev
cp -a /dev/zero $destdir/dev/

if [ "$release" != "11-sp4" ]; then
  certs=ca-certificates
fi

setarch $link_arch zypper --no-gpg-checks --non-interactive --root $destdir install --auto-agree-with-licenses --no-recommends aaa_base $release_package rpm zypper sudo curl wget expect ccache gcc patch rpmlint gawk db-utils git tar python-xml iproute2 $certs `cat jenkins-scripts/modules/extra-sles-packages`

if [ "$release" != "11-sp4" ]; then
  cp jenkins-scripts/modules/stern.suse.com $destdir/etc/pki/trust/anchors/*.suse.com
  chroot $destdir update-ca-certificates
fi

mv $destdir/var/lib/rpm/Packages $destdir/var/lib/rpm/Packages.old
db_dump $destdir/var/lib/rpm/Packages.old | chroot $destdir db_load /var/lib/rpm/Packages
rm -f $destdir/var/lib/rpm/Packages.old
chroot $destdir rpm --rebuilddb

gcc --static -o $destdir/usr/bin/root_exec jenkins-scripts/modules/root_exec.c
chroot $destdir chmod ug+s /usr/bin/root_exec

echo nameserver 8.8.8.8 > $destdir/etc/resolv.conf

chroot $destdir groupadd -g 1000 jenkins
chroot $destdir useradd -u 1000 -g 1000 -m jenkins
echo 'jenkins ALL=(ALL:ALL) NOPASSWD: ALL' | chroot $destdir tee -a /etc/sudoers

tar c -C $destdir --one-file-system . | docker import - $image_name

umount -R $destdir

source jenkins-scripts/docker/push_docker_image.sh
