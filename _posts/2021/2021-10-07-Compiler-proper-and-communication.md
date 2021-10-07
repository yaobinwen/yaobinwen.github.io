---
comments: true
date: 2021-10-07
layout: post
tags: [Communication]
title: "\"Compiler proper\" and Communication"
---

Today when I read [GCC 7.5 user manual](https://gcc.gnu.org/onlinedocs/gcc-7.5.0/gcc.pdf), I came across the word "proper" a few times:

> (Page 3) To use these, they must be built together with **GCC proper**.
>
> (Page 27) Compilation can involve up to four stages: preprocessing, **compilation proper**, assembly and linking, always in that order.
>
> (Page 30) Stop after the preprocessing stage; do not run the **compiler proper**.

English being my second language, I have never learned this usage of the word "proper". As far as I have learned so far, "proper" is always used alone or before a noun. [For example](https://dictionary.cambridge.org/us/dictionary/english/proper):

- In those days it was considered not quite **proper** for young ladies to be seen talking to men in public.
- She was very **proper**, my grandmother - she'd never go out without wearing her hat and gloves.
- If you're going to walk long distances you need **proper** walking boots.
- I would have done the job myself but I didn't have the **proper** equipment.

So when I saw the phrase "GCC proper", "compilation proper", and "compiler proper", I could guess what they referred to but I wasn't confident enough to say I definitely understand them. Someone on `cplusplus.com` asked [this question](http://www.cplusplus.com/forum/beginner/12638/):

> Hi guys,
>
> I have one simple question.
>
> What is "compiler proper" ?

Someone replied:

> Something you can do in English is, when referring to something in particular, you can say "the X proper" or "the X itself."

Cambridge Dictionary has [a section for this meaning](https://dictionary.cambridge.org/us/dictionary/english/proper), too:

> [ after noun ]
>
> belonging to the main, most important, or typical part:
>
> "It's a suburb of Los Angeles really - I wouldn't call it **Los Angeles proper**."

**At first glance, this looks like a pure language issue. But I don't think so.** The native speakers probably have learned how to use "proper" this way early in their life so they never realize this can become an issue for non-native speakers. So, in a document, in a presentation, or in a speech, the native speakers will just burst out phrases or expressions that they are very familiar but may be unfamiliar to some of the audience. In this particular case of "GCC/compilation/compiler proper", I can make a good guess, but **I think technical communication should be as clear as possible and minimize the need of guess because guess always results in possibility of misunderstanding or miscommunication.**

Another situation I sometimes encounter is the native speakers, when giving a technical talk, joke about the topic or use a slang word to explain the topic that almost only the native speakers can understand. We second-language learners don't get it and don't understand what they just said. If I were sitting in that presentation, I may get the chance to interrupt and ask the speaker to explain a bit further. But when I watch the recorded video of the talk, I will have no way to ask for clarification. As a result, I either get confused for not understanding what the speakers say or I'll have to spend more time to search Google for a proper meaning in order to understand it. I feel frustrated in the former case, or waste some of my time in the latter case.

However, I'm definitely not blaming the native speakers. I also have friends who are learning my mother tongue and I sometimes say something that I don't realize they don't understand until they tell me so.

I think this is a mutual task. The native speakers should use English as simple as possible to explain things. The [KISS principle](https://en.wikipedia.org/wiki/KISS_principle) may be applicable, too. Meanwhile, we language learners should also keep improving our language proficiency so we can understand the native speakers even if they are saying something "very native".
