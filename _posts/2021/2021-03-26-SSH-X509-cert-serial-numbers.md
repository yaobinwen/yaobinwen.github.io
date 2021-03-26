---
comments: true
date: 2021-03-26
layout: post
tags: [Tech]
title: "SSH: Uniqueness of X509 Certificates Serial Numbers"
---

## Overview

I asked the question ["ssh-keygen: How to guarantee the uniqueness of serial numbers?"](https://security.stackexchange.com/q/246389/80050). This question has two parts:

- 1). Whether or not the serial numbers must be unique.
- 2). How to guarantee the uniqueness of the serial numbers if uniqueness is needed.

Note that the "SSH" in this article refers to the OpenSSH implementation.

## TL;DR

If the serial numbers are used to sign certificates:
- They must be unique across all the certificates that are signed by the same CA.
- The certificates that are signed by different CAs can use the same serial numbers.

If the serial numbers are not used to sign certificates, SSH would use `0` for all the certificates. `0` is not a valid serial number [1] so it makes no sense to talk about uniqueness in this case.
- `-I`, or key ID (or certificate ID), must always be specified, so revoked certificates can be identified by the key IDs.

`ssh-keygen(1)` manual doesn't mention anything about how the serial numbers are guaranteed. I think it's up to the users to implement the solution. Simpliest, it can be a spreadsheet if the user only needs to manage a few certificates. A large organization may want to automate their own certificate signing process and use software to guarantee the uniqueness.

## Test: Using Serial Numbers

### The Test

To figure out the answer to the "whether" question, I set up the following environment:

- I used three VMs for different purposes:
  - CAs
  - SSH client
  - SSH server
- I set up two CAs:
  - CA1 (`ca1.pub`, `SHA256:QCq66/ROQTS8wF74vL3DNlB1SWW6DT6iLpzyhQf3q/8`)
  - CA2 (`ca2.pub`, `SHA256:GsE4qEa+pLpQW/urLZW0YrB1aymgdLKh8OhLzonHrco`)
  - The public keys of the two CAs are merged into a single public key file: `ca_all.pub`.
- SSH server is configured this way:
  - `TrustedUserCAKeys /etc/ssh/ca_all.pub`
  - `AuthorizedPrincipalsFile /etc/ssh/auth_principals/%u`
  - `RevokedKeys /etc/ssh/revoked_keys`

I then set up three users and signed their certificates using serial numbers as follows:

| Name | Signed by | Serial No. | Certificate Fingerprint [2] |
|:----:|:---------:|:----------:|:---------------------------:|
| alice | CA 1 | 10 [3] | `SHA256:j5IPf7RtoRzLbuPcFi35knX/4/ZIBL4m5tjclSEOQek` |
| bob | CA 2 | 10 | `SHA256:+xTits76Rq9cwg5at0cHuQfPkbgvPyIP+252hyKcMCY` |
| cassey | CA 1 | 10 | `SHA256:iyIeiiKZmcRUenQXjKi9M9Vw32fAZGyh6wztv8/TCBQ` |

When `cassey`'s certificate is revoked by `ssh-keygen -k -f ./revoked_keys -s ./ca1.pub ./cassey/id_ecdsa-cert.pub`, he won't be able to access the SSH server (`/var/log/auth.log`):

```
error: Authentication key ECDSA-CERT SHA256:iyIeiiKZmcRUenQXjKi9M9Vw32fAZGyh6wztv8/TCBQ revoked by file /etc/ssh/revoked_keys
```

However, `alice` won't be able to access the server, either:

```
error: Authentication key ECDSA-CERT SHA256:j5IPf7RtoRzLbuPcFi35knX/4/ZIBL4m5tjclSEOQek revoked by file /etc/ssh/revoked_keys
```

The revocation doesn't affect `bob` because he still has the access:

```
Accepted publickey for root from 192.168.58.4 port 35626 ssh2: ECDSA-CERT ID bob (serial 0) CA RSA SHA256:GsE4qEa+pLpQW/urLZW0YrB1aymgdLKh8OhLzonHrco
```

### Conclusions

If serial numbers are used to identify certificates:
- The certificates that are signed by the same CA must have unique serial numbers. Otherwise, revoking one would cause the others that have the same serial numbers to be revoked, too.
- The certificates that are signed by different CAs can use the same serial number without affecting each other.

### More Thoughts

