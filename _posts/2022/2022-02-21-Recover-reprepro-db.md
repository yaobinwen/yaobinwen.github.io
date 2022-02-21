---
comments: true
date: 2022-02-21
layout: post
tags: [Tech]
title: "Recover Reprepro Corrupted/Broken `.db` Files"
---

`reprepro(1)` is a tool to manage a repository of Debian packages. For future reference, here is a list of the documents I've collected about this tool:

- [1] [Debian Wiki: Setup With Reprepro](https://wiki.debian.org/DebianRepository/SetupWithReprepro): A good start place.
- [2] [Creating your own Signed APT Repository and Debian Packages](https://scotbofh.wordpress.com/2011/04/26/creating-your-own-signed-apt-repository-and-debian-packages/)
- [3] [`reprepro(1)`: Ubuntu manual page](https://manpages.ubuntu.com/manpages/bionic/man1/reprepro.1.html)
- [4] [`reprepro` manual](https://salsa.debian.org/brlink/reprepro/-/blob/debian/docs/manual.html)
- [5] [`reprepro/docs`](https://salsa.debian.org/brlink/reprepro/-/tree/debian/docs) which has two important documents:
  - [5.1] [FAQ](https://salsa.debian.org/brlink/reprepro/-/blob/debian/docs/FAQ)
  - [5.2] [recovery](https://salsa.debian.org/brlink/reprepro/-/blob/debian/docs/recovery)

This article talks about how to recover the corrupted/broken `.db` files under the `db` folder, using [5.2] as the main reference because it briefly talks about this process but doesn't give a detailed list of steps.

As [4] points out, a Reprepro repository has the following basic sub-directories in its base directory:

- `conf`
- `db` which contains all the `.db` files about the packages.
- `dists`
- `pool`

In my work, I'm maintaining two distributions: `edge` and `stable`. When everything is fine, I could run `reprepro list edge/stable` to list all the packages in the specified distribution. One day, however, when I was publishing updated packages to `edge`, I accidentally corrupted the repository and started to get errors like "some `.deb` files are missing" errors. Having not found a way to fix that (since I had many missing `.deb` files), I moved the repository base directory away by appending `.bak` to its name and let `reprepro` recreate them with the distribution `edge`.

The problem was the newly created repository didn't have the previously existing distribution `stable`. In other words, my partially recovered repository had the following parts:

- `conf/distributions` only had the section for the distribution `edge`.
- `db` had the `.db` files which only had the information about the packages of the versions for `edge`.
- `dists` only had the distribution `edge`.
- `pool` only had the packages of the versions for `edge`.

As a result, when I ran `reprepro list stable`, I got the error of "Cannot find definition of distribution 'stable'!".

So I did the following steps to partially fix it:

- 1). I copied the distribution section `stable` in the backup directory to the newly created `conf/distribution`.
- 2). I copied the `dists/stable` in the backup directory to the newly created `dists`.
- 3). Using `rsync`, I synchronized `pool` in the backup directory to the newly created `pool`.

Now I had the backup repository directory and the newly created repository directory almost synchronized. Running `reprepro list stable` wouldn't report any error but it didn't list any packages of `stable`, either, because the `.db` files in the newly created repository directory still didn't have the information of those packages.

[5.2] teaches a way to recover the directory `db`:

> If you have still an uncorrupted "dists/" directory around, (e.g. you just deleted db/ accidentally), it can be reconstructed by moving your dists/ directory to some other place, moving the packages.db file (if still existent) away, and set every distribution in conf/distributions a "Update: localreadd" with localreadd in conf/updates like:
>
> ```
> Name: localreadd
> Suite: *
> Method: copy:/<otherplace>
> ```
>
> with otherplace being the place you moved the dists/ directory too.

But the description is a bit vague without specific instructions. After some experimenting, I figured the following detailed steps to recover my `db` directory:

- 1). `cd` into the base directory of the repository, e.g., `/srv/www/apt/debian/bionic`. So `pwd` should print `/srv/www/apt/debian/bionic`.
- 2). Move `dists` to some other place by doing the two steps below:
  - 2.1). `mkdir ./tmp` to create `/srv/www/apt/debian/bionic/tmp`. Now `/srv/www/apt/debian/bionic/tmp` is the "otherplace."
  - 2.2). `mv ./dists ./tmp`. This intermediate `tmp` directory is needed because the final `reprepro update` assumes the directory `dists` is under `otherplace`.
- 3). `mv ./db ./db.bak` to back up the original corrupted `db`. Skip this step if `db` is already lost.
- 4). Make sure the GPG key that's specified by the field `SignWith` in `conf/distributions` exists in the current GPG keyring.
- 5). Figure out the `VerifyRelease` GPG key ID by running `gpg --list-secret-keys --with-colons` and find the ID of the key (not the fingerprint). For example, in the following signing sub-key, the key ID is `851F38D2609E665D`. Note: In contrast, the `SignWith` in `conf/distributions` uses the fingerprint of the signing key (which is `A788F5525815CBC6DF91A36E851F38D2609E665D` in the case below).

```
ssb:-:4096:1:851F38D2609E665D:1567703050::::::s:::+:::23:
fpr:::::::::A788F5525815CBC6DF91A36E851F38D2609E665D:
grp:::::::::2D08AB585A479D3A674BD9969EAB96F0A6286564:
```

- 6). Add `Update: localreadd` to all the distribution sections in `conf/distributions`. For example:

```
Origin: Yaobin Wen <robin.wyb@gmail.com>
Codename: edge
Architectures: amd64
Components: comp1 comp2
SignWith: 0xA788F5525815CBC6DF91A36E851F38D2609E665D
Update: localreadd
```

- 7). Create the file `conf/updates` with the following content. Note that the `VerifyRelease` should not have the `0x` prefix. Otherwise, the error "Error: Unexpected character 0x78='x' in VerifyRelease condition '0x851F38D2609E665D'!" would be reported.

```
Name: localreadd
Suite: *
VerifyRelease: 851F38D2609E665D
Method: copy:/srv/www/apt/debian/bionic/tmp
```

- 8). Finally, `cd` into the base directory of the repository (`/srv/www/apt/debian/bionic`) and run `reprepro update` to re-construct the `.db` files. You may be prompted to enter the GPG signing key passphrase.
- 9). Remove the `Update: localreadd` in `conf/distributions` and also remove `conf/updates`.

Now the `db` directory is re-constructed. Running `reprepro list edge/stable` should print the packages of the distributions.
