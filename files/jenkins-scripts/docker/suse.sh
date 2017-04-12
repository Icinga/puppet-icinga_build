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
apt-get install -y zypper db-util gnupg2

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
    zypper --root $destdir ar http://ftp.uni-erlangen.de/opensuse/distribution/13.2/repo/oss/ repo-oss
    zypper --root $destdir ar http://ftp.uni-erlangen.de/opensuse/distribution/13.2/repo/non-oss/ repo-non-oss
    ;;
  42.1)
    zypper --root $destdir ar http://ftp.uni-erlangen.de/opensuse/distribution/leap/42.1/repo/oss/ repo-oss
    zypper --root $destdir ar http://ftp.uni-erlangen.de/opensuse/distribution/leap/42.1/repo/non-oss/ repo-non-oss
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
baseurl=http://`cat jenkins-scripts/docker/mirror_passwd`@dvd-images.icinga.com/sles_dvds/11-$arch-dvd1
type=yast2
REPO
    cat >$destdir/etc/zypp/repos.d/sdk-$link_arch-dvd1.repo <<REPO
[sdk-$link_arch-dvd1]
name=SLES 11 SP4 SDK (DVD1)
enabled=1
autorefresh=0
baseurl=http://`cat jenkins-scripts/docker/mirror_passwd`@dvd-images.icinga.com/sles_dvds/11-sdk-$arch-dvd1
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
baseurl=http://`cat jenkins-scripts/docker/mirror_passwd`@dvd-images.icinga.com/sles_dvds/$os-$release-$arch-dvd1
type=yast2
REPO
    cat >$destdir/etc/zypp/repos.d/sdk-$link_arch-dvd1.repo <<REPO
[sdk-$link_arch-dvd1]
name=SLES 12 SDK (DVD1)
enabled=1
autorefresh=0
baseurl=http://`cat jenkins-scripts/docker/mirror_passwd`@dvd-images.icinga.com/sles_dvds/$os-$release-sdk-$arch-dvd1
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

setarch $link_arch zypper \
    --no-gpg-checks --non-interactive --root $destdir \
    install --auto-agree-with-licenses --no-recommends \
    aaa_base $release_package rpm zypper sudo curl wget expect ccache gcc \
    patch rpmlint gawk db-utils git tar python-xml iproute2 $certs \
    cmake flex bison libedit-devel

if [ "$release" != "11-sp4" ]; then
  cat > "$destdir"/etc/pki/trust/anchors/"*.suse.com" <<EOF
