---
comments: true
date: 2023-03-20
layout: post
tags: [Tech,AI]
title: "Thoughts on AI: My anticipations and why"
---

The release of Devin has disturbed a lot of programmers and make them think they are going to lose their jobs.

After thinking about this post, I basically come to the similar conclusion with the author but from a different perspective. If the AI model is significantly improved and we do it right, my anticipations are:
- 1). There is a great potential that AI can become experts in computer science (and mathematics). AI will not replace human programmers but become a wonderful assistant of them.
  - TODO(ywen): AI is a super Turing machine that can simulate all other Turing machines. Look back at my course notes.
- 2). Human programmers nowadays program against machines directly; future human programmers will program AI directly and AI will then program machines directly.
- 3). Human programmers will be more like a "pilot" (to guide AI to solve the problem correctly) and a "reviewer" of AI's work (to make sure AI doesn't deceive us).
  - Because the AI may not completely understand our thoughts (due to the inherent vagueness in the verbal languages), sometimes we human programmers may just write down the code that we want exactly, and ask AI to build other stuff on top of it. This is the "pilot" role.
  - The reviewer role is more like to make sure AI doesn't do anything harm to us.

Although I listed 3) as the last item, it was actually the beginning of my thought process. I thought about the basic question: Do we human beings want AIs to be 100% under control? Do we want AI to do things secretly that's out of our control, thus potentially harm human beings? Probably not.

Note my precondition that AI has been significantly improved. In this situation, when we delegate a task to AI, we can assume AI is smart enough to do thing based on its own plan. Think about how we delegate a task to a human programmer: we describe the task; we probably discuss a general plan (or even not discuss it); the human programmer will develop a detailed plan, finish the work, and return to us. Even if we discuss the detailed plan, we still don't have 100% control of how this programmer actually finishes the task. We care more about the result. For example, based on a discussed plan and the programmer's capability, we decide to give the programmer 5 days to finish the task. But what if the programmer has secretly become more experienced and productive, and can finish the work in 3 days. Then he can use the extra 2 days to do something else but we don't know. 5 days later, he comes back with the completed task. We examine the result and feel good about it, and accept it. But still, we don't know what he does during those 2 days. Maybe he learned other things; maybe he just played video games. We just don't know. There are technical ways to influence what he can do (e.g., watching his computer monitor, eavesdropping his communication with others, cutting off the Internet access during office hours). We may or may not want to do that.

But when it comes to AI, we probably want to put it under serious surveillance: When we delegate a task to AI, we not only need to completely understand its output (by reviewing it to make sure it doesn't do anything malicious like [attempting to backdoor the Linux kernel](https://lwn.net/Articles/57135/)), we also need to make sure it doesn't do anything unnecessarily additional (e.g., finish the task in 3 days and use the remaining 2 days to build a nuclear launcher to nuke us).

Now let's think about reviewing the output of AI to make sure the work is safe. Suppose one average human programmer can write M lines of code per hour, and to make sure these M lines of code are *good* to use (from many perspectives, such as performance, security, maintenability), suppose it takes N man-hours to finish the review. Then how many lines of code can an AI write per hour? Still M? Twice as many as M? Probably an AI can write M lines of code in 0.0001 second, or even less. Then how many man-hours will be required to review the work? This probably means there will be a way higher demand of programmers in the future.

===

After thinking about this post about programming jobs, I came to the similar conclusions as this author but probably from a different route. Assuming AI can be improved significantly in the future (to or at least near to the level of AGI), I think:
- 1). Human will need to review AI's output work (e.g., a piece of code) and AI's own behaviors to make sure it doesn't do any harm.
- 2). AI will probably shift the focus of human programmers from coding to reviewing, but there will still be a huge (potentially huger) demand of human programmers.

I want to share my current thoughts because I may have missed/overlooked something due to my own limited understanding of AI. Other people's thoughts may help me see a bigger picture.

I started my thoughts with a basic question: Do we human beings want AI to be under 100% control? Do we allow AI to do things secretly that's out of our control, thus potentially harm human beings? Probably not.

For example, suppose we ask AI to fix a bug or add a feature to the existing code. Now the AI comes back to us with the finished code. Remember my pre-condition that AI has been improved significantly so it's very smart and can do things autonomously. We run the code and see the result is good. **Then do we want to accept the code blindly without any further review?** How do we guarantee the AI doesn't secretly do anything harmful (see a real story "An attempt to backdoor the kernel" https://lwn.net/Articles/57135/)? We need to review its output. Furthermore, suppose the AI spent one hour in generating the code, how do we know it wasn't the case that the AI actually finished the work in just 20 minutes and spent the next 40 minutes to secretly build a nuclear launcher? We need to review its behaviors to make sure AI only does what we have asked and nothing more. All this review work is done by people that have enough technical knowledge.

===

I've heard the rumors that say guys like Elon Musk, the CEO of OpenAI, have found a way to implement AGI, but I can't find more info. I can't say it's false, but I don't think we should easily believe it's true. It reminds me of this story: Centuries ago, the French mathematician Pierre de Fermat, in the margin of a book, claimed that he found a wonderful proof of his Last Theorem but the proof was too large to fit in the margin so he didn't write it down. His Last Theorem, which was called Fermat's conjecture for a long time, was not really proved until about 350 years later in 1994 (published in 1995). This 3.5-century effort made people doubt whether Fermat actually found a correct proof in the first place.

The takeaway: Don't simply rely on people's verbal claim. Even if they do have the idea of how to implement AGI, we still need to evaluate if their implementation is really an AGI or not.
