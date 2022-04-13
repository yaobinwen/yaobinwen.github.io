---
comments: true
date: 2022-04-06
layout: post
tags: [Tech]
title: "Stateful Firewalls and How Connections Are Tracked"
---

## 1. Background

A few days ago, I was trying to figure out some technical issue for my work in which I wanted to set up the firewall (`ufw`) to allow outgoing UDP traffic but deny incoming UDP traffic. However, I found even if I completely deny all incoming traffic, as the following status shows, I could still get UDP communication between machines:

```
$ sudo ufw status verbose
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), deny (routed)
New profiles: skip
```

Later I learned that nowadays firewalls are usually **"stateful"**, as [1] explains:

> A stateful firewall keeps track of the state of network connections, such as TCP streams, UDP datagrams, and ICMP messages, and can apply **labels** such as LISTEN, ESTABLISHED, or CLOSING.[2] State table entries are created for TCP streams or UDP datagrams that are allowed to communicate through the firewall in accordance with the configured security policy. Once in the table, all RELATED packets of a stored session are streamlined allowed, taking fewer CPU cycles than standard inspection. Related packets are also permitted to return through the firewall even if no rule is configured to allow communications from that host. **If no traffic is seen for a specified time (implementation dependent), the connection is removed from the state table.** Applications can send `keepalive` messages periodically to prevent a firewall from dropping the connection during periods of no activity or for applications which by design have long periods of silence. 

In other words, the reason I could still communicate with other machines even if the firewall rules didn't allow incoming traffic was because the "allow" rules for specific incoming traffic were created on the fly.

So I wanted to verify this.

## 2. Is `iptables` Stateful?

I'm using Ubuntu 18.04 so the firewall application is `ufw`. But `ufw` is really just a "uncomplicated" frontend for the underlying `iptables` which is the real firewall application. Firstly, by searching the question "is iptables stateful" on Google, I didn't find any direct reference to the official documentation that says `iptables` is a stateful firewall. However, a few top-ranked search results, such as [2], say it is stateful:

> The _raw_ table: iptables is a stateful firewall, which means that packets are inspected with respect to their "state". (For example, a packet could be part of a new connection, or it could be part of an existing connection.)

[3] also says `iptables` uses the subsystem "Connection Tracking" to implement a stateful firewall:

> Connection Tracking: This subsystem allows for stateful firewalling. This allows for filtering packets based not only on source, destination, port, protocol, etc... but also on the state of the connection (INVALID, ESTABLISHED, NEW, RELATED).

[4] is a more official document that talks about `iptables` being stateful, although it is about Red Hat:

> You can inspect and restrict connections to services based on their connection state. A module within iptables uses a method called connection tracking to store information about incoming connections.
>
> You can use the stateful functionality of iptables connection tracking with any network protocol, even if the protocol itself is stateless (such as UDP).

## 3. How to Confirm the Connection Tracking

To check the tracked connections by `iptables`, one can use `conntrack-tools` [5]:

> Using `conntrack`, you can view and manage the in-kernel connection tracking state table from userspace.

One can install `conntrack` on Ubuntu 18.04 by running `sudo apt install conntrack`.

After installation, run `sudo conntrack -L` to list all the tracked connections in the tablet `conntrack`. For example:

```
...
udp      17 28 src=192.168.86.56 dst=142.250.31.95 sport=56605 dport=443 src=142.250.31.95 dst=192.168.86.56 sport=443 dport=56605 [ASSURED] mark=0 use=1
tcp      6 94 TIME_WAIT src=192.168.86.56 dst=172.217.1.206 sport=60422 dport=443 src=172.217.1.206 dst=192.168.86.56 sport=443 dport=60422 [ASSURED] mark=0 use=1
tcp      6 431986 ESTABLISHED src=203.0.113.129 dst=203.0.113.129 sport=54060 dport=5672 src=203.0.113.129 dst=203.0.113.129 sport=5672 dport=54060 [ASSURED] mark=0 use=1
udp      17 6 src=192.168.86.37 dst=192.168.86.255 sport=35764 dport=3956 [UNREPLIED] src=192.168.86.255 dst=192.168.86.37 sport=3956 dport=35764 mark=0 use=1
tcp      6 31 TIME_WAIT src=192.0.2.1 dst=192.0.2.1 sport=46584 dport=8500 src=192.0.2.1 dst=192.0.2.1 sport=8500 dport=46584 [ASSURED] mark=0 use=1
tcp      6 31 TIME_WAIT src=192.0.2.1 dst=192.0.2.1 sport=46582 dport=8500 src=192.0.2.1 dst=192.0.2.1 sport=8500 dport=46582 [ASSURED] mark=0 use=1
...
```

See `conntrack(8)` for more details.

