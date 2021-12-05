---
comments: true
date: 2021-12-04
layout: post
tags: [Tech]
title: Finding Ubuntu Packaging for Debian Source Code
---

Ubuntu is built on Debian. Therefore, many Ubuntu packages use Debian source code, such as `ca-certificates`[1] of which the source code is on Debian's repository [2].

But if you want to find the `.deb` packaging of Debian source code for Ubuntu specifically, chances are you won't be able to find it on the Debian's repository. For example, on [1], all the links to the source code point to [2]. In the `changelog` file [3], I could see the log entry:

```
  [ Dimitri John Ledkov ]
  * mozilla/blacklist.txt: blacklist expired "DST Root CA X3".
    (LP: #1944481)
```

But I couldn't find this log entry in [2]. But I wanted to see what exactly were changed in this new version.

It turned out that I needed to look at the Launchpad page for `ca-certificates` [4]. Unfortunately, you can't find a direct link to it on [1]. The only way to quickly jump to [4] is to click the "Bug Reports" link on [1] and then click the title link "ca-certificates package".

There, you can navigate into the source package page for the version `20210119~18.04.2` where you can find more details:
- The link to the bug (["#1944481"](https://launchpad.net/ubuntu/+source/ca-certificates/20210119~18.04.2)) that's fixed by this packaging.
- The difference between this version (`20210119~18.04.2`) and the previous packaging version (`20210119~18.04.1`) where you can see the actual changes:

```diff
diff -Nru ca-certificates-20210119~18.04.1/mozilla/blacklist.txt ca-certificates-20210119~18.04.2/mozilla/blacklist.txt
--- ca-certificates-20210119~18.04.1/mozilla/blacklist.txt	2021-02-01 15:13:34.000000000 +0000
+++ ca-certificates-20210119~18.04.2/mozilla/blacklist.txt	2021-09-22 11:46:54.000000000 +0000
@@ -7,3 +7,4 @@
 "MITM subCA 2 issued by Trustwave"
 "TURKTRUST Mis-issued Intermediate CA 1"
 "TURKTRUST Mis-issued Intermediate CA 2"
+"DST Root CA X3"
```

References:
- [1] [`ca-certificates` on Ubuntu's package server](https://packages.ubuntu.com/source/bionic/ca-certificates)
- [2] [`ca-certificates` on Debian's repository](https://salsa.debian.org/debian/ca-certificates)
- [3] [`ca-certificates` changelog](http://changelogs.ubuntu.com/changelogs/pool/main/c/ca-certificates/ca-certificates_20210119~18.04.2/changelog)
- [4] [`ca-certificates` Launchpad page](https://launchpad.net/ubuntu/+source/ca-certificates)
- [5] [`ca-certificates` 20210119~18.04.2 source package](https://launchpad.net/ubuntu/+source/ca-certificates/20210119~18.04.2)
