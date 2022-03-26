---
comments: true
date: 2022-03-24
layout: post
tags: [Tech]
title: "Why does the Ubuntu installer asks me to re-mount the partitions even though I had done that in earlier installation?"
---

I don't remember the last time I installed multiple OSes on my computer. It must have been quite long time ago. So the other day when I was working with my colleague to install multiple Ubuntu OSes on his work laptop, we were both confused because, although my colleague had installed Ubuntu on the laptop earlier so all the partitions (totally three) had been set up with a mount point for each, we were still asked to re-configure the mount points during the installation. After doing some research, I understand the reason and here is my explanation I sent to my colleague:

- 1). Here we must learn to think from the perspective of an "OS installation" (and I focus on the resources of the hard drives, or the partitions on a single hard drive):
  - a). I'll use the term "storage resource" to refer to one partition on one hard drive because, firstly, we do use it for storing information and, secondly, this term can give us a good level of abstraction so we can unify the thinking about "partitions on a hard drive" and "multiple hard drives". Each storage resource needs a file system (e.g., `NTFS`, `ext4`, `fat32`) so the OS knows how to find the files on that storage resource.
  - b). When we install the OS, the OS installer assumes that we the users are trying to **replan our use of all the available storage resources**. In your case, there are three major storage resources: `sda1`, `sda2`, and `sda3`. I'm not mentioning the free spaces because they are not the focus here.
  - c). I need to explain what I meant by **"plan"** when I said "replan": Simply put, "planning" the use of a storage resource includes:
    - i). In the finally installed OS, **do I want to use one storage resource at all?** The OS installer gives us the chance to say "No, I don't want to use this storage at all so please don't mount it anywhere."
    - ii). In the finally installed OS, **which path do I want to mount this storage resource?** `/`? `/tmp`? Or somewhere else?
    - iii). **Do I want to use the existing file systems (if available) on the storage resources? Or do I want to re-format them to some other file systems?**
  - d). Because the OS installer allows us to replan the storage resources, it asks us to specify the usage plan from scratch. This is why even if you had previously installed Ubuntu 18.04 on your machine and you could boot it up, which means some of the hard drive partition must have been assigned with the root path (i.e., `/`), when you are installing the OS again, the partition listing still shows you **no mount points** (see screenshot 1 below): because the OS installer is waiting for your **new plan**: "Hey user, here is the list of all available storage resources, where do you want to mount them?" And point (c-iii) also explains why you can view the current file systems of each storage resource: the OS installer presents them so you can decide if you want to reuse them or format it to another one.
  - e). Look at the screenshot which shows this "replanning" process: for one storage resource, you can use the "Change..." button to do the replanning as I said in (c) above. Notice the end of the drop down list is "do not use the partition" which aligns with (c-i).
  - f). With that said, when you choose "do not use the partition", you are telling the OS installer to leave this partition alone and does not touch it at all in this OS that's being installed. We are going to use this in the section below.
- 2). Back to the first part of your second question: "Is the `/` just important ...?" I didn't find the related reference/document to really say this but according to the use experience, yes, `/` is important for Ubuntu (or generally, Linux) because that's the starting point of the entire file system hierarchy. In other words, we have seen every Linux OS has the `/`, but we haven't seen one Linux OS without `/`.
- 3). Regarding "... because it reformats that portion of the storage...": As I said above, reformatting is not necessary as long as you want to re-use the existing file system format on that storage. The screenshot shows you can check/uncheck the "Format?" option. But if you choose a different file system without formatting it, the OS installer will warn you that "the existing file system may prevent the correct use of the storage".
- 4). Back to our goal of installing two Ubuntu 18.04 side by side, here is my suggestion:
  - a). Our plan:
    - i). `sda2`, 1.5TB, username `chris` => Use as dev machine, kind of permanently installed and don't plan to reinstall often.
    - ii). `sda3`, username `test` => Use as tablet testing machine and want to re-install frequently.
  - b). When you install the dev machine (`sda2`), when presented with the partition listing after we choose "Something else":
    - i). Mount `sda2` to `/` and keep using `ext4`. You don't have to choose "Format?" because you don't plan to change the file system, but the OS installer may warn you about "the existing file system may prevent..." (or not, I don't remember exactly). But that's fine because we know the existing file system works for us.
    - ii). Leave `sda3` alone: do not give it a mount point; ensure "do not use this partition".
  - c). When you install the tablet machine (`sda3`):
    - i). Mount `sda3` to `/` and keep using `ext4`. Don't have to choose "Format?" but suggest to do so because you want to wipe it out anyway.
    - ii). Leave `sda2` alone: no mount point; ensure "do not use this partition".
  - d). It looks like the "last OS installation" is always considered the "primary, default" boot option, so the OS for `sda3` will become the top "Ubuntu" option and OS for `sda2` will be listed below as the alternative option.

Screenshot 1 (not screenshots of my colleague's laptop but a virtual machine I used for testing):

<img src="https://raw.githubusercontent.com/yaobinwen/yaobinwen.github.io/master/images/2022/03-26/os-installation-replanning.png" alt="No mount points during OS installation" width="50%" height="50%" />