## 4. An Experiment Using `nc`

To learn `conntrack` further, I used `nc` (`netcat`) to do an experiment which consists of two machines:

- Machine 1:
  - Name: `M4800`
  - mDNS name: `M4800.local` (`192.168.86.58`)
  - Firewall rules: Firewall is disabled
  - Role in experiment: UDP server
  - Port: `61111`
- Machine 2:
  - Name: `M7500`
  - mDNS name: `M7500.local` (`192.168.86.56`)
  - Firewall rules: `deny (incoming), allow (outgoing), deny (routed)`
  - Role in experiment: UDP client
  - Port: `62222`

I started the UDP server on `M4800` by running `nc -v -u -l 192.168.86.58 61111`.

Then I started the UDP client on `M7510` by running `nc -v -u -s 192.168.86.56 -p 62222 192.168.86.58 61111` which means:
- I want to use the source IP address `192.168.86.56` and source port `62222` to connect to the UDP server.
- The UDP server is running on the port `61111` on the address `192.168.86.58`.

I want to set the source IP address and source port to find the tracked connection more easily.

Then by running `sudo conntrack -L -p udp --dport=61111 --sport=62222` I could find the following tracked connection:

```
$ sudo conntrack -L -p udp --dport=61111 --sport=62222
udp      17 93 src=192.168.86.56 dst=192.168.86.58 sport=62222 dport=61111 src=192.168.86.58 dst=192.168.86.56 sport=61111 dport=62222 [ASSURED] mark=0 use=1
conntrack v1.4.4 (conntrack-tools): 1 flow entries have been shown.
```

The number `93` after the number `17` is a count-down timer for the life time of this connection. `93` means the connection has 93 seconds before it gets removed from the tracking table. In other words, during the remaining 93 seconds, a communication channel was dynamically set up for the two machines for this particular UDP communication and the two machines can communicate without traffic getting blocked, even though the firewall rules on `M7510` didn't allow any incoming traffic.

The `[ASSURED]` is the label for this connection which means `iptables` has observed UDP packet stream going back and forth between the two machines so the connection is considered relatively "stable". I'll talk more about this below.

Wait silently for 93 seconds without sending any messages. Then by running `sudo conntrack -L -p udp --dport=61111 --sport=62222` again, I noticed the output was empty which means the connection timed out and was removed:

```
$ sudo conntrack -L -p udp --dport=61111 --sport=62222
conntrack v1.4.4 (conntrack-tools): 0 flow entries have been shown.
```

When the connection got removed, the firewall rule `deny (incoming)` became actually effective and the UDP packets would be block from then on.

## 5. How Connection Tracking Works

I have to say that I haven't read the `iptables` source code so this section is based on my **very limited** observations in the previous section.

It looks like an `iptables` connection to track a UDP session goes through the following states:

- Initially, when one machine initiates a UDP "connection" by sending the first packet to the other machine, and `iptables` notices this initiation, `iptables` marks this connection as `[UNREPLIED]`. A `[UNREPLIED]` connection has the timeout of 30 seconds: Any traffic before the timeout is allowed, but if no more traffic is observed within 30 seconds, this connection will be removed from the tracking table and the further traffic will be disabled.
- When the other machine replies, the `iptables` thinks the connection is "confirmed" so it removes the label `[UNREPLIED]`. But `iptables` still thinks the connection is a one-time thing (in contrast as a "stream") so the timeout is still 30 seconds.
- However, if there is further traffic between the two machines, `iptables` thinks this is a "stream" of traffic so it labels it as `[ASSURED]`, as if to say "the connection is much more stable thus assured", and the timeout increases to 120 seconds.

The two timeouts are controlled by the following two kernel parameters:

```
net.netfilter.nf_conntrack_udp_timeout = 30
net.netfilter.nf_conntrack_udp_timeout_stream = 120
```

## 6. Simulate a Stateless Firewall

One can change the two timeouts to `0` (zero) to simulate a stateless firewall.

## 7. References:
- [1] [Wikipedia: Stateful firewall](https://en.wikipedia.org/wiki/Stateful_firewall)
- [2] [Boolean World: An In-Depth Guide to iptables, the Linux Firewall](https://www.booleanworld.com/depth-guide-iptables-linux-firewall/)
- [3] [Iptables](https://ww2.cs.fsu.edu/~bogdanov/SysAdminSp04/Agenda/week15/iptables_lecture.html)
- [4] [Red Hat Enterprise Linux 6: Security Guide: 2.8.7. IPTables and Connection Tracking](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/security_guide/sect-security_guide-firewalls-iptables_and_connection_tracking)
- [5] [The netfilter.org "conntrack-tools" project](https://www.netfilter.org/projects/conntrack-tools/)
