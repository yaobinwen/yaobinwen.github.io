---
comments: true
date: 2024-07-14
layout: post
tags: [Tech,Hardware]
title: Understanding why memory alignment is needed from the hardware perspective
---

To understand why memory alignment can make the operation faster in the first place, we need to understand how the hardware is implemented.

## The memory

The smallest unit of information storage in the memory is one bit, i.e., a value of 0 or 1. On the hardware level, an [S-R latch](https://en.wikibooks.org/wiki/Digital_Circuits/Latches) is the hardware that's used to store one bit of information.

The smallest addressable unit in the memory is one byte, i.e., an array of 8 bits. Every byte is assigned with an address. To read/write a byte, the CPU must specify the corresponding address of that byte and read/write it as a whole. In other words, a byte is also the smallest readable/writable unit of information. On the hardware level, eight S-R latches are put together to implement one byte of storage.

## System buses

On the motherboard, CPU and memory are separate pieces of hardware. They are connected via the system buses that consist of three buses:
- The **address bus** that carries the address of the byte(s) to be read/written.
- The **data bus** that carries the bytes that are read/written.
- The **control bus** that carries the command about what operation (e.g., read/write) to perform on the memory.

Every bus is just a group of wires. Each wires has two states, 0 or 1, that represents one bit of information. The width of a bus is the number of wires that that bus contains. Width matters. For example:
- An address bus of width 33 (i.e., contains 33 wires) can represent \\(2^{33} \div 8\\) different addresses ("\\(\div 8\\)" is needed because only a byte, or 8 bits, has an address), or 8 GB.
- A data bus of width 32 (i.e., contains 32 wires) can carry 32 bits, or 4 bytes, of data in one sitting. Therefore, its data transfer efficiency is twice as much as a data bus of width 16.

Therefore, for the CPU and the memory to exchange data, they both must be wired to the system buses:
- The address bus is used to specify which part of the memory is to be accessed.
- The data bus is used to carry the data to be exchanged.
- The control bus is used to specify the operation to be performed, e.g., read/write.

## Wiring

Let's use a data bus of width 16 as the example for discussion.

When the memory is wired to the data bus, they are wired this way:

<img alt="Wiring between memory and data bus" src="https://raw.githubusercontent.com/yaobinwen/yaobinwen.github.io/master/images/2024/07-14/memory-data-bus-wiring.png" />

From the diagram, we can see that data bus can transfer the data in the byte 0 and the byte 1 together, and the data in the byte 2 and the byte 3 together. The byte 2 and the byte 3 cannot be transferred together, because the byte 2 is wired to the wires 8 ~ 15 on the data bus, while the byte 3 is wired to the wires 0 ~ 7 on the data bus. The order they should be accessible (i.e., byte 2 followed by byte 3) is opposite to the order they are wired to the data bus (i.e., byte 3 is wired to the lower 8 wires while byte 2 is wired to the higher 8 wires).

As a result, if the CPU needs to get byte 1 and byte 2 as a pair, it needs to fetch them in two cycles:
- In the first cycle, the CPU fetches byte 0 and byte 1 because they can be fetched together. Then the CPU discards byte 0.
- In the second cycle, the CPU fetches byte 2 and byte 3 because they can be fetched together. Then the CPU discards byte 3.
- Then the CPU combines byte 1 and byte 2 as the result.

This is the reason on the hardware level that memory alignment is recommended: if you make sure the data you want to access is at the address of 0, 2, 4, etc., the data can be accessed in fewer cycles than the misaligned data.
