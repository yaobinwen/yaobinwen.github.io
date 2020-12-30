---
comments: true
date: 2018-08-06
layout: post
tags: [Tech]
title: How to Setup Jenkins to Access Local Git Repository
---

> The local git repository must be initialized with "--shared=group" and the user "jenkins" must be in the same user group that has the access to the git repository.

Last week when I was working on the automation of our build process, I was doing the task this way:

- Used a local git repository to manage the `Jenkinsfile`. The local git repository was created on our internal NAS which was mounted to a local path on my computer.
- Set up the Jenkins in a local virtual machine that had the NAS mounted, too, so from within the virtual machine I could access the git repository like a local one.
- Created a Jenkins pipeline to use the `Jenkinsfile` as the build script.

However, when trying to set up the pipeline to use the git repository, I kept getting the following error:

> Failed to connect to repository : Command "git ls-remote -h file:///path/to/local/git/repo HEAD" returned status code 128:
stdout:
>
>stderr: fatal: '/path/to/local/git/repo' does not appear to be a git repository
>
>fatal: Could not read from remote repository.
>
>Please make sure you have the correct access rights and the repository exists.

When I tried to run the command `git ls-remote -h file:///path/to/local/git/repo HEAD`, I didn't get any error.

After searching for a while, I found [the following Stack Overflow answer](https://stackoverflow.com/a/16368839/630364) that told me why that happened:

> If you're using Linux, this error can also be caused from not enabling share on your Git repo. Linux jenkins user won't be able to access Git report under another user unless.... git --bare init --shared=group Also, your jenkins user and Git repo user must belong to the same group for file permission access. There's other alternatives to that like messing with umasks and ACL's but setting up a linux group for your two users is the easiest way.

I then remembered that Jenkins uses the `jenkins` user to do all the work. So I tried to run that `ls-remote` as the user `jenkins`: `sudo -u jenkins git ls-remote -h file:///path/to/local/git/repo HEAD`.

This time I got the exit code `128` and the error message about not having access permission.

So I did the two things that answer suggested:

- Recreated the git repository with [`--shared=group`](https://git-scm.com/docs/git-init#git-init---sharedfalsetrueumaskgroupallworldeverybody0xxx).
- Added `jenkins` user to the user group that had the desired access permission.

I also needed to restart the Jenkins server to make the changes effective, as I suggested [here](https://stackoverflow.com/questions/15257652/jenkins-configuration-of-git-plugin#comment90387884_16368839).
