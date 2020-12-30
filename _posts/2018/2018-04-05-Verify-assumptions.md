---
comments: true
date: 2018-04-05
layout: post
tags: [Tech]
title: Verifying the Assumptions Before Implementing the Solution
---

> After you devise a plan to solve a problem, it's always better to identify the assumptions you hold in the solution and verify if they are true. If some of them are not, the verification can save you a lot of time.

## Replay

- I observed a database authentication failure during development.
- I saw the authentication information was kept in two places (actually three, but I failed to notice one of them initially): the database service configuration and its consumer's low-level configuration. They were different.
- Somehow I immediately thought the consumer used the low-level configuration to authenticate.
- Then I implemented the solution which simply replicated the authentication information to the consumer's low-level configuration.
- I tested it. It seemed to work.
- Because I was being paranoid, I decided to remove my fix and saw if I could reproduce the problem.
- But I couldn't.
- I was confused because the solution I thought should work didn't work.
- Fortunately, I decided to figure out why it didn't work.
- After long time of debugging, I finally noticed the authentication information stored in the third place: a higher-level configuration of the consumer service that could override its low-level configuration. When I was testing the code, the higher-level configuration was always present so the low-level configuration was not used at all because it was overridden.
- The authentication information in the higher-level configuration was the same as wbat was in the database service configuration. Therefore, the service was using the correct authentication information to log in the database.
- It turned out to be a completely different root cause: the database authentication information was updated a day ago, but I was still using an old database instance that used the old authentication information. Because I didn't ask the database service to update the authentication information recorded in the old database, I was trying to use the new authentication information to log in a database with the old authentication information. Of course it didn't work.
- The final solution was: I simply updated the authentication information stored in the database instance, and everything started to work again.

## Reflection

I did something right and wrong:

- **I decided to reproduce the problem.** Although I didn't do it in the first place, my paranoia made me do it before I published my fix. Because I did it, I realized I couldn't reproduce the problem, which led me to thinking more what happened. Next time, I should always reproduce the problem first.
- **I decided not to assume it would work.** This eventually saved me from getting embarrased. I decided to fully understand why I couldn't reproduce the problem. This led me to the final discovery of the real cause.
- **I should have verified the assumptions first.** My initial solution relied on the assumption that the database consumer service used the low-level configuration. If I could have verified this assumption earlier, I may have discovered the correct solution earlier and thus saved more time of my day.
