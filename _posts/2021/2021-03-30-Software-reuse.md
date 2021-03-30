---
comments: true
date: 2021-03-30
layout: post
tags: [Tech]
title: Software Reuse
---

I think if we want to get closer to better software reuse, we should not create branches of the code itself.

Branches of the same code means duplicated code. Duplicated code is not reused because if it were reused, it wouldn't be duplicated.

So I'm perceiving a possible way of maintaining the code and building the final product:

- There is a single, monolithic code base that doesn't have the concept of "branches".
- This monolithic code base is divided into reusable modules.
- Another configuration repository is used to cherry-pick the needed modules from the monolithic code base in order to assemble a product.
- This configuration repository has "branches" and each branch is for one product.

The pros of this approach:

- The found bugs need to be fixed in just one place and all the products can get the updates.
- Minimize the duplicated code to minimize the maintenance burden.

The cons of this approach:

- Because a bug can affect potentially all the products, automated tests must provide a good enough coverage, so the tests can take up a majority of the development work.
- A bad bug fix can affect potentially all the products. We may need to develop another way of updating and releasing software to minimize the impact.
