---
comments: true
date: 2023-07-30
layout: post
tags: [Tech]
title: Representing signed numbers
---

This article contains the notes from [Stanford CS107: Computer Organization & Systems: Lecture 2: Integer Representations and Bits / Bytes](https://web.stanford.edu/class/archive/cs/cs107/cs107.1238/lectures/2/Lecture2.pdf). The purpose is to solidify my fundamental knowledge of computer science.

We reserve the **most significant bit (MSB)** to store the sign. This is fine.

An initial solution is to use the rest of the bits to encode the values. For example:
- Decimal 6 is encoded as `0110` in binary. The MSB is `0` to indicate the number is positive.
- Decimal -3 is encoded as `1011` in binary. The MSB is `1` to indicate the number is negative.

The problem with the initial solution is we will have two zeros:
- Positive zero: `0000`
- Negative zero: `1000`

4 bits can encode 16 numbers, but because the initial solution results in two zeros, we will only be able to encode 15 signed numbers:
- Technically, zero is neither negative nor positive. However, under this encoding scheme, the positive zero and the negative zero are encoded differently so we must see them as two separate items.

| Positive | Negative  |
|:--------:|:---------:|
| 0 = 0000 | -0 = 1000 |
| 1 = 0001 | -1 = 1001 |
| 2 = 0010 | -2 = 1010 |
| 3 = 0011 | -3 = 1011 |
| 4 = 0100 | -4 = 1100 |
| 5 = 0101 | -5 = 1101 |
| 6 = 0110 | -6 = 1110 |
| 7 = 0111 | -7 = 1111 |

This encoding also makes the arithmetic unnecessarily complicated, because when performing an arithmetic operation, we need to find the sign, do the calculation, then maybe need to change the sign.

The ideal solution is: **binary addition would just work regardless of whether the number is positive or negative**. With this goal in mind and noticing that `N + (-N) = 0`, given the binary representation of a positive number, the binary representation of the corresponding negative number could be something that produces 0 when added to the binary representation of the positive number. For example:
- Given `0001` (1), the negative counterpart could be `1111` because `0001` + `1111` -> `1|0000` (the left-most `1` is considered "overflowed").
- Given `0101` (5), the negative counterpart could be `1011` because `0101` + `1011` -> `1|0000`.
- Given `0000` (0), the negative counterpart could be `0000` because `0000` + `0000` -> `0|0000`.

So now we can try to encode the 16 numbers differently (Range: `-8` ~ `7`):

| Positive | Negative  |
|:--------:|:---------:|
| 0 = 0000 | (No `-0`) |
| 1 = 0001 | -1 = 1111 |
| 2 = 0010 | -2 = 1110 |
| 3 = 0011 | -3 = 1101 |
| 4 = 0100 | -4 = 1100 |
| 5 = 0101 | -5 = 1011 |
| 6 = 0110 | -6 = 1010 |
| 7 = 0111 | -7 = 1001 |
| N/A      | -8 = 1000 |

This encoding scheme is called the **two's complement**. Given a binary representation, the way to find its two's complement is **"inverting binary digits and add 1"**. For example:

| Original | Inverted | plus 1 | Two's complement |
|:--------:|:--------:|:------:|:----------------:|
| 0000     | 1111     | 0000   | 0000             |
| 0101     | 1010     | 1011   | 1011             |
| 1101     | 0010     | 0011   | 0011             |
| 1001     | 0110     | 0111   | 0111             |

The special case is `-8` (1000). When using only 4 bits, `-8` (1000) doesn't have the two's complement because `+8` is not in the range of 4 bits signed numbering system.

Another way of finding a number's two complement is: Work right-to-left and write down all digits through when you reach a `1`. Then invert the rest of the digits. For example:
- 1). The original number is `0010`.
- 2). Work right to left and write down all digits through until reaching a `1`: `??10`.
- 3). Invert the rest of the digits: `1110`.

To calculate the corresponding decimal value of a binary representation, simply multiply the MSB by `-1` and multiply all the other bits by `1`` as normal. For example:
- \\((1110)\_2 = 1 \times (-2^3) + 1 \times 2^2 + 1 \times 2^1 + 0 \times 2^0 = (-2)\_{10}\\)
- \\((0101)\_2 = 0 \times (-2^3) + 1 \times 2^2 + 0 \times 2^1 + 0 \times 2^0 = (5)\_{10}\\)