-----BEGIN CERTIFICATE-----
MIIFRTCCBC2gAwIBAgIQCJJb06QMRgTclTHp7CPI7jANBgkqhkiG9w0BAQsFADBw
MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
d3cuZGlnaWNlcnQuY29tMS8wLQYDVQQDEyZEaWdpQ2VydCBTSEEyIEhpZ2ggQXNz
dXJhbmNlIFNlcnZlciBDQTAeFw0xNDAyMTkwMDAwMDBaFw0xNzAyMjMxMjAwMDBa
MGYxCzAJBgNVBAYTAlVTMQ0wCwYDVQQIEwRVdGFoMQ4wDAYDVQQHEwVQcm92bzEU
MBIGA1UEChMLTm92ZWxsIEluYy4xDTALBgNVBAsMBElTJlQxEzARBgNVBAMMCiou
c3VzZS5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC24fXxqwyo
3cpQFiYTdErISZJ3zCGcE6pGgtWWGFSa3Zp96YLedc+kzczryoI1RbXoUTCKy9lQ
15l4i9Mg9IGGvBtV2pTOsUcirIDW0TDIxJyIIVJdOmI47jsb1dydc+Okb1qY0A4+
eGuonV902WQIGxHNMJ3iLOrT0H9oN3HQyHoz67FIjboJZY7P9E3PeE3M66GZZNxd
Nk4RvHx4eswr7A/PmDRhQYvGzw+Hv5dJtbVBVjcaIx2vG2fe5VjgZG2djuVaqY2S
QjEB3rOZ+oGMaAkDM2Jxi6p/AZ0a/FSKzc9Bcbe64n3pCyKNDYhn0+XoAlIjhnUx
Uw7E1ypxI7XXAgMBAAGjggHjMIIB3zAfBgNVHSMEGDAWgBRRaP+QrwIHdTzM2WVk
YqISuFlyOzAdBgNVHQ4EFgQU9MJIZf42kcfvXCCIMNUphNPj4ZUwHwYDVR0RBBgw
FoIKKi5zdXNlLmNvbYIIc3VzZS5jb20wDgYDVR0PAQH/BAQDAgWgMB0GA1UdJQQW
MBQGCCsGAQUFBwMBBggrBgEFBQcDAjB1BgNVHR8EbjBsMDSgMqAwhi5odHRwOi8v
Y3JsMy5kaWdpY2VydC5jb20vc2hhMi1oYS1zZXJ2ZXItZzEuY3JsMDSgMqAwhi5o
dHRwOi8vY3JsNC5kaWdpY2VydC5jb20vc2hhMi1oYS1zZXJ2ZXItZzEuY3JsMEIG
A1UdIAQ7MDkwNwYJYIZIAYb9bAEBMCowKAYIKwYBBQUHAgEWHGh0dHBzOi8vd3d3
LmRpZ2ljZXJ0LmNvbS9DUFMwgYMGCCsGAQUFBwEBBHcwdTAkBggrBgEFBQcwAYYY
aHR0cDovL29jc3AuZGlnaWNlcnQuY29tME0GCCsGAQUFBzAChkFodHRwOi8vY2Fj
ZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEySGlnaEFzc3VyYW5jZVNlcnZl
ckNBLmNydDAMBgNVHRMBAf8EAjAAMA0GCSqGSIb3DQEBCwUAA4IBAQBm2v03RxLC
0apPDfBKPt+ADVMrhoTeg8jaPgrZSTORCJEjNVGkYIWGdrTE9KiPpxG2UvIfD11Y
g+Qk/TgbUW4bPanejUlFxHPezobu/nKBRhjjS6znKhu0JXBEzyAn9ypRTXi10LEc
0RnkXcLydEIVSnc8YOOqMaFpjEPxKANzKDMbCsOv9HwAGjg5t4WKKzGgZGB3WfeR
dZ3NFGbaGE1qcFFa0F1N3KdI6BDQw8jYCGJVh2Ovn+bm9mbyF6TbrEz5p+3rGdpp
/Ghcr0+W6ERtmBRa3P832XbeD6njnliBnLCZ3wIRTEbggCPG6H05FOZax4/GvEw8
mcBakud04KvE
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIEsTCCA5mgAwIBAgIQBOHnpNxc8vNtwCtCuF0VnzANBgkqhkiG9w0BAQsFADBs
MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
d3cuZGlnaWNlcnQuY29tMSswKQYDVQQDEyJEaWdpQ2VydCBIaWdoIEFzc3VyYW5j
ZSBFViBSb290IENBMB4XDTEzMTAyMjEyMDAwMFoXDTI4MTAyMjEyMDAwMFowcDEL
MAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3
LmRpZ2ljZXJ0LmNvbTEvMC0GA1UEAxMmRGlnaUNlcnQgU0hBMiBIaWdoIEFzc3Vy
YW5jZSBTZXJ2ZXIgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC2
4C/CJAbIbQRf1+8KZAayfSImZRauQkCbztyfn3YHPsMwVYcZuU+UDlqUH1VWtMIC
Kq/QmO4LQNfE0DtyyBSe75CxEamu0si4QzrZCwvV1ZX1QK/IHe1NnF9Xt4ZQaJn1
itrSxwUfqJfJ3KSxgoQtxq2lnMcZgqaFD15EWCo3j/018QsIJzJa9buLnqS9UdAn
4t07QjOjBSjEuyjMmqwrIw14xnvmXnG3Sj4I+4G3FhahnSMSTeXXkgisdaScus0X
sh5ENWV/UyU50RwKmmMbGZJ0aAo3wsJSSMs5WqK24V3B3aAguCGikyZvFEohQcft
bZvySC/zA/WiaJJTL17jAgMBAAGjggFJMIIBRTASBgNVHRMBAf8ECDAGAQH/AgEA
MA4GA1UdDwEB/wQEAwIBhjAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIw
NAYIKwYBBQUHAQEEKDAmMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2Vy
dC5jb20wSwYDVR0fBEQwQjBAoD6gPIY6aHR0cDovL2NybDQuZGlnaWNlcnQuY29t
L0RpZ2lDZXJ0SGlnaEFzc3VyYW5jZUVWUm9vdENBLmNybDA9BgNVHSAENjA0MDIG
BFUdIAAwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQuY29tL0NQ
UzAdBgNVHQ4EFgQUUWj/kK8CB3U8zNllZGKiErhZcjswHwYDVR0jBBgwFoAUsT7D
aQP4v0cB1JgmGggC72NkK8MwDQYJKoZIhvcNAQELBQADggEBABiKlYkD5m3fXPwd
aOpKj4PWUS+Na0QWnqxj9dJubISZi6qBcYRb7TROsLd5kinMLYBq8I4g4Xmk/gNH
E+r1hspZcX30BJZr01lYPf7TMSVcGDiEo+afgv2MW5gxTs14nhr9hctJqvIni5ly
/D6q1UEL2tU2ob8cbkdJf17ZSHwD2f2LSaCYJkJA69aSEaRkCldUxPUd1gJea6zu
xICaEnL6VpPX/78whQYwvwt/Tv9XBZ0k7YXDK/umdaisLRbvfXknsuvCnQsH6qqF
0wGjIChBWUMo0oHjqvbsezt3tkBigAVBRQHvFwY+3sAzm2fTYS5yh+Rp/BIAV0Ae
cPUeybQ=
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIDxTCCAq2gAwIBAgIQAqxcJmoLQJuPC3nyrkYldzANBgkqhkiG9w0BAQUFADBs
MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
d3cuZGlnaWNlcnQuY29tMSswKQYDVQQDEyJEaWdpQ2VydCBIaWdoIEFzc3VyYW5j
ZSBFViBSb290IENBMB4XDTA2MTExMDAwMDAwMFoXDTMxMTExMDAwMDAwMFowbDEL
MAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3
LmRpZ2ljZXJ0LmNvbTErMCkGA1UEAxMiRGlnaUNlcnQgSGlnaCBBc3N1cmFuY2Ug
RVYgUm9vdCBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMbM5XPm
+9S75S0tMqbf5YE/yc0lSbZxKsPVlDRnogocsF9ppkCxxLeyj9CYpKlBWTrT3JTW
PNt0OKRKzE0lgvdKpVMSOO7zSW1xkX5jtqumX8OkhPhPYlG++MXs2ziS4wblCJEM
xChBVfvLWokVfnHoNb9Ncgk9vjo4UFt3MRuNs8ckRZqnrG0AFFoEt7oT61EKmEFB
Ik5lYYeBQVCmeVyJ3hlKV9Uu5l0cUyx+mM0aBhakaHPQNAQTXKFx01p8VdteZOE3
hzBWBOURtCmAEvF5OYiiAhF8J2a3iLd48soKqDirCmTCv2ZdlYTBoSUeh10aUAsg
EsxBu24LUTi4S8sCAwEAAaNjMGEwDgYDVR0PAQH/BAQDAgGGMA8GA1UdEwEB/wQF
MAMBAf8wHQYDVR0OBBYEFLE+w2kD+L9HAdSYJhoIAu9jZCvDMB8GA1UdIwQYMBaA
FLE+w2kD+L9HAdSYJhoIAu9jZCvDMA0GCSqGSIb3DQEBBQUAA4IBAQAcGgaX3Nec
nzyIZgYIVyHbIUf4KmeqvxgydkAQV8GK83rZEWWONfqe/EW1ntlMMUu4kehDLI6z
eM7b41N5cdblIZQB2lWHmiRk9opmzN6cN82oNLFpmyPInngiK3BD41VHMWEZ71jF
hS9OMPagMRYjyOfiZRYzy78aG6A9+MpeizGLYAiJLQwGXFK3xPkKmNEVX58Svnw2
Yzi9RKR/5CYrCsSXaQ3pjOLAEFe4yHYSkVXySGnYvCoCWw9E1CAx2/S6cCZdkGCe
vEsXCS+0yx5DaMkHJ8HSXPfqIbloEpw8nL+e/IBcm2PN7EeqJSdnoDfzAIJ9VNep
+OkuE6N36B9K
-----END CERTIFICATE-----
EOF
  chroot $destdir update-ca-certificates
fi

echo nameserver 8.8.8.8 > $destdir/etc/resolv.conf

chroot $destdir groupadd -g 1000 jenkins
chroot $destdir useradd -u 1000 -g 1000 -m jenkins
echo 'jenkins ALL=(ALL:ALL) NOPASSWD: ALL' | chroot "$destdir" tee -a /etc/sudoers

tar c -C $destdir --one-file-system . | docker import - $image_name

umount -R $destdir

source jenkins-scripts/docker/push_docker_image.sh
