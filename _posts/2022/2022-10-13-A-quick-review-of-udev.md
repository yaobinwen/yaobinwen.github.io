---
comments: true
date: 2022-10-13
layout: post
tags: [Tech,Linux]
title: A quick review of Linux udev
---

The purpose of this article is to help refresh my memory of how to write Linux `udev` rules without having to re-read the manual pages and other articles. This article assumes the use of Ubuntu Linux.

## 1. Overview

What is `udev`? [4] says `udev` stand for "userspace /dev". [1] says:

> `udev` supplies the system software with device events, manages permissions of device nodes and may create additional symlinks in the `/dev` directory, or renames network interfaces.

`udev` primarily (but not only) manages device nodes in the directory `/dev` by using the device information in `/sys`. As [3] says:

> `sysfs` is a new filesystem to the 2.6 kernels. It is managed by the kernel, and exports basic information about the devices currently plugged into your system. `udev` can use this information to create device nodes corresponding to your hardware.

Here are some of the things you can use rules to achieve:
- Rename a device node from the default name to something else
- Provide an alternative/persistent name for a device node by creating a symbolic link to the default device node
- Name a device node based on the output of a program
- Change permissions and ownership of a device node
- Launch a script when a device node is created or deleted (typically when a device is attached or unplugged)
- Rename network interfaces

