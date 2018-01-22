#!/bin/bash

set -ex

: ${os:=}
: ${release:=}
: ${arch:=}
: ${SLES_MIRROR:=}
: ${SLES_MIRROR_USERNAME:=}
: ${SLES_MIRROR_PASSWORD:=}
: ${OPENSUSE_MIRROR:='http://ftp.uni-erlangen.de/opensuse/distribution'}
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

if [ ${os} = sles ] && [ -z ${SLES_MIRROR:=} ]; then
  echo "You need to configure SLES_MIRROR in order to build SLES images!" >&2
  exit 1
fi

image_name="${IMAGE_PREFIX}${os}-${release}-${arch}"

# check architecture
if [ "$arch" = "x86" ] ; then
  link_arch="i386"
  if [[ "$release" == 12* ]] ; then
    echo "No x86 builds for sles 12 possible"
	false
  fi
else
  link_arch="$arch"
fi

# Install tools
apt-get update
apt-get install -y zypper db-util gnupg2

# create tempdir for installation
destdir=/tmp/target
test -d "$destdir" || mkdir "$destdir"
# NOTE: This is probably the only reason for privileged(?)
mount -t tmpfs none "$destdir"

# setting correct home, so zypper can find the credentials
export HOME=/root

run_zypper() {
  setarch ${link_arch} zypper --root "$destdir" --gpg-auto-import-keys "$@"
}

if [ -n ${SLES_MIRROR_USERNAME} ]; then
  echo "Creating credentials file /root/.zypp/credentials.cat"
  mkdir -p "$destdir"/root/.zypp
  cat >"$destdir"/root/.zypp/credentials.cat <<EOF
[${SLES_MIRROR}]
username = ${SLES_MIRROR_USERNAME}
password = ${SLES_MIRROR_PASSWORD}
EOF
fi

# Setup repositories in target
case "$os" in
opensuse)
  release_package=openSUSE-release
  case "$release" in
  13*)
    run_zypper ar "$OPENSUSE_MIRROR"/"$release"/repo/oss/ repo-oss
    run_zypper ar "$OPENSUSE_MIRROR"/"$release"/repo/non-oss/ repo-non-oss
    ;;
  42*)
    run_zypper ar "$OPENSUSE_MIRROR"/leap/"$release"/repo/oss/ repo-oss
    run_zypper ar "$OPENSUSE_MIRROR"/leap/"$release"/repo/non-oss/ repo-non-oss
    ;;
  *)
    echo "Unknown opensuse release $release"
    exit 1
    ;;
  esac
  ;;
sles)
  release_package=sles-release
  case "$release" in
  11-sp4|11.4)
    run_zypper ar "${SLES_MIRROR}/sles_dvds/11-${arch}-dvd1" "${link_arch}-dvd1"
    run_zypper ar "${SLES_MIRROR}/sles_dvds/11-sdk-${arch}-dvd1" "sdk-${link_arch}-dvd1"
    run_zypper ar "${SLES_MIRROR}/sles_repos/11-security-${arch}" "security-${link_arch}"
    ;;
  12.*)
    repo_release=${release/./-sp}
    run_zypper ar "${SLES_MIRROR}/sles_dvds/${os}-${repo_release}-${arch}-dvd1" "${link_arch}-dvd1"
#   run_zypper ar "${SLES_MIRROR}/sles_dvds/${os}-${repo_release}-sdk-${arch}-dvd1" "sdk-${link_arch}-dvd1"
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

run_zypper --non-interactive --no-gpg-checks ref

# TODO: not sure if we really need this
mkdir "$destdir/dev"
cp -a /dev/zero "$destdir/dev/"

if [[ "$release" == 11* ]]; then
  certs=openssl-certs
else
  certs='ca-certificates ca-certificates-mozilla'
fi

if [[ "$release" == 11* ]]; then
    # on SLES 11, rpmbuild is part of the rpm package
    rpmbuild=
    gpgcheck='--no-gpg-check'
else
    rpmbuild=rpm-build
    gpgcheck=
