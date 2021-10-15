---
comments: true
date: 2021-10-14
layout: post
tags: [Tech]
title: A Process for Complicated Git Merges
---

## 1. Overview

Today I learned from my director a process to do `git` merge when the merge itself has become complicated (e.g., involving many changes on the two branches).

It's hard to define "complicated" so it depends on the engineering judgment to see if a merge is complicated enough to abandon the automatic `git merge` but use this process. Generally speaking, **my rule of thumb is: If you need to spend a lot of time analyzing the "current" and "incoming" changes in order to figure out the correct merge and there can be a lot of such "in-depth" analysis during the merge, it's likely that you need this process.**

**At its core, this process is a "rebase" of one branch (usually the feature branch) onto the other (usually the `main` branch)**, so it uses `git rebase` rather than `git merge`. But using `git merge` certainly works, too.

The process is described in the following sections.

## 2. The Scenario

The target scenario of this process is: When you are developing a feature on a feature branch and you want to merge the current changes that other developers have pushed onto `main`. You tried a quick `git merge` but you find the conflicts are not trivial at all and are too complicated to be resolved by a quick glance.

## 3. The Process

### 3.1 Communicate with Other Developers

Because this process is essentially a "rebase" which will inevitably result in a force-push, you need to make sure nobody else will be impacted by the force-push. Ask if anyone else is also using current feature branch. If somebody is using the branch, you and that developer need to figure out what to do with his/her local checkout of the feature branch. Possible options are:
- 1). The fellow developer just abandons his/her local changes, if any, and will re-check out the re-based branch.
- 2). The fellow developer will push his/her work to the feature branch and then you will do the merge using the feature branch that has his/her contribution.

### 3.2 Understanding the Changes

Since this is a "complicated merge" from `main` onto the feature branch and there are likely complicated conflicts, you need to understand the changes on both sides in order to perform a correct merge.

To understand the changes on `main`:
- 1). Run `git log --stat <feature branch>..origin/main` to list the commits that `main` has but the feature branch doesn't.
- 2). Pick the commits that have also modified the files that are touched by the feature branch.
- 3). For each such commit, run `git show` on it to learn how the commit changes the files that the feature branch also modifies.

If you are the developer of the feature branch, you should be already familiar with the changes on the feature branch. If you are not the developer of the feature branch, you may want to follow the same process above to understand the changes.

Once you have a solid grasp of the changes on both sides, you can proceed to the next phase.

### 3.3 Rebase the Feature Branch onto `main`

Follow the steps below to do the rebasing and merging:
- 1). Run `git branch <feature-new-branch> <feature-branch>` to create a new feature branch that's based on the current feature branch. You will use `<feature-new-branch>` to do the rebasing work so we need to `git switch <feature-new-branch>` to put yourself on it.
- 2). Run `git merge-base <feature-new-branch> origin/main` to find the merge base.
- 3). If appropriate, run `git rebase -S -i <merge-base>` to reorganize and squash the commit history so make the commits more logically grouped. Squashing the multiple related commits into one commit can potentially result in fewer merge conflicts.
- 4). Run `git rebase -S -i origin/main` to rebase `<feature-new-branch>` against the current `main`. There can be still conflicts and you need to resolve them using the knowledge that you have learned from reading the changes on both the feature branch and `main`. Possibly you also need to get the related developers to help. This rebase process is essentially cherry-picking the commits from `main` onto the feature's new branch.
- 5). Once the rebase is done, run `git push -f` to replace the old feature branch with the new feature branch.
- 6). Notify other developers, if any, to re-check out the updated feature branch.
