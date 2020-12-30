---
comments: true
date: 2018-07-31
layout: post
tags: [Tech]
title: How to Debug Debian Package
---

> Use the "Maintainer script flowcharts" to debug the installation scripts.

## Debug Debian Package Installation

Today I was trying to use the [`oracle-java8-installer` Debian package](https://launchpad.net/~webupd8team/+archive/ubuntu/java) to install Java 8 to my Ubuntu 14.04.

Weirdly, the installation succeeded on some machines but failed on some others. The failure was caused by the unauthorized accesss to the target package. The `oracle-java8-installer` package uses `wget` to download the Java 8 installation file from Oracle's official website. Oracle requires the user to agree the license before downloading, which is handled by the `oracle-java8-installer`. If the user agrees with the license, the installer downloads with the header `Cookie: oraclelicense=a` to indicate the license acceptance by the user. Then an `AuthParam` is appended to the URL:

> http://download.oracle.com/otn-pub/java/jdk/8u181-b13/96a7b8442fe848ef90c96a2fad6ed6d1/jdk-8u181-linux-x64.tar.gz?AuthParam=1533080203_1cd7184c1597c2025098221ab6c8d57a

On those computers that failed, the `AuthParam` was missing, hence the `unauthorized access` error. Because the Java 8 installation file was not downloaded successfully, the installation would surely not succeed, either.

To debug this issue, I did the following things:

- Find the cached `oracle-java8-installer` package in `/var/cache/apt/archives` and copy it somewhere else for use.
- Uncompress the copy of the `oracle-java8-installer` package.
- Inside the extracted folder, you can find the `DEBIAN` sub-folder which has all the installation scripts: `preinst`, `postinst`, `prerm`, `postrm`, etc..
- Use `sudo apt-get remove --purge oracle-java8-installer` to completely remove the package from the system so the later calls of the installation scripts would have a clean system environment.
- Edit the installation scripts to add necessary debug messages.
- Use the [`Maintainer script flowcharts`](https://www.debian.org/doc/debian-policy/ap-flowcharts.html) to go through the installation process and see what may go wrong.

## More About `oracle-java8-installer`

The installer source code can be found [here](https://github.com/hotice/oracle-java8-installer).

The direct cause of the installation (or downloading) failure was that, on the failed computers, the APT configuration has [an `http_proxy` set](https://github.com/hotice/oracle-java8-installer/blob/master/oracle-java8-installer.postinst#L120) and the download from Oracle's website was not set as ["DIRECT"](https://github.com/hotice/oracle-java8-installer/blob/master/oracle-java8-installer.postinst#L123). Once I set it as "DIRECT" download, the Java 8 installation file could be downloaded successfully.

The root cause seems to be the presence of `http_proxy`, which is usually the `apt-cache-ng` proxy, caused the `AuthParam` missing from the URL that `wget` uses. But I haven't figured out why that happened.
