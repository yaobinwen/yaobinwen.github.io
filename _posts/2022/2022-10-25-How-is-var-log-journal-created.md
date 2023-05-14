---
comments: true
date: 2022-10-25
layout: post
tags: [Tech,Linux]
title: On Ubuntu 18.04, how is `/var/log/journal` created?
---

This is a question I asked on [Ask Ubuntu](https://askubuntu.com/q/1437267/514711).

My work project `fluentd` to manage the log messages and one day I noticed the following error message:

```
Systemd::JournalError: No such file or directory retrying in 1s
```

After some investigation, I found the error was because, for some reason, the folder `/var/log/journal` was not created on our system. So I started to look into what creates `/var/log/journal` in the first place.

By reading [systemd-journald.service(8)](https://manpages.ubuntu.com/manpages/bionic/man8/systemd-journald.service.8.html) and [journald.conf(5)](https://manpages.ubuntu.com/manpages/bionic/man5/journald.conf.5.html), I learned that:

- If `Storage=persistent` in `/etc/systemd/journald.conf`, `/var/log/journal` is created automatically.
- If `Storage=auto` in `/etc/systemd/journald.conf`, `/var/log/journal` is not created automatically if it doesn't exist. But if the system admin creates `/var/log/journal`, `systemd-journald` will write logs into it. Otherwise, it falls back to using `/run/log/journal`.

On my Ubuntu 18.04, my `/etc/systemd/journald.conf` uses all the default values:

```
# Entries in this file show the compile time defaults.
# You can change settings by editing this file.
# Defaults can be restored by simply deleting this file.
#
# See journald.conf(5) for details.

[Journal]
#Storage=auto
#Compress=yes
#Seal=yes
#SplitMode=uid
#SyncIntervalSec=5m
#RateLimitIntervalSec=30s
#RateLimitBurst=1000
#SystemMaxUse=
#SystemKeepFree=
#SystemMaxFileSize=
#SystemMaxFiles=100
#RuntimeMaxUse=
#RuntimeKeepFree=
#RuntimeMaxFileSize=
#RuntimeMaxFiles=100
#MaxRetentionSec=
#MaxFileSec=1month
#ForwardToSyslog=yes
#ForwardToKMsg=no
#ForwardToConsole=no
#ForwardToWall=yes
#TTYPath=/dev/console
#MaxLevelStore=debug
#MaxLevelSyslog=debug
#MaxLevelKMsg=notice
#MaxLevelConsole=info
#MaxLevelWall=emerg
#LineMax=48K
```

In other words, I'm using `Storage=auto` on my system.

I also learned from [systemd-tmpfiles(8)](https://manpages.ubuntu.com/manpages/bionic/man8/systemd-tmpfiles-setup-dev.service.8.html) and [tmpfiles.d(5)](https://manpages.ubuntu.com/manpages/bionic/man5/tmpfiles.d.5.html) that `systemd-tmpfiles` creates, deletes, and cleans up volatile and temporary files and directories, based on the configuration file format and location specified in tmpfiles.d(5).

So I examined the `tmpfiles.d(5)` folders and I only found configuration files under `/usr/lib/tmpfiles.d` that modify the attributes of `/var/log/journal`, as shown in the following `grep` output:

```
/usr/lib/tmpfiles.d$ grep journal *.conf
journal-nocow.conf:# Set the NOCOW attribute for directories of journal files. This flag
journal-nocow.conf:# WARNING: Enabling the NOCOW attribute improves journal performance
journal-nocow.conf:# enabling the NOCOW attribute for journal files is safe, because
journal-nocow.conf:h /var/log/journal - - - - +C
journal-nocow.conf:h /var/log/journal/%m - - - - +C
journal-nocow.conf:h /var/log/journal/remote - - - - +C
systemd.conf:z /run/log/journal 2755 root systemd-journal - -
systemd.conf:Z /run/log/journal/%m ~2750 root systemd-journal - -
systemd.conf:a+ /run/log/journal/%m - - - - d:group:adm:r-x
systemd.conf:a+ /run/log/journal/%m - - - - group:adm:r-x
systemd.conf:a+ /run/log/journal/%m/*.journal* - - - - group:adm:r--
systemd.conf:z /var/log/journal 2755 root systemd-journal - -
systemd.conf:z /var/log/journal/%m 2755 root systemd-journal - -
systemd.conf:z /var/log/journal/%m/system.journal 0640 root systemd-journal - -
systemd.conf:a+ /var/log/journal    - - - - d:group::r-x,d:group:adm:r-x
systemd.conf:a+ /var/log/journal    - - - - group::r-x,group:adm:r-x
systemd.conf:a+ /var/log/journal/%m - - - - d:group:adm:r-x
systemd.conf:a+ /var/log/journal/%m - - - - group:adm:r-x
systemd.conf:a+ /var/log/journal/%m/system.journal - - - - group:adm:r--
```

**But by reading the meanings of `h`, `z`, `Z`, and `a+`, none of them seem to create the folder `/var/log/journal`. All of them seem to only modify the attributes of `/var/log/journal`.**

I did a test in which I deleted the folder `/var/log/journal` and rebooted my computer. Then I saw `/var/log/journal` was not re-created (which was expected because of `Storage=auto` on my machine). Instead, `/run/log/journal` was created (as expected).

I was blocked here for a while, until it occurred to me that the folder may be created by the `postinst` script of some package, possibly `systemd`. [The user Andrew Lowther's answer](https://askubuntu.com/a/1437564/514711) confirmed it that `systemd` creates the folder `/var/log/journal` in [its `postinst` script](https://git.launchpad.net/~ubuntu-core-dev/ubuntu/+source/systemd/tree/debian/systemd.postinst):

```shell
# Enable persistent journal, in auto-mode, by default on new installs installs and upgrades
if dpkg --compare-versions "$2" lt "235-3ubuntu3~"; then
    mkdir -p /var/log/journal
    # create tmpfiles only when running systemd, otherwise %b substitution fails
    if [ -d /run/systemd/system ]; then
        systemd-tmpfiles --create --prefix /var/log/journal
    fi
fi
```

Andrew also posted why `systemd` created `/var/log/journal` in the first place. It was because of the Debian bug [Please enable persistent journal](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=717388):

> By default, journald logs to the non-persistent /run/log/journal.
journald will only maintain a persistent journal if /var/log/journal
exists.
>
> Please create /var/log/journal, to enable persistent journal logging.

I then verified Andrew's answer and it was correct, so instead of writing my own answer, I accepted his better answer.
