---
comments: true
date: 2022-04-07
layout: post
tags: [Tech,Linux,Debian]
title: What is the detailed process of resolving `${shlibs:Depends}` when creating a Debian package?
---

In 2018-10-22, I asked [this question](https://askubuntu.com/q/1086226/514711) on Ask Ubuntu.

At that time, my work involves a lot of Debian packaging, and I was using the [Debian New Maintainers' Guide](https://www.debian.org/doc/manuals/maint-guide/) as my main reference.

What I didn't fully understood was how the `${shlibs:Depends}` was resolved into specific packages and versions. By "how" I meant **the detailed steps** from the variable `${shlibs:Depends}` to the final list of packages in the `Depends` field.

[Chapter 4](https://www.debian.org/doc/manuals/maint-guide/dreq.en.html#control) of _Debian New Maintainers' Guide_ says:

> dh_shlibdeps(1) calculates shared library dependencies for binary packages. It generates a list of ELF executables and shared libraries it has found for each binary package. This list is used for substituting ${shlibs:Depends}.

I was really interested in the detailed steps of "generates a list of ELF executables and shared libraries it has found for each binary package", such as what were the information sources used.

I also looked at the section ["8.6.4. The shlibs system"](https://www.debian.org/doc/debian-policy/ch-sharedlibs.html#s-sharedlibs-shlibdeps) in the _Debian Policy Manual_. It does give some information sources but still doesn't seem to talk about the detailed steps either.

The user `user.dz` posted what he/she had learned and I appreciated the help (by accepting the answer).

But today I realized that it looks like `${shlibs:Depends}` is resolved by `dpkg-shlibdeps` (or `dh_shlibdeps`) using the file `debian/shlibs.local`. The section ["8.6.4.1. The shlibs files present on the system"](https://www.debian.org/doc/debian-policy/ch-sharedlibs.html#the-shlibs-files-present-on-the-system) of the _Debian Policy Manual_ says:

> This lists overrides for this package. This file should normally not be used, but may be needed temporarily in unusual situations to work around bugs in other packages, or in unusual cases where the normally declared dependency information in the installed shlibs file for a library cannot be used. This file overrides information obtained from any other source.

`shlibs` file format is defined by [`deb-shlibs(5)`](https://man7.org/linux/man-pages/man5/deb-shlibs.5.html). In other words, if a Debian package doesn't have the file `debian/shlibs.local`, the variable `${shlibs:Depends}` may be resolved to an empty list.

I haven't got a chance to verify if this is correct, so I only posted my findings as [a comment](https://askubuntu.com/questions/1086226/what-is-the-detailed-process-of-resolving-shlibsdepends-when-creating-a-de#comment2431808_1086226) below my original question. But I think this is a good clue if one day I need to dig in deeper.
