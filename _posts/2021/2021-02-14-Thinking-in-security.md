---
comments: true
date: 2021-02-14
layout: post
tags: [Tech]
title: Thinking in Security
---

## Why This Article

I am a security novice. I am not a security guru. Along the way of learning information security, I find so many different ways of practicing security: some are considered generally good while some bad; or, some are only considered good in certain circumstances. Oftentimes, I find I do not have a thinking model to decide if a practice is good or bad. Therefore, I spent some time in thinking about what problems the information security industry tries to solve with the hope that this can help me evaluate a particular security practice in a particular situation. This article is the result of my thinking.

## Warning

Because I'm still an apprentice of security, the terminology I use in this article may look naive, stupid, or even wrong to the gurus. Please excuse me for that. Take the ideas away (if you find them useful) and leave the terms here.

Being a novice means this is just my **current** understanding which can be evolved as I learn more, so what I write down today may be completely overthrown my what I think about tomorrow.

## The Original Problem: from Plaintext to Ciphertext

The very original problem that information security wants to solve is: **how can I make sure the message is only read by the intended audience?** I believe this is the first principle to think about the whole information security industry. Some early attempts [1] were made to transform the message in plaintext into ciphertext.

The model for the this is the _Alice and Bob_ model [2], as shown below:

![The Romance of Alice, Bob, and Moallory](https://upload.wikimedia.org/wikipedia/commons/7/7c/Alice-bob-mallory.jpg)

This model raises two questions:

- 1). With the knowledge that Mallory might be evesdropping, how can Alice and Bob make sure Mallory won't be able to understand the messages even if he captures all of them?
- 2). When Alice or Bob receives a message from the other, how can he/she know if the message is intact or already tampered by Mallory?

With these two questions in mind, we know that:

- 1). If the communication channel is insecure, exchanging messages in plaintext is bad practice. But if the communication channel is guarantteed secure, it is OK to exchange plaintext.
  - In fact, in the Fortress Model below, the realm inside the fortress is generally considered secure, so the work inside the fortress can be done without encryption.
- 2). The exchanged messages should be signed [3] to be tamper-evident, so if the message content is changed by the third party, the recipient can detect that easily.

## Security Realm: the Fortress Model

Although [4] provides some good answers to "what a security realm is", I have my own understanding of it.

I think of a security realm in a physical sense: a security realm is a fortress with walls that only the friends are supposed to enter and foes are rejected. When a visitor arrives, the guards ask for a password. Only those who provide the correct passwords are allowed to enter. This model raises several questions:

- 1). Most of the time, the visitors try to enter the fortress through the gates. But how do you prevent them from climbing into the fortress through the windows and vents?
- 2). How do you make sure the foes have no way to know the correct password?
- 3). How do you make sure the guards are loyal and not corrupted by the foes? A corrupted guard can pretend to be doing the job but let all the bad guys enter the fortress.
- 4). When you realize a password is no longer safe thus revoke it (e.g., a friend betrays and becomes a foe), how do you make sure that the foes won't be able to use the old password to enter the fortress?
- 5). When you need to use a new password because you decide to revoke the old one, how do you update all the friends the new password without leaking it to the foes? This is usually an issue of the _Alice and Bob_ model.

If you think of your work computer as a fortress and you are the only legitimate visitor to use it, this model applies as follows:

- 1). Very likely, your computer is connected to the internet. How do you make sure no malware creeps into your computer through the web links?
- 2). How do you make sure the other people who happen to pass by your seat or cubical have no way to get access to your computer?
- 3). The login screen of your computer is similar to the guard of the fortress gate. How do you make sure the login screen is not a fake which secretly sends your password to somebody else?

I find this Fortress Model is useful because:

- 1). It can be scaled up and down. A realm can be as small as a computer and as large as a whole office building. It doesn't have to be physical, either.
- 2). It can be physical or logical. A realm can be a physical machine but also the corporate network which is across different continents but is treated as a whole logical network.
- 3). It can be recursive. A realm can be an office building which consists of smaller realms of rooms. Different rooms may have different security policies.

## The Eternal Conflict: Security vs Convenience

If you want something to be really well secured, you will have to sacrifice the convenience. If you want more convenience, you'll have to sacrifice some security. Choose a good balance.

For example, you may want to protect your email account really well, then one of the things you must do is use a strong password. A strong password is usually hard to remember, so you will have to sacrifice the convenience of easily remembering the password. However, for something less important, you may think it's not a big deal if the account is stolen, so you choose a relatively simple password to remember which also makes it easier for bad guys to crack the account.

## Next Step: Learn the Good and Bad Practices

I think all the security-related problems can be analyzed using the two fundamental models above. The next step is: for both models (and their variants), learn the good practices to know what should be done as well as the bad practices to know what should be avoided. Then, when you face a real-world problem, break the problem into smaller parts that fit the models, then figure out what should and shouldn't be done in each part.

However, that each part is secured may not mean the entire system is secured. So I think the system-level analysis of security is also needed.

## References

- [1] [A Brief History of Cryptography](http://www.cypher.com.au/crypto_history.htm)
- [2] [Alice and Bob](https://en.wikipedia.org/wiki/Alice_and_Bob)
- [3] [Digital signature](https://en.wikipedia.org/wiki/Digital_signature)
- [4] [Stack Overflow question: What is the exact uses of REALM term in security?](https://stackoverflow.com/q/8468075/630364)
