---
comments: true
date: 2024-12-19
layout: post
tags: [Tech,git]
title: "git-rebase: A case study"
---

`rebase` is probably one of the most difficult operation in `git` because it requires a lot of carefulness and patience to do it right. Recently, I dealt with a complicated `git rebase` case so I wanted to write down my learning.

In this `git rebase` case, I needed to rebase a feature branch on top of the latest main branch `origin/main`. However, the latest main branch evolved in the following way:

* 1). At the beginning, there were two topic branches: `topic1` and `topic2`:
  * `topic1` was based on `main`.
  * `topic2` was based on `topic1`.

<center>
<img src="https://raw.githubusercontent.com/yaobinwen/yaobinwen.github.io/6b06cb7f6fd50849e0613be40ee0a79f06b707f7/images/2024/12-19/git-rebase-01.png" alt="git-rebase-state-01" height="50%" width="50%" />
</center>

* 2). Later:
  * More commits from other topic branches were merged into `main`.
  * Meanwhile, a few commits were pushed into `topic1` to fix bugs.

<center>
<img src="https://raw.githubusercontent.com/yaobinwen/yaobinwen.github.io/6b06cb7f6fd50849e0613be40ee0a79f06b707f7/images/2024/12-19/git-rebase-02.png" alt="git-rebase-state-02" height="50%" width="50%" />
</center>

* 3). Then, at some point:
  * `topic1` was rebased against the then-latest `main` branch in order to resolve the merge conflicts.
  * However, `topic2` had never been rebased, so it still referred to some old commits that used to be on `topic1`. See the commits in light green in the yellow box.

<center>
<img src="https://raw.githubusercontent.com/yaobinwen/yaobinwen.github.io/6b06cb7f6fd50849e0613be40ee0a79f06b707f7/images/2024/12-19/git-rebase-03.png" alt="git-rebase-state-03" height="50%" width="50%" />
</center>

* 4). Eventually, the branch `topic1` was merged into `main`.

<center>
<img src="https://raw.githubusercontent.com/yaobinwen/yaobinwen.github.io/6b06cb7f6fd50849e0613be40ee0a79f06b707f7/images/2024/12-19/git-rebase-04.png" alt="git-rebase-state-04" height="50%" width="50%" />
</center>

What I needed to do was rebase the branch `topic2` against the latest branch `main`. The biggest challenge was handling the commits inside the yellow box: Those commits from the two branches were either identical or quite similar. Identical commits were easy to handle. In fact, `git rebase` will automatically skip them. The similar commits needed more attention, because we need to decide whether we need to keep them or skip them.

The commits outside the yellow box were much easier to handle: For the commits 3, 4, and 5, they were `topic1`-specific commits so they must be kept; for the commits 6 and 7, they were `topic2`-specific commits, so they must be kept too.

Now let's think about what can cause the commits inside the yellow box to be similar but not identical.

The first case is that the branch `main` already has some changes that also appear in the topic branches. In the following illustration, the branch `topic1` had the changes `A=1` and `B=2`. However, the change `A=1` was already merged into `main`. This may happen for two reasons:
* `A=1` might be a more fundamental change that was required by multiple branches. Therefore, it may appear in not only `topic1` and `topic2`, but also in a 3rd branch called `topic3`. If `topic3` was merged earlier than `topic1` and `topic2`, the change `A=1` would be merged into `main` before `topic1` and `topic2` were merged.
* `A=1` was only made in `topic1`, but it might be a bug fix that was urgent enough to be cherry-picked into `main` before `topic1` was merged.

<center>
<img src="https://raw.githubusercontent.com/yaobinwen/yaobinwen.github.io/6b06cb7f6fd50849e0613be40ee0a79f06b707f7/images/2024/12-19/git-rebase-05.png" alt="git-rebase-state-05" height="50%" width="50%" />
</center>

As a result, when `topic1` was rebased against `main`, the change `A=1` was no longer needed because it was already done in `main`. The branch `topic1` only needed to keep the change `B=2`, as illustrated below:

<center>
<img src="https://raw.githubusercontent.com/yaobinwen/yaobinwen.github.io/6b06cb7f6fd50849e0613be40ee0a79f06b707f7/images/2024/12-19/git-rebase-06.png" alt="git-rebase-state-06" height="50%" width="50%" />
</center>

The second case is that the branch `main` introduced some condition that required the code in the branch `topic1` be changed. For example, `topic1` wanted to assign the value zero to `A`. However, a change in `main` used `A` as the divider in the expression `C=B/A`. See the following illustration:

<center>
<img src="https://raw.githubusercontent.com/yaobinwen/yaobinwen.github.io/6b06cb7f6fd50849e0613be40ee0a79f06b707f7/images/2024/12-19/git-rebase-07.png" alt="git-rebase-state-07" height="50%" width="50%" />
</center>

As a result, `A` could no longer be zero. When `topic1` was rebased against `main`, it must update `A` to be a non-zero value, such as `1`. But the commit that was referred in the old `topic1` commit still had the change `A=0`. See the following illustration:

<center>
<img src="https://raw.githubusercontent.com/yaobinwen/yaobinwen.github.io/6b06cb7f6fd50849e0613be40ee0a79f06b707f7/images/2024/12-19/git-rebase-08.png" alt="git-rebase-state-08" height="50%" width="50%" />
</center>

In both cases, we need to keep the commits during rebase, so the conflicting changes can be kept for further resolution.