On Ubuntu: `udev` is installed by the [Debian package `udev`](https://packages.ubuntu.com/bionic/udev) from which one could see `udev` is now (as of 2022-10-13) part of `systemd`.

`udev` installs the following noticeable files:
- `/bin/systemd-hwdb`
- `/bin/udevadm`
- `/lib/systemd/system/systemd-udevd.service` (and a few other `.service` files).
- `/lib/udev/rules.d/*.rules`: Many `.rules` files.

## 2. Device hierarchy

Devices are usually managed in a hierarchical structure. For example, the following `udevadm info --attribute-walk <devpath>` lists the device hierarchy of my USB keyboard:

```
$ udevadm info --attribute-walk "/sys/devices/pci0000:00/0000:00:14.0/usb1/1-1/1-1.3"

Udevadm info starts with the device specified by the devpath and then
walks up the chain of parent devices. It prints for every device
found, all possible attributes in the udev rules key format.
A rule to match, can be composed by the attributes of the device
and the attributes from one single parent device.

  looking at device '/devices/pci0000:00/0000:00:14.0/usb1/1-1/1-1.3':
    KERNEL=="1-1.3"
    SUBSYSTEM=="usb"
    DRIVER=="usb"
    ...
    ATTR{manufacturer}=="Logitech"
    ATTR{product}=="USB Keyboard"
    ...

  looking at parent device '/devices/pci0000:00/0000:00:14.0/usb1/1-1':
    KERNELS=="1-1"
    SUBSYSTEMS=="usb"
    DRIVERS=="usb"
    ...
    ATTRS{product}=="USB2.0 HUB"
    ...

  looking at parent device '/devices/pci0000:00/0000:00:14.0/usb1':
    KERNELS=="usb1"
    SUBSYSTEMS=="usb"
    DRIVERS=="usb"
    ...
    ATTRS{product}=="xHCI Host Controller"
    ...

  looking at parent device '/devices/pci0000:00/0000:00:14.0':
    KERNELS=="0000:00:14.0"
    SUBSYSTEMS=="pci"
    DRIVERS=="xhci_hcd"
    ...

  looking at parent device '/devices/pci0000:00':
    KERNELS=="pci0000:00"
    SUBSYSTEMS==""
    DRIVERS==""
```

The top section `looking at device` describes the device (i.e., my USB keyboard) itself; the following `looking at parent device` sections describe the parent devices. It's important to realize this hierarchical structure because `udev` rules can use the information of both the device itself and the parent devices to match a particular device.

## 3. Writing rules

Here is a quick recap of writing rules:
- The rules should be written in files of extension `.rules`.
- Put the `.rules` files under `/etc/udev/rules.d`.
- Rules **cannot** span multiple lines. `udev` does **not** support any form of line continuation.
- `#` starts a comment line.
- One device can be matched by more than one rule, so we can use different rules to handle the different aspects of the device, making each rule have a clearly defined responsibility.
- `udev` will **not** stop processing when it finds a matching rule, it will continue searching and attempt to apply every rule that it knows about.
- Rule syntax is as follows:

```
<matching key 1>==<value 1>, <matching key 2>==<value 2>, ... <matching key N>==<value N>, <assignment key A>=<value A>, <assignment key B>=<value B>, ...
```

- Keys of singular form (e.g., `KERNEL`, `SUBSYSTEM`) match the attributes of the device itself; keys of plural forms (e.g., `KERNELS`, `SUBSYSTEMS`) match the attributes of the device itself or any of the parent devices.
- Make use of the `printf`-like string substitution operators (e.g., `%k`, `%n`) to make the names dynamic and variable. See [1] and [3] for more details.
- Make use of the matching patterns (e.g., `*`, `?`, `[]`) to match a group of devices. See [1] and [3] for more details.
- Remember the single-parent-device rule, as [3] puts it (also see [6] for an example):

> ... while it is legal to combine the attributes from the device in question and a **single parent device**, you **cannot mix-and-match attributes from multiple parent devices** - your rule will not work.

- If you really need to use attributes from multiple parent devices, you can use `TAG` to achieve this (and see the example below):
  - Use attributes from a parent device to narrow down the scope of the devices and then tag all of them with a certain tag (i.e., `TAG=tag1`).
  - Then within the tagged devices (i.e., `TAG==tag`), use attributes from another parent device to further narrow down the devices.

```
ACTION!="add" GOTO="rules_end"

SUBSYSTEM=="net", SUBSYSTEMS=="usb", ATTRS{idProduct}=="1234", ATTRS{idVendor}=="5678", TAG+="mydevices"

TAG=="mydevices", DRIVERS=="cdc_ncm", ATTRS{bInterfaceNumber}=="05", NAME="dev0"
TAG=="mydevices", DRIVERS=="rndis_host", ATTRS{bInterfaceNumber}=="00", NAME="dev1"

LABEL="rules_end"
```

## 4. General steps of writing rules

### 4.1 Figure out what properties/attributes can be used to match the device

Although `udevadm info` can show a lot of device attributes, **it looks like not all of them can be used to match a device.** I haven't figured out why yet, probably because not all of the attributes are available when the `udev` events are emit.

The more reliable way is to run `udevadm monitor` to print the `udev` events and properties, and then **try** to only use the properties listed there to write the `udev` rules because, compared to the attributes that `udevadm info` prints out, `udevadm monitor` prints a smaller number of attributes, so it may (or may not) be easier to start trying things in a smaller scope. I said "try" because some of the attributes that are not listed in `udevadm monitor` but listed in `udevadm info` can still be used. **The rule of thumb seems to be "just try and see which one works".**

Take my USB keyboard for example:

```
udevadm monitor --property --udev --subsystem-match="usb"

(events for removal are ignored)

UDEV  [7068.167449] add      /devices/pci0000:00/0000:00:14.0/usb1/1-1/1-1.3 (usb)
ACTION=add
BUSNUM=001
DEVNAME=/dev/bus/usb/001/012
DEVNUM=012
DEVPATH=/devices/pci0000:00/0000:00:14.0/usb1/1-1/1-1.3
DEVTYPE=usb_device
DRIVER=usb
ID_BUS=usb
ID_MODEL=USB_Keyboard
ID_MODEL_ENC=USB\x20Keyboard
ID_MODEL_FROM_DATABASE=Keyboard K120
ID_MODEL_ID=c31c
ID_REVISION=6402
ID_SERIAL=Logitech_USB_Keyboard
ID_USB_INTERFACES=:030101:030000:
ID_VENDOR=Logitech
ID_VENDOR_ENC=Logitech
ID_VENDOR_FROM_DATABASE=Logitech, Inc.
ID_VENDOR_ID=046d
MAJOR=189
MINOR=11
PRODUCT=46d/c31c/6402
SEQNUM=80889
SUBSYSTEM=usb
TYPE=0/0/0
UPOWER_VENDOR=Logitech, Inc.
USEC_INITIALIZED=7068158666

UDEV  [7068.169948] add      /devices/pci0000:00/0000:00:14.0/usb1/1-1/1-1.3/1-1.3:1.0 (usb)
ACTION=add
DEVPATH=/devices/pci0000:00/0000:00:14.0/usb1/1-1/1-1.3/1-1.3:1.0
DEVTYPE=usb_interface
DRIVER=usbhid
ID_MODEL_FROM_DATABASE=Keyboard K120
ID_VENDOR_FROM_DATABASE=Logitech, Inc.
INTERFACE=3/1/1
MODALIAS=usb:v046DpC31Cd6402dc00dsc00dp00ic03isc01ip01in00
PRODUCT=46d/c31c/6402
SEQNUM=80890
SUBSYSTEM=usb
TYPE=0/0/0
USEC_INITIALIZED=7068169714

UDEV  [7068.170813] add      /devices/pci0000:00/0000:00:14.0/usb1/1-1/1-1.3/1-1.3:1.1 (usb)
ACTION=add
DEVPATH=/devices/pci0000:00/0000:00:14.0/usb1/1-1/1-1.3/1-1.3:1.1
DEVTYPE=usb_interface
DRIVER=usbhid
ID_MODEL_FROM_DATABASE=Keyboard K120
ID_VENDOR_FROM_DATABASE=Logitech, Inc.
INTERFACE=3/0/0
MODALIAS=usb:v046DpC31Cd6402dc00dsc00dp00ic03isc00ip00in01
PRODUCT=46d/c31c/6402
SEQNUM=80907
SUBSYSTEM=usb
TYPE=0/0/0
USEC_INITIALIZED=7068170525

UDEV  [7068.212167] bind     /devices/pci0000:00/0000:00:14.0/usb1/1-1/1-1.3/1-1.3:1.0 (usb)
ACTION=bind
DEVPATH=/devices/pci0000:00/0000:00:14.0/usb1/1-1/1-1.3/1-1.3:1.0
DEVTYPE=usb_interface
DRIVER=usbhid
ID_MODEL_FROM_DATABASE=Keyboard K120
ID_VENDOR_FROM_DATABASE=Logitech, Inc.
INTERFACE=3/1/1
MODALIAS=usb:v046DpC31Cd6402dc00dsc00dp00ic03isc01ip01in00
PRODUCT=46d/c31c/6402
SEQNUM=80906
SUBSYSTEM=usb
TYPE=0/0/0
USEC_INITIALIZED=7068169714

UDEV  [7068.215560] bind     /devices/pci0000:00/0000:00:14.0/usb1/1-1/1-1.3/1-1.3:1.1 (usb)
ACTION=bind
DEVPATH=/devices/pci0000:00/0000:00:14.0/usb1/1-1/1-1.3/1-1.3:1.1
DEVTYPE=usb_interface
DRIVER=usbhid
ID_MODEL_FROM_DATABASE=Keyboard K120
ID_VENDOR_FROM_DATABASE=Logitech, Inc.
INTERFACE=3/0/0
MODALIAS=usb:v046DpC31Cd6402dc00dsc00dp00ic03isc00ip00in01
PRODUCT=46d/c31c/6402
SEQNUM=80917
SUBSYSTEM=usb
TYPE=0/0/0
USEC_INITIALIZED=7068170525

UDEV  [7068.217541] bind     /devices/pci0000:00/0000:00:14.0/usb1/1-1/1-1.3 (usb)
ACTION=bind
BUSNUM=001
DEVNAME=/dev/bus/usb/001/012
DEVNUM=012
DEVPATH=/devices/pci0000:00/0000:00:14.0/usb1/1-1/1-1.3
DEVTYPE=usb_device
DRIVER=usb
ID_BUS=usb
ID_MODEL=USB_Keyboard
ID_MODEL_ENC=USB\x20Keyboard
ID_MODEL_FROM_DATABASE=Keyboard K120
ID_MODEL_ID=c31c
ID_REVISION=6402
ID_SERIAL=Logitech_USB_Keyboard
ID_USB_INTERFACES=:030101:030000:
ID_VENDOR=Logitech
ID_VENDOR_ENC=Logitech
ID_VENDOR_FROM_DATABASE=Logitech, Inc.
ID_VENDOR_ID=046d
MAJOR=189
MINOR=11
PRODUCT=46d/c31c/6402
SEQNUM=80918
SUBSYSTEM=usb
TYPE=0/0/0
UPOWER_VENDOR=Logitech, Inc.
USEC_INITIALIZED=7068158666
```

You can use the attributes such as `ID_VENDOR_ID` and `SUBSYSTEM` to try to match the device, but also check out the output of `udevadm info` to test if an attribute can be used to match the device. You will probably need a lot of testing.

Here is a counter-example of only using `udevadm info`. I once had a USB-Ethernet device that `udevadm info` gave me the following attributes:

```
  looking at device '/devices/pci0000:00/0000:00:14.0/usb1/1-4/1-4:1.5/net/enp0s20f0u2':
    KERNEL=="enp0s20f0u2"
    SUBSYSTEM=="net"
    DRIVER==""
    ATTR{addr_assign_type}=="0"
    ATTR{addr_len}=="6"
    ATTR{address}=="5a:4e:2b:2b:30:22"
    ATTR{broadcast}=="ff:ff:ff:ff:ff:ff"
    ATTR{carrier}=="1"
    ATTR{carrier_changes}=="2"
    ATTR{carrier_down_count}=="1"
    ATTR{carrier_up_count}=="1"
    ATTR{dev_id}=="0x0"
    ATTR{dev_port}=="0"
    ATTR{dormant}=="0"
    ATTR{flags}=="0x1003"
    ATTR{gro_flush_timeout}=="0"
    ATTR{ifalias}==""
    ATTR{ifindex}=="51"
    ATTR{iflink}=="51"
    ATTR{link_mode}=="0"
    ATTR{mtu}=="1500"
    ATTR{name_assign_type}=="4"
    ATTR{netdev_group}=="0"
    ATTR{operstate}=="up"
    ATTR{proto_down}=="0"
    ATTR{tx_queue_len}=="1000"
    ATTR{type}=="1"

  ...
  ...
```

There seemed to be a lot of attributes for me to choose, but when I tried the attribute `ATTR{operstate}=="up"`, I couldn't match the device.

### 4.2 Write the rules

You can read the rules under `/lib/udev/rules.d/` to learn how to use the various features of `udev`.

### 4.3 Reload the rules

Run `sudo udevadm control --reload` to reload the rules, as [2] says:

> -R, --reload
>
> Signal systemd-udevd to reload the rules files and other databases like the kernel module index. Reloading rules and databases does not apply any changes to already existing devices; the new configuration will only be applied to new events.

### 4.3 Test the rules using `udevadm test`

If you know the `devpath` of a device, you can run `udevadm test [OPTIONS] <devpath>` to test it. If your rules are correct **to some extent**, you should be able to see the actions by your assignment keys in the output. For example, if you use `NAME` to rename a network interface, you should be able to see an line that mentions the renaming (although it may fail due to insufficient privilege), or if you use `RUN` to run a command, you should be able to see a line that says the command is run.

**However**, I said "correct **to some extent**" because your rule may pass `udevadm test` but still fail in a real test (i.e., when you unplug and re-plug a device). Still, I haven't figured out why, but I **guess** it's because `udevadm test` uses all the attributes that `udevadm info` lists to test your rule. But as I said above, in a real test, not all the `udevadm info` attributes are available. So if you happen to use such an attribute, your rule will fail. I was bitten by this when I was trying to match the USB-Ethernet device I mentioned above. In my initial rule, I included `ATTR{operstate}=="up"` because it was listed by `udevadm info`, and `udevadm test` also showed the test was successful. But the rule always failed when I actually unplugged and re-plugged the device. After I removed `ATTR{operstate}=="up"`, both `udevadm test` and the real test could succeed.

### 4.4 Test with the real hardware

As I said in 4.3, `udevadm test` is not 100% reliable. You still need to test the real hardware to see if the rule fully works as expected.

## 5. How to view logs

To see how `udev` works:
- Run `dmesg --follow` to see the kernel messages. (Or run `tail -F /var/log/kern.log`.)
- Run `udevadm monitor` to see the kernel uevents and `udev` events.
- Run `journalctl -u systemd-udevd.service` to see `udev` logs.
  - Run `sudo udevadm control --log-priority=debug` to set the logging level to `debug` to see more details.

## 6. Gotchas

- Some of the attributes that `udevadm info --attribute-walk` may not be usable for matching devices. See section 4.1 for more details.
- Even though `udevadm test` works, your rule may still fail when tested on the real hardware. See section 4.3 for more details.
- The assignment key `NAME` only deals with network interface names.
- The assignment key `SYMLINK` only deals with device nodes under `/dev`. Because network interfaces usually do not have device nodes under `/dev`, you can't create an alias name for a network interface using `SYMLINK`.
- The command in the assignment key `RUN` must be specified with the full path (e.g., `/usr/bin/touch`) probably because `RUN` does not have a full shell environment.
- You can use `lsusb -v` to view the properties of a device, but because `lsusb -v` doesn't tell you whether properties belong to the same parent device, it is easier to violate the single-parent-device rule. See [6] for an example.

## References

- [1] [`udev(7)`](https://manpages.ubuntu.com/manpages/bionic/man7/udev.7.html)
- [2] [`udevadm(8)`](https://manpages.ubuntu.com/manpages/bionic/man8/udevadm.8.html)
- [3] [Writing udev rules](http://reactivated.net/writing_udev_rules.html): This is a very good introductory tutorial of writing `udev` rules. In case the article is gone someday, I saved a copy of the HTML page [here](https://github.com/yaobinwen/robin_on_rails/blob/master/Linux/systemd/Writing-udev-rules.html).
- [4] [Wikipedia: udev](https://en.wikipedia.org/wiki/Udev)
- [5] [udev - Linux dynamic device management](https://wiki.debian.org/udev)
- [6] [A question that I answered on `superuser.com` about why rules didn't work](https://superuser.com/a/1747255)
