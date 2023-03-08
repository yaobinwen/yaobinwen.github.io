---
comments: true
date: 2023-03-06
layout: post
tags: [Tech,Theory,Security]
title: Information, Entropy, and Password Strength
---

## Introduction

I've known the term "entropy" for a long time, and I've also heard people mention "entropy" when talking about the password strength, but I have never really understood what entropy is and how it is related with password strength. I studied the subject recently and this article is my notes.

I used the following references for this article:
- [1] [Matthew N. Bernstein: _Foundations of information theory_ series](https://mbernste.github.io/posts/self_info/)
  - [1.1] [What is information? (Foundations of information theory: Part 1)](https://mbernste.github.io/posts/self_info/)
  - [1.2] [Information entropy (Foundations of information theory: Part 2)](https://mbernste.github.io/posts/entropy/)
  - [1.3] [Shannon’s Source Coding Theorem (Foundations of information theory: Part 3)](https://mbernste.github.io/posts/sourcecoding/)
- [2] [Wikipedia: Information content](https://en.wikipedia.org/wiki/Information_content)
- [3] [Wikipedia: Entropy (information theory)](https://en.wikipedia.org/wiki/Entropy_(information_theory))
- [4] [Wikepedia: Shannon's source coding theorem](https://en.wikipedia.org/wiki/Shannon%27s_source_coding_theorem)

## Surprise and information

Although we have used the word "information" frequently in everyday life, as [1] mentioned, people haven't come up with a well accepted definition for the term "information". Actually, as [1] says, "there is an [entire field of philosophy](https://plato.stanford.edu/entries/information/) dedicated to the construction of such a definition."

I was surprised by the fact that "information" does not have a good definition yet. This fact gives me a lot of information.

I wasn't making a recursive joke in the previous paragraph. If we think about our everyday experience, we can see the amount of information we get from a piece of news is usually proportional to how much surprise we feel when we read or hear the news. The more surprised we are, the more information we can retrieve from the news.

For example, I learned Euclidean geometry in middle school and the fifth axiom said "through any given point not on a line there passes exactly one line parallel to that line in the same plane." (Britannica: [parallel postulate](https://www.britannica.com/science/parallel-postulate)) As a middle school boy, I thought that was the truth of the universe based on my daily experience and never thought there could be other possibilities. Later in college, I learned two other non-Euclidean geometries ([Lobachevskian geometry](https://en.wikipedia.org/wiki/Hyperbolic_geometry) and [Riemannian geometry](https://en.wikipedia.org/wiki/Riemannian_geometry)) in which the fifth axiom is stated differently. I was quite surprised that there CAN be other possibilities and that broadened my horizon quite a bit (i.e., provided me with a lot of new information).

Another example is the ["black swan" events](https://en.wikipedia.org/wiki/Black_swan_theory). A "black swan" event is a kind of event that people generally think would rarely or never happen based on people's current understanding of the world, but actually happens. The occurrence of a "black swan" event would surprise people greatly, but also provide a lot of information that could potentially change how people view the world and establish a new theory of the world.

So if we want to measure the "amount of information" mathematically, we know the key input is the "amount of surprise." Based on our everyday experience, we know the "amount of surprise" can be measured by the likelihood of an event occurrence: If something happens every day and we get used to that, we don't think it's much of a surprise when it happens again. But if something that usually doesn't happen happens, we would be surprised much more. In the next section, we will try to establish the mathematical relationship between "information" and "likelihood".

## Mathematical description of information

In this section, we are going to try to find a mathematical function that defines the relationship between information and surprise.

The previous section said the amount of information is proportional to the amount of surprise which is negatively correlated with the likelihood of an event (i.e., "less likely" means "more surprise"). Therefore, we can say:

> The more likely an event happens, the less information the occurrence carries; the less likely an event happens, the more information the occurrence carries.

Because we know the likelihood of occorrence must be a probability between 0% (inclusive) and 100% (inclusive), **the domain (i.e., input range) of this function must be from 0 (inclusive) to 1 (inclusive)**.

Because "[t]he more likely an event happens, the less information the occurrence carries", we can say when we are certain that something happens, the information it provides is zero. For example, we know the sun rises every day. We are also certain that even if the entire earth is nuked, the sun also rises the next day. So the rising of the sun has the probability of 100% and its occurrence doesn't give us any new information.

On the other side, what if something that's believed would never happen actually happens? What if the sun wouldn't rise anymore? What if a dead person would return alive? What if you saw an elephant fly across the sky? How much information could we get from those impossible events? Probably we can get a positively infinite amount of information, because it's hard to argue for any finite amount of information: where should we set that finite number? In addition, a negatively infinite amount of information doesn't seem to make sense either. So we can derive the output range of this function:

> - When the input value is 1 (or 100%), the output value is **zero**.
> - When the input value is 0 (or 0%), the output value is **positive infinity (+∞)**.

[1] uses `I` to denote this function and `I` is called "self-information"[2]:

```
I: [0,1] -> [0,∞)
```

[1] also discusses the properties that `I` should possess, based on our everyday experience:

- 1). **Continuous**: "a small change in the probability of an event should lead to a corresponding small change in the surprise that we experience."
- 2). **Non-negative**: A "negative amount of information" doesn't make much sense.
- 3). **Monotonic**: If A is less likely than B, then A is more surprising than B.
- 4). **Additive if independent**: If two events are independent, the surprises we get from their occurrences can be added.

[1] then said the only mathematical function that satisfies all the properties is the following one:

```
I(p) := -log2(p)
```

where:
- `p` is the probability of the occurrence of an event
- `log2` is base-2 logarithm.

[1.2] discusses the meanings of different bases but in this article we will use base 2, because the current computers are based on the binary counting system.

I have to say I'm not sure if it is the only function we can find. But from reading other articles, I know this function works properly so we can just take it.

In a more abstract way, if we use the variable `X` to denote the event, and the concrete values `x1`, `x2`, ..., `xN` to denote the occurrences of all the possible N cases of `X`, we can say the information of the occurrence of the n-th case is:

```
I(p(X=xn)) := -log2(p(X=xn))
```

When `p` is 1 (100%), `I(p)` is 0. When `p` is 0 (0%), `log2(p)` is undefined, but as we discussed above, we can define it as positive infinity (`+∞`).

## Examples of `I(p)`

Let's use tossing a coin as the example to calculate `I(p)`.

Tossing a coin can have two possible outcomes: `head` or `tail`. Assuming the coin is fair sided, we have:
- The occurrence of the event "coin is head up" is `0.5` (50%), i.e., `p(X=head) = 0.5`.
- The occurrence of the event "coin is tail up" is `0.5` (50%), i.e., `p(X=tail) = 0.5`.

Therefore:
- The information we can when "coin is head up" occurs is: `I(p(X=head)) = -log2(0.5) = 1`.
- The information we can when "coin is tail up" occurs is: `I(p(X=tail)) = -log2(0.5) = 1`.

Suppose the coin is biased as follows:
- The occurrence of the event "coin is head up" is `0.75` (75%), i.e., `p(X=head) = 0.75`.
- The occurrence of the event "coin is tail up" is `0.25` (25%), i.e., `p(X=tail) = 0.25`.

Therefore:
- The information we can when "coin is head up" occurs is: `I(p(X=head)) = -log2(0.75) = 0.415`.
- The information we can when "coin is tail up" occurs is: `I(p(X=tail)) = -log2(0.25) = 2`.

Note that when the probability of "head up" increases from `50%` to `75%`, the information we get from the occurrence drops from `1` to `0.415`. This is because as the event becomes more likely to happen, we get used to its occurrence so we are not that surprised to see it happen again. But when the "tail up" probability drops from `50%` to `25%`, the information of its occurrence increases from `1` to `2`.

Suppose the two sides of this coin are both "head", meaning:
- The occurrence of the event "coin is head up" is `1` (100%), i.e., `p(X=head) = 1`.
- The occurrence of the event "coin is tail up" is `0` (0%), i.e., `p(X=tail) = 0`.

Therefore:
- The information we can when "coin is head up" occurs is: `I(p(X=head)) = -log2(1) = 0`. When something always happens, we can get nothing (but tiredness) from it.
- The information we can when "coin is tail up" occurs is: `I(p(X=tail)) = -log2(0) = undefined (or +∞)`.

## Entropy

In information theory, the entropy measures the **average** level of **surprise/information** of a variable's all possible outcomes [3]. In other words, entropy is the **expected information** we get when the event `X` happens. It is calculated as follows:

```
H(X) := -Σ{n=1..N} [p(X=xn)*log2(p(X=xn))]
```

The entropy tells us that, on **average**, how surprised we are by the outcome of the concerned event. Because entropy takes all the possible outcomes into consideration, it describes a property of the **entire system, not just a particular outcome**.

Let's still use the coin as the example.

When the coin is fair sided, i.e., `p(X=head) = 0.5` and `p(X=tail) = 0.5`, the entropy of the coin tossing system is:

```
H(coin) = -[p(X=head)*log2(p(X=head)) + p(X=tail)*log2(p(X=tail))]
        = -[0.5 * log2(0.5) + 0.5 * log2(0.5)]
        = -[0.5 * (-1) + 0.5 * (-1)]
        = 1
```

When the coin is biased and `p(X=head) = 0.75` and `p(X=tail) = 0.25`, the entropy of the coin tossing system is:

```
H(coin) = -[p(X=head)*log2(p(X=head)) + p(X=tail)*log2(p(X=tail))]
        = -[0.75 * log2(0.75) + 0.25 * log2(0.25)]
        = -[0.75 * (-0.415) + 0.25 * (-2)]
        = 0.81125
```

When the coin is both sides as "head", i.e., `p(X=head) = 1` and `p(X=tail) = 0`, we need to firstly figure out the value of `p(X=tail)*log2(p(X=tail))` because `log2(p(X=tail))` is undefined (or positive infinity) which can't be directly used in an arithmetic calculation. In mathematics and information theory, the widely used convention is to define `0*log2(0)` as `0` (which is consistent with `limit {x->0+} x*log2(x) = 0`).[3] Therefore, the entropy of the coin tossing system is:

```
H(coin) = -[p(X=head)*log2(p(X=head)) + p(X=tail)*log2(p(X=tail))]
        = -[1 * log2(1) + 0 * log2(0)]
        = -[1 * 0 + 0]
        = 0
```

From the example above, we can tell that: A system whose probability is in the uniform distribution has the highest entropy, or the highest expected information. A system of no uncertainty (i.e., some event always happens) has zero entropy, or zero expected information. This matches what we discussed earlier: In a system, if the probability of the occurrence of every possible value is equal, it's the most difficult to predict what value can actually occur, so we will always get some sort of surprise. In a system whose probability is lessly uniformly distributed, the system is more predictable. Although we can get more surprise when a less likely value occurs, but remember that entropy measures the entire system, so when the entire system is more predictable, the entropy (or the expected information, or the average surprise) is still lower.

Therefore, entropy is a measurement of the uniformness of the system's probability distribution. **The higher the entropy is, the more uniformly the system's probability is distributed. When the system probability is evenly distributed, its entropy hits the maximal value.**

## Entropy of a password system

In fact, it doesn't make sense to talk about the entropy of a password. As we discussed above, entropy is a property of the entire system. One concrete password is just one possible value of all the possible values within a specific password system. Therefore, we can only discuss the entropy of a password system.

Nowadays, a password is typically a sequence of characters of some length. Therefore there are three important aspects of a password system. The first two aspects are:
- **The set of characters that can be used in a password.** For example, one password system may consist of only digits (i.e., 0 ~ 9), such as ATM PIN. Another password system may consist of a wider range of characters, such as digits and English letters (in lower and upper cases). Let's use `N` to denote the number of available characters to choose.
- **The length of a password.** Let's use `L` (and `L > 0`) to denote the length.

With `N` available characters to choose from, there can be `N^L` possible passwords of length `L`. Let's use `Pi` to denote the i-th password where `1 <= i <= N^L`. In real world scenarios, the "password length" is the upper limit of passwords, so an actual password can be shorter than `L`. But to make the discussion easier in this article, I'll assume `L` means the password must have exactly `L` characters.

To calculate the entropy of the password system, we need to determine the probability of each password (i.e., the probability of the event "the chosen password is Pi"). This is determined by the third aspect: **The strategy of choosing the password from all the possible passwords**.

There are two strategies. The first strategy chooses a password based on certain easy-to-remember patterns because the users want to be able to remember them in mind. These patterns use such as important dates, names, places, or things that are directly related with the users themselves. As a result, for a particular user, this strategy causes some passwords are more likely to be chosen than other passwords.

The second strategy chooses a password truly randomly, based on no pattern. This strategy makes every possible password is equally possible to be chosen, so the probability is in the uniform distribution.

With all the three aspects, we can calculate the password system entropy.

## Entropy of password system of uniform probability distribution

In this section, I'll calculate the entropy of the password system from the previous section under the second strategy. To be honest, my mathematical knowledge is not enough to calculate the entropy of password systems of arbitrary probability distribution.

As we have seen, in this password system:
- There are `N^L` possible passwords.
- The probability of every password is `1/(N^L)`.

Therefore, the entropy of the password system is:

```
H = -Σ{i=1..N^L} [p(X=xi)*log2(p(X=xi))]
  = -Σ{i=1..N^L} [(1/(N^L))*log2(1/(N^L))]
  = -(N^L)*[(1/(N^L))*log2(1/(N^L))]
  = -log2(1/(N^L))
  = log2(N^L)
```

I calculated the entropies with different `N` and `L` in the following table:

| N | L | H |
|:-:|:-:|:-:|
| 10 | 1 | 3.322 |
| 10 | 5 | 16.610 |
| 10 | 10 | 33.219 |
| 26 | 1 | 4.700 |
| 26 | 5 | 23.502 |
| 26 | 10 | 47.004 |
| 52 | 1 | 5.700 |
| 52 | 5 | 28.502 |
| 52 | 10 | 57.004 |

We can tell that:
- When `N` is fixed, the longer the password is, the higher the entropy is.
- When `L` is fixed, the more available characters to choose from, the higher the entropy is.

## Password strength

According to Shannon's source coding theorem [4], entropy is the minimum number of bits (assuming under a base-2, i.e., binary, system) that are needed to communicate the value without information loss. In other words, if we want to **fully** represent a password in a password system, we need at least the entropy number of bits. If we use fewer bits, we cannot represent the password completely so the password cannot be used to log in the system.

In other words, if a hacker tries to use brute force to crack a password, and if the entropy of the password system that the concerned password belongs to is `H`, then the hacker needs to try at most `2^H` times. Therefore, **the higher the entropy is, the more difficult for the hacker to crack the password, and the stronger the password is**.

For example, if `N=52` and `L=10`, as we calculated in the previous section, `H=57.004`. So a hacker needs to try `2^57.004=1.445153147×10^17` times to crack the password. If the hacker can guess a million times (i.e., `10^6`) per second, he/she will need about `144515314657` seconds which are about `1672630` days which are about `4582` years.

This [Password Cracking Calculator](https://passwordbits.com/password-cracking-calculator/) estimates the cost to crack a password and it also explains how the cost is estimated. It's surprising to see some seemingly strong passwords may not cost that much to get cracked.

So go with caution.
