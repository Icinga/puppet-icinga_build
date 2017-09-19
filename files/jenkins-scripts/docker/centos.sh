#!/bin/bash -xe

: ${os:=}
: ${release:=}
: ${arch:=}
: ${IMAGE_PREFIX:='netways/'}

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

# So that Debian's RPM creates the files in the correct location...
export HOME=/root
cat >$HOME/.rpmmacros <<MACROS
%_dbpath /var/lib/rpm
MACROS

rpm --initdb --root $destdir

case $os in 
fedora)
  case $release in
  23 | 24 | 25 | 26)
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
	wget http://vault.centos.org/5.11/os/$link_arch/CentOS/centos-release-5-11.el5.centos.$link_arch.rpm
  ;;
  6)
    rpmurl=http://mirror.centos.org/centos/6/os/x86_64/Packages/centos-release-6-9.el6.12.3.x86_64.rpm
    if [ "$link_arch" = "i386" ]; then
      rpmurl="${rpmurl/x86_64/$link_arch}" # in path
      rpmurl="${rpmurl/x86_64/i686}" # in file name
	fi
    wget "$rpmurl"
  ;;
  7)
    wget http://mirror.centos.org/centos/7/os/x86_64/Packages/centos-release-7-4.1708.el7.centos.x86_64.rpm
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

if [ "$os-$release" = "centos-5" ] ; then
  #Because centos 5 is kinda dead we need the Vault
  sed -ie 's/#baseurl=.*$/baseurl=http:\/\/vault.centos.org\/5\.11\/os\/\$basearch/g' $destdir/etc/yum.repos.d/CentOS-Base.repo
  sed -ie 's/mirrorlist.*//g' $destdir/etc/yum.repos.d/CentOS-Base.repo
  setarch $link_arch yum --installroot $destdir clean metadata
fi

# TODO: where do we need to do this??
setarch $link_arch yum --installroot $destdir install -y yum db4-utils buildsys-macros
mv $destdir/var/lib/rpm/Packages $destdir/var/lib/rpm/Packages.old
db_dump $destdir/var/lib/rpm/Packages.old | chroot $destdir db_load /var/lib/rpm/Packages
rm -f $destdir/var/lib/rpm/Packages.old
chroot $destdir rpm --rebuilddb

echo nameserver 8.8.8.8 > $destdir/etc/resolv.conf

# Update CA bundle
if [ "$os-$release" = "centos-5" ] ; then
  cp -v "$destdir"/etc/pki/tls/certs/ca-bundle.crt "$destdir"/root/ca-bundle.crt-old
  # Note: Download is done in build container, so we can download it via HTTPS
  wget https://curl.haxx.se/ca/cacert.pem -O "$destdir"/etc/pki/tls/certs/ca-bundle.crt
fi

# Install EPEL
if [ "$os-$release" = "centos-5" ] ; then
  wget -O "$destdir"/tmp/epel-release.rpm https://archives.fedoraproject.org/pub/archive/epel/epel-release-latest-"$release".noarch.rpm
  chroot "$destdir" sh -ex <<EOF
    rpm -Uvh /tmp/epel-release.rpm
    rm -f /tmp/epel-release.rpm
EOF
elif [ "$os" = centos ]; then
  chroot "$destdir" rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-"$release".noarch.rpm
fi

# Add devtools-2 repository
devtools='gcc gcc-c++'
if [ "$os-$release" = "centos-5" ] || [ "$os-$release" = "centos-6" ]; then
  wget -O "$destdir"/etc/yum.repos.d/devtools-2.repo https://people.centos.org/tru/devtools-2/devtools-2.repo
  devtools='devtoolset-2-gcc devtoolset-2-gcc-c++ devtoolset-2-binutils'
fi

# Add repoforge for newer devtools on CentOS 5
if [ "$os-$release" = "centos-5" ]; then
  cat >/etc/yum.repos.d/repoforge-buildtools.repo <<REPO
[repoforge-buildtools]
name=RepoForge buildtools
baseurl=http://mirror.hs-esslingen.de/repoforge/redhat/el\$releasever/en/\$basearch/buildtools/
enabled=1
gpgcheck=0
REPO
fi

# Add Icinga's own repository, so we can ship build dependencies
icinga_repo=
if [ "$os" = "centos" ]; then
  icinga_repo=epel
elif [ "$os" = "fedora" ]; then
  icinga_repo=fedora
fi
if [ -n "$icinga_repo" ]; then
  wget -O "$destdir"/etc/yum.repos.d/ICINGA-release.repo https://packages.icinga.com/"${icinga_repo}"/ICINGA-release.repo
  sed -i 's#http://#https://#' "$destdir"/etc/yum.repos.d/ICINGA-release.repo
fi

setarch_pkg=""
if [ "$os-$release" = "centos-5" ]; then
  setarch_pkg="setarch"
fi

success=0
# TODO: why retry??
for i in $(seq 10); do
  setarch $link_arch chroot $destdir yum update -y
  yumopts=
  if [ "$os" = fedora ]; then
    yumopts='--allowerasing'
  fi
  # TODO: remove extra packages file?
  if setarch $link_arch chroot $destdir yum install -y $yumopts \
    sudo wget patch which rpm-build redhat-rpm-config yum-utils rpm-sign tar \
    expect ccache patch rpmlint make util-linux git iproute curl ${devtools} \
    yum-plugin-ovl $setarch_pkg `cat jenkins-scripts/docker/extra-centos-packages`
   then
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

# TODO: Remove this once the build deps for boost have been cleaned up...
echo '%build_icinga_org 1' >"$destdir"/etc/rpm/macros.icinga_build

tar c -C $destdir --one-file-system . | docker import - $image_name

umount -R $destdir

export image_name
./jenkins-scripts/docker/push_docker_image.sh