If you look at the revocation command `ssh-keygen -k` used above, you'll see it has two inputs:
- `-s ./ca1.pub`
- `./cassey/id_ecdsa-cert.pub`

Cassey's certificate has the following information (shown by `ssh-keygen -L`):

```
./cassey/id_ecdsa-cert.pub:
        Type: ecdsa-sha2-nistp256-cert-v01@openssh.com user certificate
        Public key: ECDSA-CERT SHA256:iyIeiiKZmcRUenQXjKi9M9Vw32fAZGyh6wztv8/TCBQ
        Signing CA: RSA SHA256:QCq66/ROQTS8wF74vL3DNlB1SWW6DT6iLpzyhQf3q/8
        Key ID: "cassey"
        Serial: 10
        Valid: from 2021-03-26T01:08:00 to 2021-04-02T01:09:48
        Principals:
                root-everywhere
        Critical Options: (none)
        Extensions:
                permit-X11-forwarding
                permit-agent-forwarding
                permit-port-forwarding
                permit-pty
                permit-user-rc
```

It has `Key ID` and `Serial`. But when being revoked, `Key ID` doesn't seem to be used when `Serial` is present and valid. `Serial` seems to be the only field that is recorded in the revocation list. As a result, the other certificate `alice` is affected, too.

## Test: Without Using Serial Numbers

### The Test

I still used the previous setup, but this time I signed the certificates without `-z`. As a result, the serial numbers of the certificates are all `0`:

| Name | Signed by | Serial No. | Certificate Fingerprint |
|:----:|:---------:|:----------:|:---------------------------:|
| alice | CA 1 | 0 | `SHA256:j5IPf7RtoRzLbuPcFi35knX/4/ZIBL4m5tjclSEOQek` |
| bob | CA 2 | 0 | `SHA256:+xTits76Rq9cwg5at0cHuQfPkbgvPyIP+252hyKcMCY` |
| cassey | CA 1 | 0 | `SHA256:iyIeiiKZmcRUenQXjKi9M9Vw32fAZGyh6wztv8/TCBQ` |

Initially, they all could access the SSH server:

```
Accepted publickey for root from 192.168.58.4 port 35628 ssh2: ECDSA-CERT ID alice (serial 0) CA RSA SHA256:QCq66/ROQTS8wF74vL3DNlB1SWW6DT6iLpzyhQf3q/8
Accepted publickey for root from 192.168.58.4 port 35630 ssh2: ECDSA-CERT ID bob (serial 0) CA RSA SHA256:GsE4qEa+pLpQW/urLZW0YrB1aymgdLKh8OhLzonHrco
Accepted publickey for root from 192.168.58.4 port 35632 ssh2: ECDSA-CERT ID cassey (serial 0) CA RSA SHA256:QCq66/ROQTS8wF74vL3DNlB1SWW6DT6iLpzyhQf3q/8
```

Note that the log messages showed that their serial numbers are all `0`.

Then I revoked `cassey`: `ssh-keygen -k -f ./revoked_keys -s ./ca1.pub ./cassey/id_ecdsa-cert.pub`, and `cassey` couldn't access the server:

```
error: Authentication key ECDSA-CERT SHA256:iyIeiiKZmcRUenQXjKi9M9Vw32fAZGyh6wztv8/TCBQ revoked by file /etc/ssh/revoked_keys
```

But `alice`'s access was not affected:

```
Accepted publickey for root from 192.168.58.4 port 35636 ssh2: ECDSA-CERT ID alice (serial 0) CA RSA SHA256:QCq66/ROQTS8wF74vL3DNlB1SWW6DT6iLpzyhQf3q/8
```

Not to mention `bob`:

```
Accepted publickey for root from 192.168.58.4 port 35638 ssh2: ECDSA-CERT ID bob (serial 0) CA RSA SHA256:GsE4qEa+pLpQW/urLZW0YrB1aymgdLKh8OhLzonHrco
```

### Conclusions

When the serial numbers are not used for certificates, the key IDs (`-I`) are used to identify which certificate is revoked.

## Notes

[1]: [`ssh-keygen(1)`](http://manpages.ubuntu.com/manpages/bionic/man1/ssh-keygen.1.html) says:

> Serial numbers are 64-bit values, not including zero and may be expressed in decimal, hex or octal.

[2]: `ssh-keygen -l -f ./user/id_ecdsa-cert.pub`

[3]: `10` is just an arbitrary number I picked. It doesn't have any special meaning.
