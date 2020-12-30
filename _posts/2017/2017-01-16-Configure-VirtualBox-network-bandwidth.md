---
comments: true
date: 2017-01-16
layout: post
tags: [Tech]
title: Configure `VirtualBox` Network Bandwidth
---

I'm using VirtualBox 4.3.36 on my Ubuntu 14.04. Both the host and guest are Ubuntu 14.04. Today when I was copying some files in it from a remote computer, I noticed that the network bandwidth was just about 5 to 7 kilobytes per second.

I searched on the Internet and eventually got to one chapter of VirtualBox official documentation: [Chapter 6. Virtual networking](https://www.virtualbox.org/manual/ch06.html#network_performance). This section provides some rules of thumb to tune the virtual machine's network performance:

> Here is the short summary of things to check in order to improve network performance:
>
> * Whenever possible use virtio network adapter, otherwise use one of Intel PRO/1000 adapters;
>
> * Use bridged attachment instead of NAT;
>
> * Make sure segmentation offloading is enabled in the guest OS. Usually it will be enabled by default. You can check and modify offloading settings using _ethtool_ command in Linux guests.

The first two settings can be done in the virtual machine's "Settings" -> "Network". But first of all the virtual machine must be shut down.

The last thing can be done by following the steps below:

* Open a terminal in the guest OS.
* Run the command: ```ifconfig```. Determine the name of the network card used to access the Internet, such as _"eth0"_.
* Run the command: ```sudo ethtool -k eth0```.
* Check the output features, especially the _"tcp-segmentation-offload"_ and _"generic-segmentation-offload"_.
* If either of them is turned off, run the following commands to turn them on:
  * ```sudo ethtool -K eth0 tso on```
  * ```sudo ethtool -K eth0 gso on```

After all of these set, the virtual machine's network bandwidth should be improved as expected.
