---
comments: true
date: 2023-03-24
layout: post
tags: [Math]
title: "What do we learn when we learn math?"
---

In Chinese schools, students are taught with a lot of math: geometry, algebra, entry-level calculus, etc. I felt I focused so much on grasping the concrete knowledge itself: memorizing the formulas, rules, and theorems, and solving a lot of questions as practices, hoping to do well enough in the next exam.

However, as a grown-up, when I reflected on my learning experience, I realized I focused on the wrong thing: For most of us, the math that's taught in school before college is far beyond what is needed in the later phase of life. In other words, I spent so much time learning something that I would rarely use in the future, and this definitely didn't look cost effective to me now. Also, in school, I was learning math not for myself but for the examinations. Well, learning for examination is important because the exam result can kind of determine the future path of life, but **if I could have shifted my focus on training my mind's abilities and sharpening my learning skills**, I would have made far better use of the time, even though I may still not perform well in the tests (because I was NOT THE smart kid at the end of the day).

OK. What should I have focused?

## Mind Abilities in Abstraction, Precision, and Accuracy

First of the first, math is a good material for training our mind's abilities. Math is different from our everyday world. While our everyday world is often concrete and vague, math world is quite abstract and precise. Therefore, learning math forces us to think in the way that we don't usually think in the everyday life. Learning math extends, or "stretches", our mind to enable it to work in a wider spectrum which then potentially enables us to adapt well in more work environments.

Let me use the linear algebra I'm learning these days as the example. These days I'm learning the notation \\( \mathbf{F}^S \\) which denotes the set of functions from a set \\( S \\) to \\( \mathbf{F} \\) (which represents either the real number set \\( \mathbf{R} \\) or the complex number set \\( \mathbf{C} \\)). Think about this definition: It doesn't define any concrete set \\( S \\) or any concrete function \\( f: S \rightarrow \mathbf{F} \\). Instead, the definition just says "it's a set" and "it's a function from \\( S \\) to \\( \mathbf{F} \\)". These are the only two required conditions. Therefore, \\( S \\) doesn't have to be a set of numbers. It can be a set of symbols such as \\( \\{ \clubsuit, \diamondsuit, \heartsuit, \spadesuit \\} \\), and the functions can be arbitrary as long as the results are in \\( \mathbf{F} \\). For example:

$$ f(\clubsuit) = 10 $$

$$ f(\diamondsuit) = -3 + 9i $$

$$ f(\heartsuit) = 1 $$

$$ f(\spadesuit) = 1 $$

The point (and the charm) is: **When studying this definition and notation, one must try the best to process the material in an abstract way without having to thinking about any concrete examples** of \\( S \\) and \\( \mathbf{F} \\). Of course, it is completely acceptable (to me) to use concrete examples to aid the learning, but eventually, one needs to train the mind to work on an abstract level.

The other part of the mind training is the precision and accuracy in thinking. In other words, whether we can think and reason in solid logic. In the everyday life, we tend to think and reason vaguely because losing some precision and accuracy doesn't cause any big (or even small) loss. When it comes to dealing with scientific and engineering work, however, we must be able to make progress with steps that are built upon firm logic. Failing to do so results in misleading or even completely wrong conclusions. The reasoning in math requires exactly such level of precision and accuracy. When solving a question, one may need to apply a bunch of definitions and theorems in order to make progress. During the entire time, he/she must constantly examine whether the prerequisites of a theorem are all met in order to apply it. One common mistake is: one thinks the prerequisites of a theorem are seemingly all met and just applies it without carefully examining if they are truly met.

Let me still use the \\( \mathbf{F}^S \\) as the example. As an exercise, I tried to prove that \\( \mathbf{F}^S \\) is a _vector space_. To prove that, I needed to prove the functions on \\( \mathbf{F}^S \\) have the property of associativiy with scalar muliplication, i.e.:

$$ (ab)f = a(bf) $$

where \\( a, b \in \mathbf{F} \\) and \\( f \in \mathbf{F}^S \\). My reasoning process was as follows:

$$
\begin{aligned}
  ((ab)f)(x) &= (ab)f(x) \cdots\cdots (1) \\
             &= a(bf(x)) \cdots\cdots (2) \\
             &= a((bf)(x)) \cdots\cdots (3) \\
             &= (a(bf))(x) \cdots\cdots (4)
\end{aligned}
$$

One question I ketp asking myself while working on the proof was: Why can I move from step `n` to step `n+1`? And I didn't move further until I could confidently point out the needed theorems and properties. For example:

- From step `(1)` to step `(2)`, I could unquote `(ab)` and requote `b` and `f(x)` because, according to the definition of \\( \mathbf{F}^S \\), `f(x)` was a value on \\( \mathbf{F} \\). With `a` and `b` were also elements in \\( \mathbf{F} \\), `a`, `b`, and `f(x)` all belonged to \\( \mathbf{F} \\) so their muliplication satisfies associativity:

$$ (ab)c = a(bc) $$

- From step `(2)` to step `(3)`, I could quote `bf` together because the definition of scalar muliplication on \\( \mathbf{F} \\) allowed me to do so.
- From step `(3)` to step `(4)`, I treated `bf` as a whole entity and applied the definition of scalar muliplication on \\( \mathbf{F} \\) again, so I could quote `a` and `(bf)` together.

Therefore, math can teach us to move slowly but solidly. This teaching is applicable not only in scientific and engineering work, but also in **defeating political propaganda and sophistry**. Oftentimes, such political statements look reasonable and correct, but if one examines the reasoning carefully, one can always find logical fellacies hiding here and there in order to mislead people. I can't say a well-trained mathematician would never be deceived, but I believe they will less likely be deceived.

## Learning Skills and Habbits

Math is also a good material for sharpening our learning abilities. (For this part, I would say all the subjects can help train our learning skills and math is just one of them.) As I argued at the beginning of the article, much of the math we learn in school would become less useful in our future life. Therefore, we need to think about what we can get out of learning math that can stick with us for the rest of the life.

That's the learning skills and habbits.

The learning skills are useful in all phases of the life in whatever we need to learn. The learning skills are thus a way better asset that we should invest in than the concrete math knowledge itself.

Math is a good material for learning how to learn because math is hard by nature, so in order to grasp it, we need to build different skills. For example, how to memorize the formulas as quickly as possible? How to choose the angle to look into the question in order to tackle it? How to finish the assignments quickly but also correctly (so to save time for other things)? If you can't do math well, chances are there are some learning skills you need to improve. The improvement of the learning skills can benefit you for the rest of the life.
