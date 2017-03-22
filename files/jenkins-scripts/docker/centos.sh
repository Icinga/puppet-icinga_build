#!/bin/bash -xe

env

image_name=netways/$os-$release-$arch

if [ "$arch" = "x86" ] ; then
  link_arch="i386"
  if [  "$release" = "7" ] ; then
    echo "x86 is not supported for CentOS 7"
	false
  fi
else
  link_arch="$arch"
fi

apt-get update
apt-get install -y yum rpm python-m2crypto wget python-lzma db-util gcc wget

#echo 'DOCKER_OPTS="--insecure-registry net-docker-registry.adm.netways.de:5000"' >> /etc/default/docker
#
#rm -f /var/run/docker.pid
#service docker start

destdir=`mktemp -d`
mount -t tmpfs none $destdir

mkdir $destdir/dev 
mount -o bind /dev $destdir/dev

cat >$HOME/.rpmmacros <<MACROS
%_dbpath /var/lib/rpm
MACROS

rpm --initdb --root $destdir

case $os in 
fedora)
  case $release in
  23 | 24 | 25)
	wget ftp://mirror.switch.ch/pool/4/mirror/fedora/linux/releases/$release/Server/$link_arch/os/Packages/f/fedora-release-$release-1.noarch.rpm
	wget ftp://mirror.switch.ch/pool/4/mirror/fedora/linux/releases/$release/Server/$link_arch/os/Packages/f/fedora-repos-$release-1.noarch.rpm
  ;;
  *)
    echo "Invalid release $release specified."
    exit 1
  ;;
  esac
;;
centos)
  case $release in
  5)
	wget ftp://mirror.switch.ch/pool/4/mirror/centos/5.11/os/$link_arch/CentOS/centos-release-5-11.el5.centos.$link_arch.rpm
  ;;
  6)
    if [ "$link_arch" = "i386" ]; then
	  wget ftp://mirror.switch.ch/pool/4/mirror/centos/6.8/os/$link_arch/Packages/centos-release-6-8.el6.centos.12.3.i686.rpm
	else
      wget ftp://mirror.switch.ch/pool/4/mirror/centos/6.8/os/$link_arch/Packages/centos-release-6-8.el6.centos.12.3.$link_arch.rpm
	fi
  ;;
  7)
    wget http://mirror.centos.org/centos/7/os/x86_64/Packages/centos-release-7-3.1611.el7.centos.x86_64.rpm
  ;;
  *)
    echo "Invalid release $release specified."
    exit 1
  ;;
  esac
  ;;
*)
  echo "Invalid os $os specified."
  exit 1
  ;;
esac

rpm -ivh --force-debian --nodeps --root $destdir *.rpm

rm -f /etc/pki/rpm-gpg
rm -f /etc/yum.repos.d

mkdir -p /etc/pki/

ln -s $destdir/etc/pki/rpm-gpg/ /etc/pki/
ln -s $destdir/etc/yum.repos.d/ /etc/

setarch $link_arch yum --installroot $destdir install -y yum db4-utils buildsys-macros 
mv $destdir/var/lib/rpm/Packages $destdir/var/lib/rpm/Packages.old
db_dump $destdir/var/lib/rpm/Packages.old | chroot $destdir db_load /var/lib/rpm/Packages
rm -f $destdir/var/lib/rpm/Packages.old
chroot $destdir rpm --rebuilddb

echo nameserver 8.8.8.8 > $destdir/etc/resolv.conf

gcc --static -o $destdir/usr/bin/root_exec jenkins-scripts/docker/root_exec.c
chroot $destdir chmod ug+s /usr/bin/root_exec

source jenkins-scripts/docker/repo_epel_chroot.sh

setarch_pkg=""
if [ "$os-$release" = "centos-5" ]; then
  setarch_pkg="setarch"
fi

success=0
for i in $(seq 10); do
  setarch $link_arch chroot $destdir yum update -y
  if setarch $link_arch chroot $destdir yum install -y sudo wget patch which rpm-build redhat-rpm-config yum-utils rpm-sign tar expect ccache gcc gcc-c++ patch rpmlint make util-linux git iproute curl $setarch_pkg `cat jenkins-scripts/docker/extra-centos-packages` ; then
    success=1
    break;
  fi
  sleep 10
done
if [ "0" == "$success" ]; then
  exit 1
fi

chroot $destdir groupadd -g 1000 jenkins
chroot $destdir useradd -u 1000 -g 1000 -m jenkins
umount $destdir/dev
echo 'jenkins ALL=(ALL:ALL) NOPASSWD: ALL' | chroot $destdir tee -a /etc/sudoers
echo 'Defaults:jenkins !requiretty' | chroot $destdir tee -a /etc/sudoers

tar c -C $destdir --one-file-system . | docker import - $image_name

umount -R $destdir

source jenkins-scripts/docker/push_docker_image.sh
