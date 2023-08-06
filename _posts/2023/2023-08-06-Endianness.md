---
comments: true
date: 2023-08-06
layout: post
tags: [Tech]
title: Endianness
---

**Endianness** is the order or sequence of bytes that are stored in the computer memory in order to represent data.

We will use a number on the machines where an `int` is 4 bytes long as an example to show the concept.

## The number

Consider the hexadecimal number `0x01234567`. It can be divided into 4 bytes: `0x 01 23 45 67`.

|     | Most Significant | Next Significant | Next Significant | Least Significant |
|:---:|:----------------:|:----------------:|:----------------:|:-----------------:|
| Hex | 01               | 23               | 45               | 67                |
| Bin | 0000 0001        | 0010 0011        | 0100 0101        | 0110 0111         |

## The bytes

For the 4 continuous bytes, they are stored in continuous locations in the memory with the indexes 0, 1, 2, 3, or, more generally, N, N+1, N+2, N+3. For simplicity, we will use 0, 1, 2, 3 here.

For people who get used to reading from left to right, the 4 locations are usually written as follows:

| 0    | 1    | 2    | 3    |
|:----:|:----:|:----:|:----:|
| byte | byte | byte | byte |

## Little endianness

If a machine stores the least siginificant byte at location 0 and the most significant byte at location 3, then this storing order is called **little endianness** (because "little end" comes first).

| Index | 0                 | 1                | 2                | 3                |
|:-----:|:-----------------:|:----------------:|:----------------:|:----------------:|
| Hex   | 67                | 45               | 23               | 01               |
|       | Least Significant | Next Significant | Next Significant | Most Significant |

## Big endianness

If a machine stores the most siginificant byte at location 0 and the least significant byte at location 3, then this storing order is called **big endianness** (because "big end" comes first).

| Index | 0                 | 1                | 2                | 3                 |
|:-----:|:-----------------:|:----------------:|:----------------:|:-----------------:|
| Hex   | 01                | 23               | 45               | 67                |
|       | Most Significant  | Next Significant | Next Significant | Least Significant |