fi

# Run the chroot installation
run_zypper --non-interactive ${gpgcheck} install \
    --auto-agree-with-licenses --no-recommends \
    aaa_base ${release_package} rpm ${rpmbuild} zypper sudo curl wget expect ccache gcc \
    patch rpmlint gawk db-utils git tar python-xml iproute2 ${certs}

if [ "$os" = sles ]; then
  # repair base product link
  if [[ "$release" == 11* ]]; then
    product=SUSE_SLES
  else
    product=SLES
  fi
  ln -s ${product}.prod "$destdir"/etc/products.d/baseproduct
fi

if [[ "$release" == 11* ]]; then
    echo "Converting / repairing RPMdb for SLES 11"
    # We need to do this so the database is readable by SLES 11's RPM
    #
    # rpmdb: /var/lib/rpm/Packages: unsupported hash version: 9
    # error: cannot open Packages index using db3 - Invalid argument (22)
    # error: cannot open Packages database in /var/lib/rpm
    # Target initialization failed:
    # Rpm Exception
    mv "$destdir"/var/lib/rpm/Packages "$destdir"/var/lib/rpm/Packages.old
    db_dump "$destdir"/var/lib/rpm/Packages.old | chroot "$destdir" db_load /var/lib/rpm/Packages
    rm -f "$destdir"/var/lib/rpm/Packages.old
    chroot "$destdir" rpm --rebuilddb
fi

echo 'nameserver 8.8.8.8' > "$destdir/etc/resolv.conf"

# The following steps need a bit of help in the chroot
mount -o bind /dev "$destdir/dev"
mount -o bind /proc "$destdir/proc"
mount -o bind /sys "$destdir/sys"

# refresh repos inside the chroot
chroot "$destdir" zypper clean -a
chroot "$destdir" zypper --non-interactive --no-gpg-checks --gpg-auto-import-keys ref

# Activate image against SUSE repositories
# These uses private credentials by the terms of a test license
# See production hiera settings!
if [ "$os" = sles ]; then
  activation_file=
  if [[ "$release" == 11* ]]; then
    activation_file=jenkins-scripts/docker/sles-activation11.sh
  elif [[ "$release" == 12* ]]; then
    activation_file=jenkins-scripts/docker/sles-activation12.sh
  fi

  if [ -n ${activation_file} ] && [ -e ${activation_file} ]; then
    cp ${activation_file} "$destdir"/tmp/activation.sh

    echo "Running activation..."
    chroot "$destdir" /tmp/activation.sh
    rm -f "$destdir"/tmp/activation.sh

    echo "Running update after activation..."
    chroot "$destdir" zypper update -y
  else
    echo "WARNING: Activation file missing! ${activation_file}" >&2
  fi
fi

# Add Icinga's own repository, so we can ship build dependencies
repo_name=
case "$os" in
  sles)
    repo_name=SUSE
    ;;
  # Not needed on OpenSUSE currently...
  #opensuse)
  #  repo_name=openSUSE
  #  ;;
  *)
    echo "Can't add Icinga repo for os $os" >&2
    ;;
esac

test -z ${repo_name} || chroot "$destdir" sh -ex <<ICINGAREPO
  zypper addrepo https://packages.icinga.com/${repo_name}/ICINGA-release.repo
  zypper --non-interactive --no-gpg-checks --gpg-auto-import-keys ref
ICINGAREPO

# Add jenkins user
chroot "$destdir" groupadd -g 1000 jenkins
chroot "$destdir" useradd -u 1000 -g 1000 -m jenkins
echo 'jenkins ALL=(ALL:ALL) NOPASSWD: ALL' | chroot "$destdir" tee -a /etc/sudoers

# TODO: Remove this once the build deps for boost have been cleaned up...
echo '%build_icinga_org 1' >"$destdir"/etc/rpm/macros.icinga_build

tar c -C "$destdir" --one-file-system . | docker import - "$image_name"

umount -R "$destdir"

export image_name
./jenkins-scripts/docker/push_docker_image.sh
