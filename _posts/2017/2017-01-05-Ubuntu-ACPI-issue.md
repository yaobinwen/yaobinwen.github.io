---
date: 2017-01-05
layout: post
tags: [Tech]
title: Ubuntu 14.04 ACPI Issue
---

> To make ACPI work for Ubuntu, you need to specify "Windows" or disable it.

## The Issue

Today Scott handed over a Panasonic Toughpad FZ-G1 to me and said the screen remained dark and the brightness couldn't be adjusted from the System Settings. Matt encountered the same issue before but couldn't find his note of the resolution right now.

I then called Panasonic technical support and they suggested me to upgrade the driver. I tried to find the appropriate driver from Intel's website but failed. There are many, and I don't know which one I should use. So I decided to Google it becuase that's how Matt solved the issue for the first time.

## The Solution

After some Googling, I found a discussion thread on the Ubuntu forum that is quite similar to my problem: [Panasonic toughbook CF-F9, LCD brightness problem](https://ubuntuforums.org/showthread.php?t=1612560), which links to another thread: [How to set NOMODESET and other kernel boot options in grub2](https://ubuntuforums.org/showthread.php?t=1613132). These two articles work together to solve the problem.

The solution is described as follows:

* Open the **/etc/default/grub** file.

* Find the line `GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"` and change it to `GRUB_CMDLINE_LINUX_DEFAULT="quiet splash acpi_osi="`. Save and exit.

* Run the command `sudo update-grub`.

* Reboot the Toughpad. Now the issue should be resolved.

## More Information

### What Is ACPI

ACPI is short for [Advanced Configuration and Power Interface](http://searchwindowsserver.techtarget.com/definition/ACPI-Advanced-Configuration-and-Power-Interface):

> ACPI (Advanced Configuration and Power Interface) is an industry specification for the efficient handling of power consumption in desktop and mobile computers. ACPI specifies how a computer's basic input/output system, operating system, and peripheral devices communicate with each other about power usage.
>
> ACPI must be supported by the computer motherboard, basic input/output system (BIOS), and the operating system. ... In order for ACPI to work on your computer, your BIOS must include the ACPI software and the operating system must be ACPI-compatible. ACPI is designed to work with Windows 98 and with Windows 2000.

In other words, the issue with my Toughpad was probably caused by the incorrect configuration of Linux ACPI driver.

### What Does 'acpi_osi=' Do

According to this article, [Linux Kernel Boot Parameters](http://redsymbol.net/linux-kernel-boot-parameters/), the kernel parameter `acpi_osi` "Modify list of supported OS interface strings", and `acpi_osi=` disable all the OS interface strings.

P4man in the [discussion thread](https://ubuntuforums.org/showthread.php?t=1612560&p=10070076#post10070076) explained roughly why that empty string works:

> As for what it does; the details are beyond my comprehension, but as I understand it, its a workaround to disable some bios/acpi functionality where the bios queries the OS and sets settings depending on what OS is reported. Unfortunately many bioses dont work properly if they dont get the expected "windows" result and therefore fail to initialize some hardware. As I understand the above setting lets the kernel figure it out, rather than rely on the bios.

But cg909 posted a better explanation in [this answer](http://unix.stackexchange.com/a/268106/162971):

> ACPI consists of so-called tables that the BIOS loads into RAM before the operating system starts. Some of them simply contain information about essential devices on the mainboard in a fixed format, but some like the DSDT table contain AML code. This code is executed by the operating system and provides the OS with a tree structure describing many devices on the mainboard and callable functions that are executed by the OS when e.g. power saving is enabled. The AML code can ask the OS which OS it is by calling the _OSI function. This is often used by vendors to make workarounds e.g. around bugs in some Windows versions.
>
> As many hardware vendors only test their products with the (at that time) latest version of Windows, the "regular" code paths without the workarounds are often buggy. Because of this Linux usually answers yes when asked if it's Windows. Linux also used to answer yes when asked if it's "Linux", but that caused BIOS vendors to work around bugs or missing functionality in the (at that time) latest Linux kernel version instead of opening bug reports or providing patches. When these bugs were fixed the workarounds caused unnecessary performance penalities and other problems for all later Linux versions.
>
> acpi_osi=Linux makes Linux answer yes again when asked if it's "Linux" by the ACPI code, thus allowing the ACPI code to enable workarounds for Linux and/or disable workarounds for Windows.

This is so far the best explanation.

## One More (Unnecessary) Step

So before I finished my work today, I changed the `/etc/default/grub` back to the original state which should reproduce the problem if that's the cause.

But, aha! Congratulations! The brightness issue was not reproduced, which means what I had done so far can't be proven effective...

## And Matt Found His Notes

Matt gave me two articles that help fix the brightness problem:

- [FIX BRIGHTNESS CONTROL NOT WORKING FOR UBUNTU 14.04 & LINUX MINT 17](https://itsfoss.com/fix-brightness-ubuntu-1310/)
- [UBUNTU DOES NOT REMEMBER BRIGHTNESS SETTINGS](https://itsfoss.com/ubuntu-mint-brightness-settings/)

By the way, I checked the Toughpad according to the steps given in the first article, and it uses the Intel graphics card.
