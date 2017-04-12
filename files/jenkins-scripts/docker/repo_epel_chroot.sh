#!/bin/bash

case "$distro" in
centos-5)
  case "$arch" in
    x86)
      chroot $destdir wget -O /root/epel-release-5-4.noarch.rpm http://mirror.de.leaseweb.net/epel/5/i386/epel-release-5-4.noarch.rpm
      ;;
    x86_64)
      chroot $destdir wget -O /root/epel-release-5-4.noarch.rpm http://mirror.de.leaseweb.net/epel/5/x86_64/epel-release-5-4.noarch.rpm
      ;;
  esac
  chroot $destdir rpm -i /root/epel-release-5-4.noarch.rpm
  ;;
centos-6)
  case "$arch" in
    x86)
      chroot $destdir wget -O /root/epel-release-6-8.noarch.rpm http://mirror.de.leaseweb.net/epel/6/i386/epel-release-6-8.noarch.rpm
      ;;
    x86_64)
      chroot $destdir wget -O /root/epel-release-6-8.noarch.rpm http://mirror.de.leaseweb.net/epel/6/x86_64/epel-release-6-8.noarch.rpm
      ;;
  esac
  rchroot $destdir pm -i /root/epel-release-6-8.noarch.rpm
  ;;
centos-7)
  chroot $destdir wget -O /root/epel-release-7-5.noarch.rpm http://ftp.tu-chemnitz.de/pub/linux/fedora-epel/7/x86_64/e/epel-release-7-5.noarch.rpm
  chroot $destdir rpm -i /root/epel-release-7-5.noarch.rpm
  ;;
esac
