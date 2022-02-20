---
comments: true
date: 2022-02-20
layout: post
tags: [Tech]
title: "Forwarding `gpg-agent` to a Remote System over SSH"
---

This article is a summary of [_Forwarding gpg-agent to a remote system over SSH_](https://wiki.gnupg.org/AgentForwarding). I re-organized the information to make it easier to follow. I'm not contributing new content so credits mostly go to that Wiki article.

## Overview

Two hosts are involved:

- 1). The **local host** that has the GPG private key.
- 2). The **remote host** where the GPG key needs to be used.

Two pieces of software are involved:

- 1). **`GnuPG` 2.1** is needed on both the local and the remote hosts.
- 2). **`OpenSSH` >= 6.7** is needed on both the local and the remote hosts.

## Remote Host

On the remote host:

- 1). Import the GPG public key.
- 2). Run `gpgconf --list-dir agent-socket` to find the path to the standard GPG agent socket. Let's call it `<remote-agent-socket>`. For example, the value may be `/run/user/1000/gnupg/S.gpg-agent`.
- 3). Modify `/etc/ssh/sshd_config` to add the line `StreamLocalBindUnlink yes` to enable automatic removal of stale sockets when connecting to the remote machine. Then run `sudo systemctl restart ssh.service`.

## Local Host

On the local host:

- 1). Run `gpgconf --list-dir agent-extra-socket` to find the path to the extra GPG agent socket. Let's call it `<local-agent-extra-socket>`. For example, the value may be `/run/user/1000/gnupg/S.gpg-agent.extra`.
- 2). In `~/.ssh/config`, add the following section:

```
Host <remote-host-short-name>
    HostName <remote-host-IP>
    RemoteForward <remote-agent-socket> <local-agent-extra-socket>
```

## Use Scenario

When the configuration above on the local and the remote hosts are finished, run `ssh -l <ssh-login-user> <remote-host-short-name>` to log into the remote host, then run `gpg`. If passphrase is needed, the passphrase prompt will be prompted on the local host.

FYI: The passphrase prompt program is one of `pinentry-*`, such as `pinentry-curses` and `pinentry-gnome3`. `gpg(1)` has the CLI option `--pinentry-mode` to control passphrase entry behavior.

## Notes

> On Systems where `systemd` controls the directories under `/var/run/user/<uid>` it may be that the socket forwarding fails because `/var/run/user/<uid>/gnupg` is deleted on logout. To workaround this you can put `gpgconf --create-socketdir` in the startup script of your shell e.g. `~/.bashrc` or `~/.zshrc`.
>
> Remote `gpg` will try to start `gpg-agent` if it's not running. Remote `gpg-agent` which will delete your forwarded socket and set up it's own. To avoid this you can pass `--no-autostart` to remote `gpg` command.
