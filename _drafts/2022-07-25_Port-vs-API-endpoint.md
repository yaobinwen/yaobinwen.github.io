---
comments: true
date: 2022-07-25
layout: post
tags: [Tech]
title: Ports vs API endpoints
---

1. A house is like a computer.
2. A house may have one or more doors to the outside world. These doors are like the network cards.
3. A person living in the house is like a process in the computer.
4. The OS is like the house butler.
5. When Ada in house 1 wants to send a mail to Bob in house 2, she gives the mail to the house 1 butler.

My friend asked me about "ports" and "API endpoints" because she got confused by them a little bit. This article is an extended answer to the question.

First of all, we need to understand what a "port" is, and in order to understand that, we need to go back to the time when network was not invented yet - in other words, the time when people still used computers locally.

When we "use" computers, we run the programs we want to use. If you have ever taken an Operating System (OS) course, you will learn that the one-time execution of a program is called a "process" in the OS. A program is a piece of static instructions we want to give to the computers, and a process is the dynamic execution of these instructions to actually fulfill the purpose of these instructions.

Use cooking as the example: A program is the recipe of a dish that's printed on a piece of paper, but the recipe itself does not and will not put a delicious dish in front of you for you to enjoy. You will have to let the chef, i.e., the process, go through the recipe step by step to actually cook it.

Our focus is on the "processes" so we can ignore "programs" for now. Because a process actually functions in some way, we can also say the process provides some "service". For example, the Calculator process provides a service of calculation - the user feeds in numbers, the service spits out the result.

Before the time of the network, every computer ran as a "local" unit: The user must be physically local with the computer in order to use those "services" that were running on the computer. In order to interact with the users, the processes must be able to read input from the "standard input" (which was typically the keyboard that was physically and locally connected to the computer) and print the result to the "standard output" (which was typically the monitor that was also physically and locally connected to the computer).

But in the era of networks, when we want to use a service (i.e., a process) that's running on a remote computer (i.e., not physically local), how can we communicate/interact with the service?

Before we can communicate with the service, we must find the service (or locate it, or identify it). As we mentioned above, a "service" is essentially a "process" that's running on a computer, so "finding the service" is really to find two things:

- 1). The computer.
- 2). The serving process on this computer.

The Internet Protocol (IP) can help us find a specific computer on the network. So the question is really about how to find that particular serving process on the computer.

The OS usually assigns a unique integer, called "process ID", to every process in order to identify them. Although we could use the process ID to find the process, the ID has a few drawbacks:

- 1). The ID is not guaranteed to be the same when the process is restarted even for the same program. For example, if we run the Calculator program today (so it is launched as a process), the process ID might be, say, 123. Later we find a bug in the program and fix it, so we need to restart it as a new process, the process ID is very likely to be a different number, say, 456. For the remote users of this Calculator service, they will have to somehow get the new process ID and reconnect to it. This sounds like a friend who lives in an apartment with 100 rooms and he/she moves from one room to another quite often, and every time we want to visit this friend, we will have to re-obtain the current room number.
