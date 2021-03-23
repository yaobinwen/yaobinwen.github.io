---
comments: true
date: 2021-03-23
layout: post
tags: [Tech]
title: "SSH: Too many authentication failures"
---

For a long time, I have never got any problems about ssh-ing into another machine (including my virtual machines); since last night, I suddenly started to get the error "Too many authentication failures".

I didn't understand why this happened suddenly. I thought the SSH configuration on the target machines was wrong, but I didn't find anything suspicious.

I tried to run `ssh` with `-v` to see if I could find anything, then I saw the following log:

```
debug1: Authentications that can continue: publickey,password
debug1: Next authentication method: publickey
debug1: Offering public key: RSA SHA256:LYgSeriHb2g8y/sUN2TMbA2hXKglqe5NV1xv91qf3sY .vagrant/machines/ssh-server/virtualbox/private_key
debug1: Authentications that can continue: publickey,password
debug1: Offering public key: RSA SHA256:y1Qp6oFxtXu6uvOash+UbTrtfvNqSOmR0dR1fBtJnrg ./.vagrant/machines/ca/virtualbox/private_key
debug1: Authentications that can continue: publickey,password
debug1: Offering public key: RSA SHA256:azvtiw0YmRSONSwJnomdOSOEBBWhrJJCYEXND3avQQc /home/ywen/.ssh/id_rsa
debug1: Authentications that can continue: publickey,password
debug1: Offering public key: RSA SHA256:kKyd99Kgd3U0Y5vnvWXuKZasz1lA8L4cVdYPae9yt/8 .vagrant/machines/ca/virtualbox/private_key
debug1: Authentications that can continue: publickey,password
debug1: Offering public key: RSA SHA256:JH9yI7OdamGAVqEE9uIyBbhc+o6Qqglsa0LpD2HgRDk .vagrant/machines/ssh-server/virtualbox/private_key
debug1: Authentications that can continue: publickey,password
debug1: Offering public key: ECDSA SHA256:xR3Ix5daRp4Rq+MRkxvl5wROyGzZvMwNMvBiyn3+ttk id_ecdsa
Received disconnect from 10.0.0.20 port 22:2: Too many authentication failures
Disconnected from 10.0.0.20 port 22
```

I was surprised that I had added so many private keys into the SSH agent. I had the `.vagrant` VM private keys added because I wanted to SSH into the VMs from my physical laptop directly, but I didn't realize that all these private keys were accumulated there and never removed. As a result, ssh was using these private keys for authentication but they all failed. Because the default maximal authentication retry count is 6, and I had 6 authentication failures, ssh on the target machine rejected me with "Too many authentication failures".

The solution was simple: ran `ssh-add -d` to remove the unneeded private keys to make sure the right private key gets a chance before the maximal retry count is reached.
